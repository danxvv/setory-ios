#!/bin/bash
# Fast UI-test runner for gymapp.
#
# Encodes the invocation quirks this project needs:
#  - scratch DerivedData: Xcode's previews agent clobbers the default
#    DerivedData app bundle, which makes launches crash at dyld.
#  - the base simulator must be booted BEFORE cloned test workers start,
#    otherwise clones fail preflight with "Busy".
#  - parallel workers (simulator clones) distribute the 8 UI-test classes.
#
# Usage:
#   scripts/uitest.sh                                 # whole UI suite
#   scripts/uitest.sh -only-testing:gymappUITests/WorkoutLoggingUITests
#   WORKERS=4 scripts/uitest.sh                       # more clones
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${DEVICE:-iPhone 17 Pro}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/gymapp-deriveddata}"
WORKERS="${WORKERS:-3}"

ONLY_ARGS=("-only-testing:gymappUITests")
for arg in "$@"; do
  if [[ "$arg" == -only-testing:* ]]; then
    ONLY_ARGS=()
  fi
done

xcrun simctl bootstatus "$DEVICE" -b

exec xcodebuild test \
  -project gymapp.xcodeproj \
  -scheme gymapp \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath "$DERIVED_DATA" \
  -parallel-testing-enabled YES \
  -parallel-testing-worker-count "$WORKERS" \
  ${ONLY_ARGS[@]+"${ONLY_ARGS[@]}"} \
  "$@"
