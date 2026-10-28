# Offline HN
Offline HN is an unofficial Android reader for [Hacker News](https://news.ycombinator.com) that downloads the front pages while you are on Wi-Fi, so you can read the stories, the comments and the linked articles later without a connection.

### Features
- Top, Best, Ask and Show feeds, kept for the days you choose, with a search over everything stored
- Full comment threads with collapsible comments, in HN's order, oldest or newest first
- A saved copy of every linked article, with ads, trackers, cookie banners and popups removed by common filter lists, plus the pages linked from the first comments
- Updates in the background each morning and every few hours, by default only on Wi-Fi and while charging; a run that gets interrupted picks up where it stopped
- Swipe between feeds and between the stories of a feed, and hide the ones you have read
- An overview of what each update fetched and how much space it uses

### Screenshots (dark/light mode)
|                  Feed                   |                    Comments                     |                    Overview                     |
| :-------------------------------------: | :---------------------------------------------: | :---------------------------------------------: |
| ![Feed](.github/screenshots/d-feed.png) | ![Comments](.github/screenshots/d-thread.png) | ![Overview](.github/screenshots/d-overview.png) |

|                  Feed                   |                    Comments                     |                    Overview                     |
| :-------------------------------------: | :---------------------------------------------: | :---------------------------------------------: |
| ![Feed](.github/screenshots/l-feed.png) | ![Comments](.github/screenshots/l-thread.png) | ![Overview](.github/screenshots/l-overview.png) |

### Warning about LLM-generated code

This app is significantly vibe-coded / created using LLMs. Most of its code has not been thoroughly reviewed by a human.

### Installation & updates
[Download the APK file](https://github.com/xarantolus/offline-hn/releases/latest/download/app-release.apk) and install it. The app does not update itself; watch this repository to get notified of new releases.

### Where the data comes from
- **Stories and comments** come from the official [Hacker News API](https://github.com/HackerNews/API) (the rankings, and items Algolia does not have yet) and from [HN Search by Algolia](https://hn.algolia.com/api) (story details in batches of 100, and each thread in one request). The app does not scrape news.ycombinator.com; it opens it in your browser when you ask for the live thread.
- **Linked articles** are loaded once in an off-screen WebView, cleaned up and saved as a single MHTML file, the way a browser saves a page.
- **Filter lists** are downloaded from their maintainers and refreshed weekly; you can change them in the settings. The defaults and their licences are listed under Settings → Open source licences.

### Development
Offline HN is a Flutter app. Saving pages blocks ads with Brave's [adblock-rust](https://github.com/brave/adblock-rust), a Rust library that Gradle builds for the Android ABIs. Install the toolchain once (rustup, the Android targets and cargo-ndk; a C compiler and an Android NDK must be present):

```sh
tool/setup-rust.sh
```

Then:

```sh
git clone https://github.com/xarantolus/offline-hn.git
cd offline-hn
flutter pub get
flutter build apk --debug    # or: flutter run
```

Please commit generated code, and regenerate it after changing models or the database: `dart run build_runner build`. The Rust crate has its own tests: `cargo test --locked` in `packages/page_capture/rust`.

Code taken from elsewhere is vendored by scripts in `tool/`: DuckDuckGo's autoconsent (`update-autoconsent`), Brave's procedural filter module (`update-procedural-filters`) and the licence notice for the Rust crates (`update-rust-notice`).

Release builds are signed from `android/key.properties` or the `X_KEYSTORE_PATH` environment variable; debug builds need neither.

### Limitations
- Read-only: no logging in, voting or commenting.
- Pages that need a login or a check that you are human cannot be saved usefully, and video links (YouTube, Vimeo) are skipped.
- A saved page is a snapshot: anything it would load later by script is missing.
- Android only.

### License
Offline HN is licensed under the [MIT License](LICENSE). Saving pages uses [adblock-rust](https://github.com/brave/adblock-rust) and code from [brave-core](https://github.com/brave/brave-core), both MPL-2.0, and [@duckduckgo/autoconsent](https://github.com/duckduckgo/autoconsent), MPL-2.0; the app lists all of them, with their licences, under Settings → Open source licences.

Hacker News is run by Y Combinator. Offline HN is not affiliated with or endorsed by Y Combinator.
