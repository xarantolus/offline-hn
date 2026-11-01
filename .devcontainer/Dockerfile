# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG FLUTTER_VERSION=3.47.1
ARG RUST_VERSION=1.99.1
ARG CARGO_NDK_VERSION=4.1.2
ARG ANDROID_CMDLINE_TOOLS=16111833
ARG ANDROID_PLATFORMS="platforms;android-37.0 platforms;android-36"
ARG ANDROID_BUILD_TOOLS="build-tools;37.0.0 build-tools;36.0.0"
# flutter.ndkVersion of FLUTTER_VERSION.
ARG ANDROID_NDK="ndk;28.2.13676358"
# Plugins build native code with it; Gradle would download it on the first build.
ARG ANDROID_CMAKE="cmake;3.22.1"
ARG ANDROID_SYSTEM_IMAGE="system-images;android-36;google_apis;x86_64"
ARG AVD_NAME=offline-hn
ARG NODE_MAJOR=20
ARG MOBILE_MCP_VERSION=1.0.2

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
        openjdk-17-jdk-headless build-essential \
        git curl wget unzip zip xz-utils ca-certificates file jq \
        libglu1-mesa openssh-client less procps nano

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_SDK_ROOT=/opt/android-sdk

RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && curl -fsSL -o /tmp/cmdline-tools.zip \
        "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
    && unzip -q /tmp/cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools" \
    && mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" \
    && rm -f /tmp/cmdline-tools.zip

ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator

RUN yes | sdkmanager --licenses > /dev/null \
    && sdkmanager --install "platform-tools" ${ANDROID_PLATFORMS} ${ANDROID_BUILD_TOOLS} ${ANDROID_NDK} ${ANDROID_CMAKE} > /dev/null

ENV RUSTUP_HOME=/opt/rustup CARGO_HOME=/opt/cargo
ENV PATH=${PATH}:${CARGO_HOME}/bin
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --profile minimal --default-toolchain "${RUST_VERSION}" \
    && rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android \
    && cargo install cargo-ndk --version "${CARGO_NDK_VERSION}" --locked \
    && rm -rf "${CARGO_HOME}/registry"

ENV FLUTTER_ROOT=/opt/flutter
RUN curl -fsSL -o /tmp/flutter.tar.xz \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm -f /tmp/flutter.tar.xz

ENV PATH=${PATH}:${FLUTTER_ROOT}/bin:${FLUTTER_ROOT}/bin/cache/dart-sdk/bin:/root/.pub-cache/bin
RUN git config --global --add safe.directory '*' \
    && flutter config --no-analytics --android-sdk "${ANDROID_HOME}" \
    && dart --disable-analytics
RUN flutter precache --android --universal

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends nodejs gh
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && ln -sf /root/.local/bin/claude /usr/local/bin/claude
RUN npm install -g "@mobilenext/mobile-mcp@${MOBILE_MCP_VERSION}"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get install -y --no-install-recommends \
        libpulse0 libnss3 libxcomposite1 libxcursor1 libxdamage1 libxi6 \
        libxtst6 libasound2t64 libgl1 libx11-xcb1 libxfixes3 libxrandr2 \
        libdrm2 libgbm1
RUN sdkmanager --install "emulator" "${ANDROID_SYSTEM_IMAGE}" > /dev/null \
    && echo no | avdmanager create avd -n "${AVD_NAME}" -k "${ANDROID_SYSTEM_IMAGE}" -d pixel_6 --force

# Flutter's container check; podman doesn't create it.
RUN touch /.dockerenv

ENV CLAUDE_CONFIG_DIR=/root/.claude
ENV GRADLE_USER_HOME=/root/.gradle
ENV PUB_CACHE=/root/.pub-cache

WORKDIR /workspaces
CMD ["/bin/bash"]
