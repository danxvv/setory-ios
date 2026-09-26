## Context

The app target is 55 Swift files / ~6,664 lines split three ways by type: `Models/` (11), `Services/` (18), `Views/` (25). See [proposal.md](proposal.md) for why that split has stopped paying off.

Constraints that shape this design:

- **`PBXFileSystemSynchronizedRootGroup`.** All three targets use it, and the pbxproj carries no `membershipExceptions`. Nested directories under `Setory/` join the target automatically, so the whole reorganization is `git mv` with no project-file surgery. This is the single biggest reason the restructure is cheap here.
- **No per-directory namespacing in Swift.** One module, so directories are organizational only. Moving a file cannot break a reference or require a new `import`. Every genuine risk in this change therefore comes from the ~10 files whose *contents* change, not from the ~45 that only move.
- **Debug compilation condition already set.** The app target's Debug configuration defines `SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)"`, and the scheme's Test action builds Debug. `#if DEBUG` is therefore a working seam for excluding test scaffolding from Release without touching build settings.
- **The existing suites are the oracle.** 23 unit-test files and 9 UI-test files encode current behavior. They must pass with mechanical updates only — that is what makes "no behavior change" a checkable claim rather than an intention.
- **`MemberImportVisibility` is enabled.** Any file using a SwiftData extension member needs an explicit `import SwiftData`. Newly created files must not forget it.

## Goals / Non-Goals

**Goals:**

- Directory layout that names features and layers, with boundary invariants that can be audited by grep rather than by convention.
- One OpenRouter transport, so auth, timeout, cancellation translation, and status mapping exist once.
- SwiftData writes reachable from unit tests: draft→session conversion, template duplication, template save, exercise edit save.
- AI flow orchestration reachable from unit tests, with one shared sheet shell for the no-key/progress/error states.
- Test scaffolding in one directory and out of Release binaries.
- Byte-identical OpenRouter request bodies, on-screen text, and accessibility identifiers.

**Non-Goals:**

- No MVVM sweep. `@Query`-straight-into-the-view stays for the CRUD screens ([ExerciseLibraryView](Setory/Views/ExerciseLibraryView.swift), [RoutineListView](Setory/Views/RoutineListView.swift), [ProgressTabView](Setory/Views/ProgressTabView.swift)); only the AI flows get flow models.
- No change to the pure-statics style of the builders, parsers, and stats providers. That style is why they are well covered, and it stays.
- No new abstraction over SwiftData. Stores take a `ModelContext` directly; no repository protocol, no generic CRUD layer.
- No feature work, no UI redesign, no OpenRouter contract change, no new dependency.
- No test rewriting beyond renames and moved symbols. Adding *new* tests for newly reachable code is in scope; changing existing assertions is not.
- Not multi-module. Splitting into SPM targets to make layer boundaries compiler-enforced is deliberately deferred (see Decisions).

## Decisions

### D1: Layer directories, with `Features/` owning screens

Target tree, with every current file's destination:

