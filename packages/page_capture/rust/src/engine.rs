use adblock::lists::{FilterSet, ParseOptions};
use adblock::request::Request;
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
