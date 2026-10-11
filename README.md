# Offline HN

An offline-first Hacker News reader for Android, built with Flutter.

This is only the scaffold so far: the app shows an empty home screen.

## Development

Page capture blocks ads with Brave's adblock-rust, a Rust library that Gradle
builds for the Android ABIs. Install the toolchain once (rustup, the Android
targets, cargo-ndk; a C compiler and an Android NDK must be present):

```sh
tool/setup-rust.sh
```

Then:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The Rust crate has its own tests: `cargo test --locked` in
`packages/page_capture/rust`.

Release builds are signed from `android/key.properties` or the `X_KEYSTORE_PATH`
environment variable; debug builds need neither.

## License

[MIT](LICENSE)