```
Setory/
  App/           SetoryApp.swift · RootTabView.swift · AppModelContainer.swift* · ExerciseRoute.swift*
  Domain/
    Entities/    Exercise.swift · WorkoutSession.swift · RoutineTemplate.swift
    Vocabulary/  Muscle.swift · ExerciseCategory.swift* · Equipment.swift
    Drafts/      DraftSeries.swift · DayPlan.swift · TemplateDraft.swift
    Stats/       ProgressStatsProvider.swift · ExerciseHistoryProvider.swift
                 TemplateNameSuggester.swift · MonthGrid.swift
  Persistence/   CatalogSeeder.swift · LegacyCatalogMigrator.swift · ExerciseCatalogSource.swift
                 WorkoutStore.swift* · TemplateStore.swift* · ExerciseStore.swift*
  AI/
    Shared/      OpenRouterClient.swift* · AIError.swift* · AIModelPreference.swift*
                 ChatCompletionResponse.swift · APIKeyStore.swift · AIEnvironment.swift
    Suggestion/  RoutineSuggestionService.swift · SuggestionPromptBuilder.swift
                 SuggestionResponseParser.swift · SuggestionModels.swift
    PhotoMatch/  PhotoExerciseMatchService.swift · PhotoMatchRequestBuilder.swift
                 PhotoMatchResponseParser.swift* · PhotoMatchModels.swift · PhotoPreprocessor.swift
  Media/         ExerciseMediaStore.swift
  Features/
    Log/         LogView.swift · DayPlanSection.swift* · DaySeriesSection.swift*
                 TemplateApplyPicker.swift* · SetEntrySheet.swift · MonthCalendarView.swift
    Catalog/     ExerciseLibraryView.swift · ExerciseDetailView.swift · ExerciseEditForm.swift
                 ExerciseFilters.swift* · ExerciseFilterBar.swift
                 ExercisePickerSheet.swift · ExerciseMultiPicker.swift
    Routines/    RoutineListView.swift · RoutineDetailView.swift · TemplateEditForm.swift
    Progress/    ProgressTabView.swift · ExerciseProgressionView.swift
    AI/          SuggestRoutineSheet.swift · SuggestionFlow.swift* · PhotoMatchSheet.swift
                 PhotoMatchFlow.swift* · PhotoMatchCaptureSection.swift* ·
                 PhotoMatchResultsSection.swift* · AIFlowScaffold.swift* ·
                 AISettingsView.swift · CameraCaptureView.swift
    Settings/    AboutView.swift
  DesignSystem/  MuscleChips.swift · ExerciseThumbnailView.swift · ExerciseMediaView.swift
                 AnimatedGIFView.swift · RoutineMediaSheet.swift
                 ExerciseDisplay.swift* · PresentedBinding.swift* · RowActionLabel.swift*
  TestSupport/   LaunchOptions.swift* · TestOverrides.swift* · UITestReset.swift*
                 UITestSeeding.swift* · StubSuggestionService.swift · StubPhotoMatchService.swift
                 InMemoryAPIKeyStore.swift* · PhotoMatchFixture.swift*
  Assets.xcassets · Resources/ · Localizable.xcstrings      (unchanged, stay at target root)
```

`*` = new file or content extracted from an existing one. Everything else is a pure `git mv`.

Four boundary invariants make the layering auditable, each a one-line grep:

| Invariant | Check |
|---|---|
| Entities are persistence-only | no `Locale.current` or `import SwiftUI` under `Domain/Entities/` |
| Features don't write | no `modelContext.save/rollback/insert` under `Features/` |
| Test hooks are quarantined | `CommandLine.arguments` appears only under `TestSupport/` |
| One transport | exactly one type builds a `URLRequest` for the OpenRouter endpoint |

*Alternatives considered.* **Keep type-based folders, add subfolders inside them** — cheaper, but leaves a feature's files split across three trees, which is the actual complaint. **Split into SPM modules** (`Domain`, `Persistence`, `AI`, `Features`) so boundaries are compiler-enforced — strictly better enforcement, but it means real pbxproj work, loses the synchronized-group convenience, and forces `public` annotations across the codebase. Deferred: the grep invariants get most of the value now, and this tree is the prerequisite for modularizing later if it becomes worth it.

### D2: One transport, two clients

[OpenRouterSuggestionService](Setory/Services/RoutineSuggestionService.swift:53) and [OpenRouterPhotoMatchService](Setory/Services/PhotoExerciseMatchService.swift:41) are identical except for the body builder and the parser. The photo client already borrows `OpenRouterSuggestionService.endpoint`, `.requestTimeout`, and `.resolvedModel` across a feature boundary — that borrow is the seam telling us where the shared type goes.

```swift
struct OpenRouterClient: Sendable {
    static let endpoint: URL
    static let requestTimeout: TimeInterval
    init(keyStore: any APIKeyStoring, session: URLSession, defaults: UserDefaults)
    var model: String                                     // via AIModelPreference
    func send(body: (_ model: String) throws -> Data) async throws -> (Data, Int)
}
```

`send` owns the key guard, Bearer header, content type, timeout, the `URLError.cancelled` → `CancellationError` translation, and the `HTTPURLResponse` cast. Each feature's service keeps its own `requestBody(...)` and its own parser, so the two request shapes (plain string user message vs. multimodal content array) and the two validation policies (empty result is an error / empty result is success) stay where they belong.

`SuggestionError` becomes **`AIError`** in `AI/Shared/AIError.swift` — it already serves both features and its current home inside the suggestion parser is the clearest naming casualty of the organic growth. `AIModelPreference` takes over `defaultModel`, `modelOverrideDefaultsKey`, and `resolvedModel(defaults:)`; the `UserDefaults` key string is unchanged, so no user's stored override is disturbed. `PhotoMatchResponseParser` moves out of the service file into its own.

