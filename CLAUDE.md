# gymapp

SwiftUI + SwiftData iOS app (Xcode 26.6, iOS 26.5 SDK, iPhone 17 Pro simulator). The pbxproj uses `PBXFileSystemSynchronizedRootGroup`: files added on disk under `gymapp/`, `gymappTests/`, or `gymappUITests/` join their target automatically — no pbxproj edits needed.

## Build & test

Always pass a scratch `-derivedDataPath` — Xcode's previews agent clobbers the default DerivedData app bundle and launches then crash at dyld.

```bash
# Unit tests
xcodebuild test -project gymapp.xcodeproj -scheme gymapp \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -derivedDataPath /tmp/gymapp-deriveddata \
  -only-testing:gymappTests

# UI tests — use the fast runner (pre-boots the base simulator, runs 3
# parallel simulator clones; full suite ≈4.5 min wall)
scripts/uitest.sh
scripts/uitest.sh -only-testing:gymappUITests/ProgressUITests
WORKERS=4 scripts/uitest.sh
```

For fast iteration: `xcodebuild build-for-testing` once against the same DerivedData path, then `test-without-building` per run.

Notes:
- Cloned-simulator workers fail preflight ("Busy") unless the base simulator is booted first; the script handles this via `simctl bootstatus -b`.
- SourceKit live diagnostics are often stale for freshly created files ("No such module", "Cannot find type"); trust `xcodebuild`.
- Unit tests run in the host app and inherit the simulator's device language (Spanish on this machine); pin with `-testLanguage en|es` or write locale-agnostic assertions.

## UI-test launch arguments

The app checks these in `gymappApp.swift`; any argument prefixed `-uitest` also disables UIKit animations so XCUITest quiescence waits don't pay animation durations.

- `-uitest-reset` — wipes WorkoutSession/WorkoutSeries/RoutineTemplate(Item), deletes custom exercises, and restores edited catalog exercises to pristine via `CatalogSeeder.restorePristineCatalog` (catalog JSON is parsed only when an edit actually leaked from a prior test — do NOT reintroduce a full Exercise wipe + reseed; the 1324-row reseed per launch is what made the suite slow).
- `-uitest-seed` — inserts two known sessions (combine with reset): today = Barbell Bench Press (gv0025) 10×40 + Run (gv0685) 15 min; three days earlier = Barbell Full Squat (gv0043) 8×70. See `UITestSeeding` in gymappApp.swift.
- `-uitest-offline-media` — disables the media store's network path so detail screens deterministically show thumbnail + retry state.
- `-uitest-ai <scenario>` — success | error | no-key; swaps AI deps for an in-memory key store + stub service.
- `-uitest-disable-animations` — no behavior of its own beyond the `-uitest` prefix; used by relaunch-without-reset persistence tests so their second launch still skips animations.
- Locale pinning works for both XCUITest and `simctl launch`: `-AppleLanguages "(en)" -AppleLocale en_US` (tests pin English so literal-string assertions hold on any simulator).

## Conventions & gotchas

- Exercise ids are `gv`-prefixed dataset ids; catalog names are English-only. Bump `CatalogSeeder.bundledCatalogVersion` together with `version` in `gymapp/Resources/exercise-catalog.json`.
- The target enables `MemberImportVisibility`: using a SwiftData extension member (e.g. `.modelContainer(for:)`) requires an explicit `import SwiftData` in that file.
- Swift Testing: don't nest `#require` inside another macro call ("recursive expansion of macro 'require'") — bind the inner value with its own `try #require(...)` first.
- SwiftUI AX quirks for XCUITest: identifiers on List rows aren't `app.cells[id]` (query `app.descendants(matching: .any).matching(identifier:)`); `LabeledContent` exposes one combined element (label in `.label`, value in `.value`); offscreen `Menu` items need `app.swipeUp()` first; `.searchable` in a sheet docks at the bottom and hides the nav bar while active — dismiss via the search bar's close button (localized label, no identifier).
- Headless visual verification: UI tests attach screenshots (`XCTAttachment`, `.keepAlways`); export with `xcrun xcresulttool export attachments` and read the PNGs.
