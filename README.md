# Offline HN

An offline-first Hacker News reader for Android, built with Flutter.

This is only the scaffold so far: the app shows an empty home screen.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Release builds are signed from `android/key.properties` or the `X_KEYSTORE_PATH`
environment variable; debug builds need neither.

## License

[MIT](LICENSE)