*Alternatives considered.* **Generic `OpenRouterClient<Request, Response>`** — collapses the two services into one type, but the divergent parsers (empty-is-error vs. empty-is-success) and the divergent request shapes would come back as generic parameters or closures anyway, for no readability gain. **Protocol with default implementations** — Swift protocol extensions can't hold the stored `keyStore`/`session`/`defaults`, so each conformer would still declare them; a struct wins.

### D3: Stores own writes; the failure *policy* lives once

`save()` / `rollback()` / `assertionFailure()` currently appears in five view files ([ContentView:377](Setory/Views/ContentView.swift:377), [RoutineListView:172](Setory/Views/RoutineListView.swift:172) and `:182`, [TemplateEditForm:217](Setory/Views/TemplateEditForm.swift:217), [ExerciseEditForm:196](Setory/Views/ExerciseEditForm.swift:196)). Three store structs replace it:

```swift
struct WorkoutStore  { let context: ModelContext
    func finishDay(date: Date, drafts: [DraftSeries]) throws }
struct TemplateStore { let context: ModelContext
    func save(_ draft: TemplateDraft, to template: RoutineTemplate?) throws
    func duplicate(_ template: RoutineTemplate) throws
    func delete(_ template: RoutineTemplate) throws }
struct ExerciseStore { let context: ModelContext
    func save(_ edit: ExerciseEdit, to exercise: Exercise) throws }
```

Each method mutates, saves, and on failure rolls back and rethrows — no partial write survives, exactly as today.

The spec requires that views not be *where save failure is handled*. Views are still the callers, so the policy goes into one shared helper used at every call site:

```swift
// DesignSystem/PresentedBinding.swift (or its own file)
func persisting(_ what: StaticString, _ work: () throws -> Void)   // assertionFailure on throw
```

Views become `persisting("finish day") { try workoutStore.finishDay(...) }`. Same Debug-crash / Release-continue behavior as today, declared once instead of five times, and the store methods are independently testable with an in-memory container.

*Alternatives considered.* **Stores swallow errors and return `Bool`** — hides failures from tests and makes the assertion policy unstateable. **A repository protocol per aggregate** — buys mockability the app doesn't need, since an in-memory `ModelContainer` is already the better test double. **Actor-isolated stores** — writes are all main-actor `@MainActor` view work today; introducing isolation would be a behavior change, not a restructure.

### D4: Flow models take dependencies as method parameters

[`findMatches()`](Setory/Views/PhotoMatchSheet.swift:429) and [`generate()`](Setory/Views/SuggestRoutineSheet.swift:147) are ~45 lines each of fetch → build → call → resolve → map-error, structurally the same twice, and reachable only through a `View`. Each becomes an `@Observable` flow:

```swift
@Observable final class SuggestionFlow {
    enum Phase { case idle, running, failed(AIError) }
    private(set) var phase: Phase = .idle
    func generate(goal: String, context: ModelContext,
                  service: any RoutineSuggestionService) async -> RoutineSuggestion?
}
```

Dependencies arrive **as method parameters**, not through `init`. The reason is SwiftUI mechanics: `@Environment` values (`modelContext`, the service, the key store) are not available when a `@State` initial value is constructed, so an init-injected model needs a `configure(...)` call from `.task`/`onAppear` — a lifecycle step that is easy to forget and awkward to assert. Parameter injection keeps `@State private var flow = SuggestionFlow()` trivial and lets a unit test call the exact same method with an in-memory context and a stub service.

Resolution keeps today's rule: returned ids resolve against local `Exercise` records, and name, muscle-target metadata, and media come from those records only, never from the model response. Unknown ids are dropped.

`AIFlowScaffold` holds the shell both sheets duplicate today: the no-key section with its AI-settings route, the in-flight progress row with cancel, and the failure alert with retry plus a settings action for key/credit errors. Cancellation stays `Task` + `matchTask?.cancel()`, since `CancellationError` handling is already correct on both paths.

*Alternatives considered.* **`@Observable` with init injection + `configure()`** — matches the usual MVVM shape but adds the lifecycle trap above. **Plain `struct` "use case" types with all state in the view** — testable, but leaves the 11 `@State` properties of the photo sheet where they are, so the view doesn't actually get smaller. **Keeping the logic in the views and testing through XCUITest** — already possible and already slow; the point is to move these cases into the sub-second unit suite.

### D5: Locale resolution moves to the presentation boundary

[`Exercise.contentLanguageCode`](Setory/Models/Exercise.swift:49) reads `Locale.current` inside a `@Model`, which is exactly why CLAUDE.md documents "unit tests inherit the simulator's device language" as a hazard. The explicit accessors `localizedName(languageCode:)`, `localizedSummary(languageCode:)`, and `localizedInstructionSteps(languageCode:)` already exist and stay on the entity; the ambient-locale conveniences (`localizedName`, `localizedSummary`, `localizedInstructionSteps`) move to `DesignSystem/ExerciseDisplay.swift` as an extension.

