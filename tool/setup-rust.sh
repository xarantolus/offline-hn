#!/usr/bin/env bash
# Installs what the page_capture plugin needs to build its Rust library:
# rustup (when missing), the three Android targets and cargo-ndk. The Android
# NDK itself comes from the Android SDK, and Gradle finds cargo in
# $CARGO_HOME/bin or ~/.cargo/bin, so no PATH setup is needed afterwards.
# A host C compiler and linker (build-essential, Xcode command line tools) are
# required by cargo itself.
set -euo pipefail

cargo_home="${CARGO_HOME:-$HOME/.cargo}"
export PATH="$cargo_home/bin:$PATH"

if ! command -v rustup >/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
fi

rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android

if ! command -v cargo-ndk >/dev/null; then
  cargo install cargo-ndk --locked
fi

echo "Rust toolchain ready: $(rustc --version), $(cargo ndk --version)"
