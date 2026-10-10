#!/usr/bin/env bash
# Headless emulator lifecycle. Tools come from PATH or ANDROID_HOME /
# ANDROID_SDK_ROOT.
#
#   emulator.sh start [avd]   boot headless and wait for it to come up
#   emulator.sh wait-idle     block until the device stops pulling data
#   emulator.sh status
#   emulator.sh stop
#
# The AVD is the argument, else $AVD_NAME, else the first one the SDK lists.
set -uo pipefail

sdk=${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}
if [ -n "$sdk" ]; then
    export PATH="$sdk/emulator:$sdk/platform-tools:$PATH"
fi
for tool in adb emulator; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "emulator: '$tool' not found; set ANDROID_HOME or fix PATH" >&2
        exit 2
    }
done

cmd=${1:-status}
BOOT_TIMEOUT=${BOOT_TIMEOUT:-300}
IDLE_TIMEOUT=${IDLE_TIMEOUT:-120}
LOG_FILE=${EMULATOR_LOG:-${TMPDIR:-/tmp}/offline-hn-emulator.log}

default_avd() {
    emulator -list-avds 2>/dev/null | head -n 1
}

booted() {
    adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' | grep -q 1
}

case "$cmd" in
start)
    avd=${2:-${AVD_NAME:-$(default_avd)}}
    if [ -z "$avd" ]; then
        echo "emulator: no AVD found; create one with avdmanager" >&2
        exit 2
    fi
    if [ -e /dev/kvm ] && { [ ! -r /dev/kvm ] || [ ! -w /dev/kvm ]; }; then
        echo "emulator: /dev/kvm is not accessible to this user" >&2
        exit 2
    fi
    if booted; then
        echo "emulator: already running"
        exit 0
    fi

    # -read-only lets a second session boot the same AVD.
    nohup emulator -avd "$avd" -read-only \
        -no-window -no-audio -no-boot-anim -no-snapshot \
        -gpu swiftshader_indirect -netdelay none -netspeed full \
        >"$LOG_FILE" 2>&1 &

    adb wait-for-device
    waited=0
    until booted; do
        sleep 3
        waited=$((waited + 3))
        if [ "$waited" -ge "$BOOT_TIMEOUT" ]; then
            echo "emulator: did not boot within ${BOOT_TIMEOUT}s (see $LOG_FILE)" >&2
            exit 1
        fi
    done
    adb devices | grep emulator
    echo "emulator: $avd booted in ${waited}s"
    ;;
wait-idle)
    # Poll the received-byte counter rather than sleeping a fixed time: once it
    # stops growing the fetches are done.
    stable=0
    waited=0
    last=-1
    while [ "$waited" -lt "$IDLE_TIMEOUT" ]; do
        now=$(adb shell cat /proc/net/dev 2>/dev/null | awk '/eth0|radio0|wlan0/ {sum += $2} END {print sum+0}')
        if [ "$now" = "$last" ]; then
            stable=$((stable + 1))
            [ "$stable" -ge 3 ] && break
        else
            stable=0
        fi
        last=$now
        sleep 2
        waited=$((waited + 2))
    done
    echo "emulator: network idle after ${waited}s"
    ;;
stop)
    adb emu kill 2>/dev/null && echo "emulator: stopped" || echo "emulator: not running"
    ;;
status)
    adb devices | grep emulator || echo "emulator: not running"
    ;;
*)
    sed -n '2,11p' "$0"
    exit 2
    ;;
esac