`matchesSearch(_:)` is the one wrinkle: it consults the resolved display name *and* the canonical English name, so it depends on the ambient language. It moves to the presentation extension alongside the conveniences, keeping its dual-vocabulary behavior byte-identical — the property that lets a Spanish-device user find "bench press" off a machine's label.

Four unit-test files touch these accessors (`LocalizationTests`, `ExerciseCatalogSourceTests`, `CatalogSeederTests`, `ExerciseOverrideTests`); their updates are mechanical, and language-pinned assertions can migrate to explicit language codes as they are touched.

*Alternatives considered.* **Inject a locale provider into the entity** — a `@Model` gaining a dependency is worse than the ambient read it replaces. **Leave it alone** — defensible, since it works; but it keeps a documented test hazard alive for the one thing the app most needs to test in two languages.

### D6: Test scaffolding behind a single `#if DEBUG` seam

`TestOverrides` is the one conditional the app entry point sees:

```swift
// TestSupport/TestOverrides.swift
enum TestOverrides {
    #if DEBUG
    static func resolve() -> Overrides? { LaunchOptions.current.overrides }
    #else
    static func resolve() -> Overrides? { nil }
    #endif
}
```

`SetoryApp` asks once for overrides and otherwise builds the real dependency graph. `#if DEBUG` also wraps the stub services, the in-memory key store, `UITestSeeding`, `UITestReset`, and `PhotoMatchFixture`, so a Release binary contains none of them and the `-uitest-*` arguments become inert. `LaunchOptions` is the only reader of `CommandLine.arguments`, which retires the stray read at [PhotoMatchSheet:479](Setory/Views/PhotoMatchSheet.swift:479); the sheet receives its fixture affordance through the same environment seam that already supplies its match service.

The reset routine keeps its current shape and its performance property: delete custom exercises, re-align edited ones, and parse the bundled catalog **only when an edited exercise exists**. `CatalogSeeder.restorePristineCatalog` and `seedIfNeeded` stay in `Persistence/` — they are real catalog logic with real unit tests — and `UITestReset` delegates to them.

*Alternatives considered.* **`EXCLUDED_SOURCE_FILE_NAMES[config=Release]`** — avoids `#if DEBUG` inside the scaffolding files, but the *call site* in `SetoryApp` would still reference types that no longer exist in Release, so a conditional there is unavoidable; adding a build setting on top buys nothing and hides the boundary from the source. **Move the stubs into the UI-test target** — impossible: XCUITest drives the app out of process and cannot inject types into it. **Leave scaffolding shipping** — status quo; it works, but it puts a network-stubbing seam and a data-wipe path in the shipped binary.

### D7: One route type, one registration

`ExerciseRoute` replaces the bare-`String` destination in [ExerciseLibraryView:53](Setory/Views/ExerciseLibraryView.swift:53) and the `ProgressionDestination` registered separately in [ExerciseLibraryView:56](Setory/Views/ExerciseLibraryView.swift:56) and [ProgressTabView:42](Setory/Views/ProgressTabView.swift:42):

```swift
enum ExerciseRoute: Hashable { case detail(String), progression(String) }
extension View { func exerciseDestinations() -> some View }   // App/ExerciseRoute.swift
```

Any stack that needs those screens applies `.exerciseDestinations()`. `ProgressionDestination` disappears; no UI test references either type name, and pushed screens are unchanged.

*Alternatives considered.* **Keep `ProgressionDestination`, just share the modifier** — smaller diff, but leaves `navigationDestination(for: String.self)` claiming every `String` value pushed in those stacks, which is the more fragile half of the problem.

## Risks / Trade-offs

