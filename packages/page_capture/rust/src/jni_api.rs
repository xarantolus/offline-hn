use crate::engine::{self, Verdict};
use adblock::Engine;
use jni::JNIEnv;
use jni::objects::{JByteArray, JClass, JObjectArray, JString};
use jni::sys::{jint, jlong, jobjectArray, jstring};
use std::collections::HashSet;
use std::panic::{AssertUnwindSafe, catch_unwind};

fn strings(env: &mut JNIEnv, array: &JObjectArray) -> Vec<String> {
    let len = env.get_array_length(array).unwrap_or(0);
    (0..len)
        .filter_map(|i| {
            let item = env.get_object_array_element(array, i).ok()?;
            env.get_string(&JString::from(item)).ok().map(String::from)
        })
        .collect()
}

fn string_array(env: &mut JNIEnv, items: &[String]) -> jobjectArray {
    let class = env.find_class("java/lang/String").unwrap();
    let empty = env.new_string("").unwrap();
    let array = env.new_object_array(items.len() as i32, class, empty).unwrap();
    for (i, item) in items.iter().enumerate() {
        let value = env.new_string(item).unwrap();
        env.set_object_array_element(&array, i as i32, value).unwrap();
    }
    array.into_raw()
}

fn engine<'a>(handle: jlong) -> &'a Engine {
    unsafe { &*(handle as *const Engine) }
}

fn into_handle(engine: Engine) -> jlong {
    Box::into_raw(Box::new(engine)) as jlong
}

#[unsafe(no_mangle)]
pub extern "system" fn Java_io_github_xarantolus_page_1capture_AdblockNative_build(
    mut env: JNIEnv,
    _class: JClass,
    lists: JObjectArray,
) -> jlong {
    let texts = strings(&mut env, &lists);
    catch_unwind(AssertUnwindSafe(|| into_handle(engine::build(&texts)))).unwrap_or(0)
}

#[unsafe(no_mangle)]
pub extern "system" fn Java_io_github_xarantolus_page_1capture_AdblockNative_load(
    env: JNIEnv,
    _class: JClass,
    bytes: JByteArray,
) -> jlong {
    let Ok(data) = env.convert_byte_array(&bytes) else {
        return 0;
    };
    catch_unwind(AssertUnwindSafe(|| {
        engine::load(&data).map(into_handle).unwrap_or(0)
    }))
    .unwrap_or(0)
}

/// Must run before the engine is shared: it needs exclusive access.
#[unsafe(no_mangle)]
pub extern "system" fn Java_io_github_xarantolus_page_1capture_AdblockNative_useResources(
    mut env: JNIEnv,
    _class: JClass,
    handle: jlong,
    text: JString,
) -> jint {
    let Ok(text) = env.get_string(&text).map(String::from) else {
        return 0;
    };
    let engine = unsafe { &mut *(handle as *mut Engine) };
    catch_unwind(AssertUnwindSafe(|| engine::use_resources(engine, &text) as jint)).unwrap_or(0)
}

#[unsafe(no_mangle)]
pub extern "system" fn Java_io_github_xarantolus_page_1capture_AdblockNative_serialize<'l>(
    env: JNIEnv<'l>,
    _class: JClass,
    handle: jlong,
) -> JByteArray<'l> {
    let bytes = engine(handle).serialize();
    env.byte_array_from_slice(&bytes).unwrap()
}

#[unsafe(no_mangle)]
pub extern "system" fn Java_io_github_xarantolus_page_1capture_AdblockNative_check(
    mut env: JNIEnv,
    _class: JClass,
    handle: jlong,
    url: JString,
    source: JString,
    kind: JString,
) -> jstring {
    let (Ok(url), Ok(source), Ok(kind)) = (
        env.get_string(&url).map(String::from),
        env.get_string(&source).map(String::from),
        env.get_string(&kind).map(String::from),
    ) else {
        return std::ptr::null_mut();
    };
    let verdict = catch_unwind(AssertUnwindSafe(|| {
        engine::check(engine(handle), &url, &source, &kind)
    }))
    .unwrap_or(Verdict::Allow);
    match verdict {
        Verdict::Allow => std::ptr::null_mut(),
        Verdict::Block => env.new_string("").map(|s| s.into_raw()).unwrap_or(std::ptr::null_mut()),
        Verdict::Redirect(body) => env
            .new_string(format!("r{body}"))
            .map(|s| s.into_raw())
            .unwrap_or(std::ptr::null_mut()),
    }
}

#[unsafe(no_mangle)]
pub extern "system" fn Java_io_github_xarantolus_page_1capture_AdblockNative_cosmetic(
    mut env: JNIEnv,
    _class: JClass,
    handle: jlong,
    url: JString,
) -> jstring {
    let Ok(url) = env.get_string(&url).map(String::from) else {
        return std::ptr::null_mut();
    };
    let json = catch_unwind(AssertUnwindSafe(|| engine::cosmetic(engine(handle), &url)))
        .unwrap_or_default();
    env.new_string(json).map(|s| s.into_raw()).unwrap_or(std::ptr::null_mut())
}

#[unsafe(no_mangle)]
pub extern "system" fn Java_io_github_xarantolus_page_1capture_AdblockNative_genericSelectors(
    mut env: JNIEnv,
    _class: JClass,
    handle: jlong,
    classes: JObjectArray,
    ids: JObjectArray,
    exceptions: JObjectArray,
) -> jobjectArray {
    let classes = strings(&mut env, &classes);
    let ids = strings(&mut env, &ids);
    let exceptions: HashSet<String> = strings(&mut env, &exceptions).into_iter().collect();
    let found = catch_unwind(AssertUnwindSafe(|| {
        engine::generic_selectors(engine(handle), &classes, &ids, &exceptions)
    }))
    .unwrap_or_default();
    string_array(&mut env, &found)
}

#[unsafe(no_mangle)]
pub extern "system" fn Java_io_github_xarantolus_page_1capture_AdblockNative_free(
    _env: JNIEnv,
    _class: JClass,
    handle: jlong,
) {
    if handle != 0 {
        drop(unsafe { Box::from_raw(handle as *mut Engine) });
    }
}
