## Why

The app has grown to 55 source files / ~6,700 lines organized by type — `Models/` (11), `Services/` (18), `Views/` (25) — and that split has stopped carrying information. Only 3 of 11 files in `Models/` are SwiftData entities; the rest are domain vocabulary, transient view drafts, and OpenRouter wire DTOs. `Services/` mixes network clients, pure prompt builders, seeding, read-model math, a media cache, a Keychain wrapper, and two UI-test stubs at one level. A feature like photo match is spread across three folders with nothing naming it as one thing.

The cost is concrete, not cosmetic: the two OpenRouter clients duplicate their entire transport (auth, timeout, cancellation translation, status mapping) so error semantics are maintained twice; `save()`/`rollback()`/`assertionFailure()` is copy-pasted into five view files, which makes every write path unreachable from unit tests; the two AI sheets each carry ~45 lines of identical fetch → build → call → resolve → map-error orchestration inside a `View`; and UI-test stubs plus launch-argument parsing compile into the Release binary. New work in any of these areas currently means editing two or five places and testing none of them.

## What Changes

- Reorganize the app target into layered, feature-owned directories: `App/`, `Domain/`, `Persistence/`, `AI/`, `Media/`, `Features/<feature>/`, `DesignSystem/`, `TestSupport/`. Pure file moves — no type renames, no behavior change. The target's `PBXFileSystemSynchronizedRootGroup` picks nested directories up automatically, so no project-file edits are needed.
- Introduce a single OpenRouter transport shared by both AI features. The two clients keep their distinct request builders and response parsers but stop duplicating Bearer auth, the request timeout, `URLError.cancelled` → `CancellationError` translation, and HTTP status → error mapping.
- Rename the shared AI error taxonomy away from its suggestion-specific name and give it its own file, together with the shared response envelope and the model preference resolution that the photo client currently reaches across a feature boundary to borrow.
- Move SwiftData writes out of view bodies into per-aggregate store types that take a `ModelContext`, preserving today's semantics exactly: a failed save rolls back and leaves no partial write. This makes finish-day conversion, template duplication, and template save unit-testable for the first time.
- Extract the orchestration in the two AI sheets into observable flow models, so fetch/build/call/resolve/error-map logic is testable without UI and the shared sheet shell (no-key gate → settings → error alert with retry → cancellable task) exists once.
- Split the two oversized views — the logging screen (450 lines) and the photo match sheet (502 lines) — into their sections under their feature directories.
- Consolidate all test scaffolding (stub AI services, in-memory key store, UI-test seeding, launch-argument parsing, the photo fixture hook currently embedded in the sheet) into `TestSupport/` and exclude it from Release builds. **BREAKING** for release binaries only: `-uitest-*` launch arguments become Debug-configuration hooks rather than something the shipped app responds to.
- Replace the stringly-typed and duplicated navigation destinations with one route type registered through a single shared modifier, removing the duplicate progression-destination registration in two tabs.
- Move ambient locale resolution out of the `Exercise` entity to the presentation boundary. The already-existing explicit `languageCode` accessors become the only content-resolution path, which retires the documented "unit tests inherit the simulator's device language" hazard for content tests.
- No user-visible behavior changes. Every requirement in the 13 existing capability specs must still hold, and the existing 23 unit-test files and 9 UI-test files must pass without modification except where a type moved or was renamed.

## Capabilities

### New Capabilities
- `app-architecture`: The codebase's structural contract — layer directories and their allowed dependency direction, where persistence writes live and their failure semantics, where AI flow orchestration lives, the single shared AI transport, single-registration navigation routes, presentation-boundary locale resolution, and the behavior-preservation guarantee that binds the whole restructure.
- `test-support-isolation`: All automated-test scaffolding lives in one place, is reachable only from test builds, and is absent from Release binaries; launch-argument parsing is centralized rather than scattered into feature views.

### Modified Capabilities
- `localization`: Content resolution (exercise name, description, instruction steps) is specified as taking an explicit language code, with ambient device-language resolution happening at the presentation boundary — so content-resolution behavior is verifiable without pinning the test host's language.
- `ai-routine-suggestions`: The deterministic-stub test hook requirement is scoped to test builds; the stub must not be present in a Release binary.
- `photo-exercise-match`: Same test-build scoping for the `-uitest-photo-match` hook, and the hook's fixture/detection logic is required to live outside the feature's view code.

## Impact

- **Affected code**: every file in the app target moves; ~10 files change contents. Highest-churn edits are the two OpenRouter clients ([RoutineSuggestionService.swift](gymapp/Services/RoutineSuggestionService.swift), [PhotoExerciseMatchService.swift](gymapp/Services/PhotoExerciseMatchService.swift)), the five view files holding save logic ([ContentView](gymapp/Views/ContentView.swift), [RoutineListView](gymapp/Views/RoutineListView.swift), [TemplateEditForm](gymapp/Views/TemplateEditForm.swift), [ExerciseEditForm](gymapp/Views/ExerciseEditForm.swift)), the two AI sheets, [gymappApp.swift](gymapp/gymappApp.swift), and [Exercise.swift](gymapp/Models/Exercise.swift).
- **Tests**: unit tests referencing `SuggestionError` and `Exercise.localizedName` need mechanical updates for the rename and the moved accessor. New unit coverage becomes possible for store writes and AI flow models. UI tests should need no changes — accessibility identifiers, launch arguments, and on-screen text all stay byte-identical.
- **Build configuration**: Release builds gain a source-exclusion or `#if DEBUG` boundary around `TestSupport/`. UI tests continue to run the Debug configuration, where the hooks remain available.
- **External dependencies**: none. The OpenRouter REST contract — endpoint, auth, structured-output schemas, request payloads — is unchanged byte-for-byte; only the Swift code that assembles it is reorganized.
- **Documentation**: `CLAUDE.md` needs its folder-layout and gotcha notes updated (the locale-pinning hazard for content tests, and the "do not reintroduce a full catalog reseed" warning that now lives with the test-support code).
- **Risk**: mostly mechanical, but the restructure touches every file, so it must land as a sequence of individually green steps rather than one commit. Behavior preservation is verified by the existing suites, which is why they must not be rewritten as part of this change.