- **Nested directories might not be picked up by the synchronized group as expected** → Verified first, before anything else: move one leaf file into a new subdirectory, build, revert if it fails. If nested groups misbehave, the fallback is a flat-but-prefixed naming scheme in the existing directories, and the rest of the design (D2–D7) proceeds unchanged.
- **A 55-file move makes `git log --follow` and in-flight branches painful** → All moves use `git mv` in dedicated move-only commits with no content edits, so renames are detected cleanly. The branch currently in flight (`add-localized-exercise-names`) lands before this change starts.
- **`AIError` rename touches three test files; `localizedName` relocation touches four** → Both are mechanical, compiler-caught renames. No assertion text changes, so a test that compiles and passes is evidence the behavior held.
- **Extracting `AIModelPreference` touches the `UserDefaults` key** → The key string `aiModelOverride` and the default model id are copied verbatim; a unit test asserts the resolved model for both "override set" and "override blank" before and after, so a stored user preference cannot silently stop resolving.
- **Splitting the two big views can quietly change layout** → Sections extract as `@ViewBuilder` properties/subviews inside the same `List`/`Form`, never into new containers. `VisualSmokeUITests` screenshots are the check; any diff in inset, spacing, or section grouping means the split was wrong.
- **`#if DEBUG` scaffolding can rot, since Release never compiles it** → Accepted trade-off, bounded by the fact that both test suites build Debug, so the scaffolding is exercised on every test run. The Release path gets one build in the verification step to prove it compiles without the directory.
- **Flow-model extraction is the only step with real behavior risk** (task cancellation, `defer { isMatching = false }` ordering, the `phase = .results(...)` transition) → It lands last, alone, after everything else is green, so a regression there is isolated by construction. The AI UI tests already cover success, error, no-key, and mid-request cancel for both features.
- **"No behavior change" is only as strong as the suites** → Coverage is good on pure logic and the AI flows but thin on the write paths, which is precisely what D3 fixes. New store tests are written *before* the call sites are switched over, so they characterize current behavior rather than ratify the new code.

## Migration Plan

Twelve steps, each independently buildable with both suites green. Steps 1–3 are content-free moves; 4–9 are localized content changes; 10–11 are the risky extractions, deliberately last.

1. **Probe** the synchronized-group behavior with one file in one new subdirectory. Build. Revert.
2. **Move** all files into the layer tree (`git mv` only, no edits). Split `Muscle.swift`'s `ExerciseCategory` out, `APIKeyStore.swift`'s `InMemoryAPIKeyStore` out, and `ExerciseFilterBar.swift`'s `ExerciseFilters` out — three mechanical file splits, no logic touched.
3. **Extract** `AppModelContainer` and `UITestSeeding` out of `SetoryApp.swift`.
4. **Rename** `SuggestionError` → `AIError` into its own file; extract `PhotoMatchResponseParser` and `AIModelPreference`. Update the three test files.
5. **Introduce** `OpenRouterClient`; rewrite both services on top of it. Assert request-body byte equality against fixtures.
6. **Add** `WorkoutStore`, `TemplateStore`, `ExerciseStore` with unit tests, and the `persisting` helper — without changing any view yet.
7. **Switch** the five view call sites to the stores. `Features/` becomes write-free.
8. **Introduce** `ExerciseRoute` + `.exerciseDestinations()`; delete `ProgressionDestination`.
9. **Move** the ambient-locale conveniences and `matchesSearch` to `DesignSystem/ExerciseDisplay.swift`. Update the four test files.
10. **Consolidate** test scaffolding into `TestSupport/` behind `TestOverrides`; remove the launch-argument read from the photo sheet. Verify a Release build compiles and that `-uitest-*` is inert in it.
11. **Split** the logging screen and the photo match sheet into their sections. Compare `VisualSmokeUITests` screenshots.
12. **Extract** `SuggestionFlow` and `PhotoMatchFlow` plus `AIFlowScaffold`; add flow unit tests. Update `CLAUDE.md`'s layout notes and gotcha list.

**Rollback:** each step is one commit, and steps 1–3 and 8–9 are revertible in isolation. Steps 5, 7, and 12 replace a working implementation, so each keeps its predecessor's tests unchanged — reverting the commit restores the prior behavior with no test edits needed. Nothing in this change touches the persistent store's schema or `UserDefaults` keys, so there is no data migration and no rollback risk to user data.

## Open Questions

- **Should `LogView` keep its `ContentView` name?** The rename is safe (no UI test references the type; only its `#Preview` and `RootTabView` mention it) and `ContentView` is a leftover template name that says nothing. Proceeding with the rename unless there is a reason to preserve it.
- **Where do the new store types' errors surface for the user?** This change deliberately preserves today's silent-in-Release behavior via `persisting`. Whether a save failure should show the user an alert is a real product question, but it is a behavior change and therefore a separate proposal.
- **Do the `Domain/Stats` providers belong in `Domain/` or `Features/Progress/`?** They are pure functions over fetched models and are consumed by two features (progress charts and the exercise detail history section), so `Domain/Stats/` is the call made here. Revisit only if a third consumer with different needs appears.
