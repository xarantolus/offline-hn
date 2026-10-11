use adblock::lists::{FilterSet, ParseOptions};
use adblock::request::Request;
use adblock::resources::{MimeType, Resource, ResourceType};
use base64::{Engine as _, prelude::BASE64_STANDARD};
use adblock::Engine;
use serde_json::json;
use std::collections::HashSet;

pub fn build(lists: &[String]) -> Engine {
    let mut set = FilterSet::new(false);
    for text in lists {
        set.add_filter_list(text.clone(), ParseOptions::default());
    }
    Engine::new_with_filter_set(set)
}

pub fn load(bytes: &[u8]) -> Option<Engine> {
    let mut engine = Engine::default();
    engine.deserialize(bytes).ok()?;
    Some(engine)
}

/// Reads the uBlock Origin resources text: blocks separated by a blank line, each a
/// `name mime-type[;base64]` line followed by its content.
pub fn parse_resources(text: &str) -> Vec<Resource> {
    let mut resources = Vec::new();
    for block in text.replace("\r\n", "\n").split("\n\n") {
        let block = block.trim_matches('\n');
        let Some((header, body)) = block.split_once('\n') else {
            continue;
        };
        let mut parts = header.split_whitespace();
        let (Some(name), Some(mime), None) = (parts.next(), parts.next(), parts.next()) else {
            continue;
        };
        let (mime, encoded) = match mime.strip_suffix(";base64") {
            Some(mime) => (mime, true),
            None => (mime, false),
        };
        let kind = if !encoded && body.contains("{{1}}") && mime == "application/javascript" {
            ResourceType::Template
        } else {
            ResourceType::Mime(MimeType::from(mime))
        };
        let content = if encoded {
            body.split_whitespace().collect()
        } else {
            BASE64_STANDARD.encode(body)
        };
        resources.push(Resource {
            name: name.to_string(),
            aliases: Vec::new(),
            kind,
            content,
            dependencies: Vec::new(),
            permission: Default::default(),
        });
    }
    resources
}

/// Replaces the engine's scriptlets and redirect resources; returns how many there were.
pub fn use_resources(engine: &mut Engine, text: &str) -> usize {
    let resources = parse_resources(text);
    let count = resources.len();
    engine.use_resources(resources);
    count
}

pub enum Verdict {
    Allow,
    Block,
    Redirect(String),
}

pub fn check(engine: &Engine, url: &str, source: &str, kind: &str) -> Verdict {
    let Ok(request) = Request::new(url, source, kind, "get") else {
        return Verdict::Allow;
    };
    let result = engine.check_network_request(&request);
    if let Some(body) = result.redirect {
        return Verdict::Redirect(body);
    }
    if result.should_block() {
        Verdict::Block
    } else {
        Verdict::Allow
    }
}

pub fn cosmetic(engine: &Engine, url: &str) -> String {
    let resources = engine.url_cosmetic_resources(url);
    json!({
        "hide": resources.hide_selectors,
        "exceptions": resources.exceptions,
        "script": resources.injected_script,
        "generichide": resources.generichide,
        "procedural": resources.procedural_actions.len(),
    })
    .to_string()
}

pub fn generic_selectors(
    engine: &Engine,
    classes: &[String],
    ids: &[String],
    exceptions: &HashSet<String>,
) -> Vec<String> {
    engine.hidden_class_id_selectors(classes, ids, exceptions)
}

#[cfg(test)]
mod tests {
    use super::*;

    const LIST: &str = "||ads.example^\n@@||ads.example/ok.js\n##.banner\nnews.test##.promo\n||trk.example^$third-party,script\n";

    fn engine() -> Engine {
        build(&[LIST.to_string()])
    }

    fn blocked(engine: &Engine, url: &str, kind: &str) -> bool {
        matches!(check(engine, url, "https://news.test/a", kind), Verdict::Block)
    }

    #[test]
    fn blocks_and_excepts() {
        let engine = engine();
        assert!(blocked(&engine, "https://ads.example/x.js", "script"));
        assert!(!blocked(&engine, "https://ads.example/ok.js", "script"));
        assert!(!blocked(&engine, "https://fine.example/x.js", "script"));
    }

    #[test]
    fn respects_type_and_party() {
        let engine = engine();
        assert!(blocked(&engine, "https://trk.example/t.js", "script"));
        assert!(!blocked(&engine, "https://trk.example/t.png", "image"));
    }

    const RESOURCES: &str = "noop.js application/javascript\n// noop\n\nflag.js application/javascript\nwindow.flag={{1}};\n\npixel.gif image/gif;base64\nR0lG\nODlh\n\nbroken\n";

    #[test]
    fn redirects_to_a_resource() {
        let mut engine = build(&["||ads.example/x.js$redirect=noop.js\n".to_string()]);
        assert_eq!(use_resources(&mut engine, RESOURCES), 3);
        match check(&engine, "https://ads.example/x.js", "https://news.test/a", "script") {
            Verdict::Redirect(url) => assert!(url.starts_with("data:application/javascript;base64,")),
            _ => panic!("expected a redirect"),
        }
    }

    #[test]
    fn injects_a_scriptlet_with_its_arguments() {
        let mut engine = build(&["news.test##+js(flag, 7)\n".to_string()]);
        assert_eq!(use_resources(&mut engine, RESOURCES), 3);
        let here: serde_json::Value =
            serde_json::from_str(&cosmetic(&engine, "https://news.test/a")).unwrap();
        assert!(here["script"].as_str().unwrap().contains("window.flag=7;"));
        let elsewhere: serde_json::Value =
            serde_json::from_str(&cosmetic(&engine, "https://other.test/")).unwrap();
        assert_eq!(elsewhere["script"], "");
    }

    #[test]
    fn keeps_encoded_resources_as_they_are() {
        let mut engine = build(&["||ads.example/p.gif$redirect=pixel.gif\n".to_string()]);
        use_resources(&mut engine, RESOURCES);
        match check(&engine, "https://ads.example/p.gif", "https://news.test/a", "image") {
            Verdict::Redirect(url) => assert_eq!(url, "data:image/gif;base64,R0lGODlh"),
            _ => panic!("expected a redirect"),
        }
    }

    #[test]
    fn survives_serialization() {
        let bytes = engine().serialize();
        let loaded = load(&bytes).unwrap();
        assert!(blocked(&loaded, "https://ads.example/x.js", "script"));
        assert!(!blocked(&loaded, "https://ads.example/ok.js", "script"));
        assert!(load(b"nonsense").is_none());
    }

    #[test]
    fn cosmetic_follows_host() {
        let engine = engine();
        let here: serde_json::Value =
            serde_json::from_str(&cosmetic(&engine, "https://news.test/a")).unwrap();
        assert_eq!(here["hide"], json!([".promo"]));
        let selectors = generic_selectors(&engine, &["banner".to_string()], &[], &HashSet::new());
        assert_eq!(selectors, vec![".banner".to_string()]);
    }
}
