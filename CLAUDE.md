# gymapp

SwiftUI + SwiftData iOS app (Xcode 26.6, iOS 26.5 SDK, iPhone 17 Pro simulator). The pbxproj uses `PBXFileSystemSynchronizedRootGroup`: files added on disk under `gymapp/`, `gymappTests/`, or `gymappUITests/` join their target automatically, nested directories included — no pbxproj edits needed.

## Source layout

Sources are organized by layer and feature, not by type:

- `App/` — entry point, root scene, `AppModelContainer` (schema + launch-time store construction), `ExerciseRoute`.
- `Domain/` — `Entities/` (SwiftData models), `Vocabulary/` (Muscle, Equipment, ExerciseCategory), `Drafts/` (transient view state: DraftSeries, DayPlan, TemplateDraft, ExerciseEdit), `Stats/` (pure read-model math).
- `Persistence/` — catalog seeding, legacy migration, catalog sources, and the write stores (`WorkoutStore`, `TemplateStore`, `ExerciseStore`).
- `AI/` — `Shared/` (`OpenRouterClient`, `AIError`, `AIModelPreference`, key store, environment), `Suggestion/`, `PhotoMatch/`.
- `Media/`, `Features/<feature>/`, `DesignSystem/`, `TestSupport/`.

Four boundary invariants, each a one-line grep — keep them true:

| Invariant | Check |
|---|---|
| Entities are persistence-only | no `Locale.current` or `import SwiftUI` under `Domain/Entities/` |
| Features don't write | no `modelContext.save/rollback/insert/delete` under `Features/` |
| Test hooks are quarantined | `CommandLine.arguments` appears only under `TestSupport/` |
| One transport | exactly one type builds a `URLRequest` for the OpenRouter endpoint |

Writes go through the `Persistence` stores, called from views via `persisting(_:_:)`, which holds the failure policy (roll back, trap in Debug, continue in Release). Both AI features share `OpenRouterClient`; each keeps its own request builder and response parser. The two AI sheets keep their request cycle in `SuggestionFlow` / `PhotoMatchFlow` so it is unit-testable, and share `AIFlowScaffold` for the no-key, progress, and failure states.

## Build & test

Always pass a scratch `-derivedDataPath` — Xcode's previews agent clobbers the default DerivedData app bundle and launches then crash at dyld.

```bash
# Unit tests
xcodebuild test -project gymapp.xcodeproj -scheme gymapp \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -derivedDataPath /tmp/gymapp-deriveddata \
  -only-testing:gymappTests

# UI tests — use the fast runner (pre-boots the base simulator, runs 6
# parallel simulator clones)
scripts/uitest.sh
scripts/uitest.sh -only-testing:gymappUITests/ProgressUITests
WORKERS=3 scripts/uitest.sh
DERIVED_DATA=/tmp/gymapp-dd-mybranch scripts/uitest.sh
```

For fast iteration: `xcodebuild build-for-testing` once against the same DerivedData path, then `test-without-building` per run.

Notes:
- Cloned-simulator workers fail preflight ("Busy") unless the base simulator is booted first; the script handles this via `simctl bootstatus -b`.
- SourceKit live diagnostics are often stale for freshly created files ("No such module", "Cannot find type"); trust `xcodebuild`.
- Unit tests run in the host app and inherit the simulator's device language (Spanish on this machine). For exercise *content* this no longer matters: pass an explicit language code (`localizedName(languageCode:)`, `matchesSearch(_:languageCode:)`, `ExerciseFilters.apply(..., languageCode:)`) and the assertion holds on any host. The ambient conveniences live in `DesignSystem/ExerciseDisplay.swift` and are for display sites. String-catalog UI text still needs `-testLanguage en|es`.
- Concurrent sessions must pass different `DERIVED_DATA` paths: two runs sharing one path compile into the same test bundle, so one branch's in-progress tests appear in the other's results.
- Under 6 workers the occasional UI test flakes on keyboard focus ("Neither element nor any descendant has keyboard focus") or a sheet timeout. Re-run the named test in isolation before treating it as a regression.
- SwiftData upserts on a unique-constraint conflict rather than throwing, so a failing save can't be provoked that way; the stores take an injectable `commit` seam for their rollback tests. `rollback()` also guarantees only that nothing was *persisted* — it does not revert in-memory mutations on an already-saved object.

## UI-test launch arguments

`TestSupport/LaunchOptions.swift` is the only place that reads `CommandLine.arguments`, and `TestSupport/TestOverrides.swift` is the only file with a Debug/Release conditional — everything in `TestSupport/` is `#if DEBUG`, so a Release binary contains none of it and these arguments are inert there (verified by symbol counts: the stubs and the `-uitest` literals are absent from Release). Previews that build stub AI dependencies are gated too, since `#Preview` expands in Release.

Any argument prefixed `-uitest` also disables UIKit animations so XCUITest quiescence waits don't pay animation durations.

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
- Headless visual verification: UI tests attach screenshots (`XCTAttachment`, `.keepAlways`); export with `xcrun xcresulttool export attachments` and read the PNGs. `VisualSmokeUITests` covers the library, detail, picker, and AI surfaces — **not** the Log tab, so log-screen layout changes need a `simctl io screenshot` check or a new case.
- `gymappTests/Fixtures/*.json` are golden OpenRouter request bodies, located via `#filePath` rather than the test bundle. A diff there means the REST contract moved; `UPDATE_REQUEST_FIXTURES=1` rewrites them after an intentional change.
