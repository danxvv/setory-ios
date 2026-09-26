#!/bin/bash
# Fast UI-test runner for Setory.
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
#   scripts/uitest.sh -only-testing:SetoryUITests/WorkoutLoggingUITests
#   WORKERS=3 scripts/uitest.sh                       # fewer clones
#   DERIVED_DATA=/tmp/setory-dd-mybranch scripts/uitest.sh
#
# Give concurrent sessions their own DERIVED_DATA: two runs sharing one path
# compile into the same test bundle, so one branch's in-progress tests show up
# in the other's results.
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${DEVICE:-iPhone 17 Pro}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/setory-deriveddata}"
WORKERS="${WORKERS:-6}"

ONLY_ARGS=("-only-testing:SetoryUITests")
for arg in "$@"; do
  if [[ "$arg" == -only-testing:* ]]; then
    ONLY_ARGS=()
  fi
done

xcrun simctl bootstatus "$DEVICE" -b

exec xcodebuild test \
  -project Setory.xcodeproj \
  -scheme Setory \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath "$DERIVED_DATA" \
  -parallel-testing-enabled YES \
  -parallel-testing-worker-count "$WORKERS" \
  ${ONLY_ARGS[@]+"${ONLY_ARGS[@]}"} \
  "$@"
