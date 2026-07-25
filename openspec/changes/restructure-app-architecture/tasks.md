Each numbered group is one commit and must leave the app target building with both suites green before the next group starts.

Baseline commands (see `CLAUDE.md`):

```bash
xcodebuild test -project gymapp.xcodeproj -scheme gymapp -destination "platform=iOS Simulator,name=iPhone 17 Pro" -derivedDataPath /tmp/gymapp-deriveddata -only-testing:gymappTests
```

```bash
scripts/uitest.sh
```

## 1. Baseline and probe

- [x] 1.1 Record the pre-restructure baseline: run the unit suite and `scripts/uitest.sh`, save the pass counts, and confirm the working tree is clean on a branch off `main`.
  - **Baseline (commit `07207af`, branch `restructure-app-architecture`): unit 191 passed / 0 failed · UI 33 passed / 0 failed.**
- [x] 1.2 Capture request-body fixtures for byte-equality checks later: serialize one suggestion body and one photo-match body from fixed inputs into `gymappTests/Fixtures/` and add a test asserting each matches its fixture.
  - Three goldens (suggestion, photo-match, photo-match+muscle) located via `#filePath` rather than the test bundle, so no resource-copy phase is involved. Inputs are date-free so goldens can't drift with the host time zone. `UPDATE_REQUEST_FIXTURES=1` rewrites them after an intentional contract change. Unit suite: 195 passed / 0 failed.
- [x] 1.3 Probe the synchronized group: `git mv` one leaf file (e.g. `MonthGrid.swift`) into `gymapp/Domain/Stats/`, build, confirm the target picked it up with no pbxproj edit, then revert. If it fails, stop and reassess the layout strategy before continuing.
  - Confirmed: `MonthGrid.swift` compiled from `gymapp/Domain/Stats/` with no pbxproj change. Move kept rather than reverted — group 2 would only redo it.

## 2. Move files into the layer tree

- [ ] 2.1 Create the layer directories and `git mv` all `Domain/` files into `Entities/`, `Vocabulary/`, `Drafts/`, `Stats/` per design D1. No content edits.
- [ ] 2.2 `git mv` the persistence, media, and AI files into `Persistence/`, `Media/`, `AI/Shared/`, `AI/Suggestion/`, `AI/PhotoMatch/`. No content edits.
- [ ] 2.3 `git mv` the view files into `Features/Log/`, `Features/Catalog/`, `Features/Routines/`, `Features/Progress/`, `Features/AI/`, `Features/Settings/`, and the reusable components into `DesignSystem/`. No content edits.
- [ ] 2.4 `git mv` `gymappApp.swift` and `RootTabView.swift` into `App/`, and the two stub services into `TestSupport/`. Confirm `Assets.xcassets`, `Resources/`, and `Localizable.xcstrings` stayed at the target root.
- [ ] 2.5 Split three files mechanically, no logic changes: `ExerciseCategory` out of `Muscle.swift` into `Domain/Vocabulary/ExerciseCategory.swift`; `InMemoryAPIKeyStore` out of `APIKeyStore.swift` into `TestSupport/InMemoryAPIKeyStore.swift`; `ExerciseFilters` out of `ExerciseFilterBar.swift` into `Features/Catalog/ExerciseFilters.swift`.
- [ ] 2.6 Build and run both suites. Verify no `Models/`, `Services/`, or `Views/` directory remains and that `git log --follow` resolves a moved file's history.

## 3. Thin out the app entry point

- [ ] 3.1 Extract the schema and `ModelContainer` construction from `gymappApp.swift` into `App/AppModelContainer.swift`, keeping the `-uitest-reset` and seeding call order byte-identical for now.
- [ ] 3.2 Extract `UITestSeeding` from `gymappApp.swift` into `TestSupport/UITestSeeding.swift` unchanged.
- [ ] 3.3 Build and run both suites; confirm `-uitest-reset -uitest-seed` still produces the two known sessions.

## 4. Rename and extract the shared AI pieces

- [ ] 4.1 Move `SuggestionError` out of `SuggestionResponseParser.swift` into `AI/Shared/AIError.swift`, renamed to `AIError`, with all cases, localized messages, and `pointsToSettings` unchanged.
- [ ] 4.2 Update the three test files referencing `SuggestionError` (`OpenRouterSuggestionServiceTests`, `SuggestionResponseParserTests`, `PhotoMatchServiceTests`) for the rename only — no assertion changes.
- [ ] 4.3 Extract `PhotoMatchResponseParser` from `PhotoExerciseMatchService.swift` into `AI/PhotoMatch/PhotoMatchResponseParser.swift`.
- [ ] 4.4 Extract `defaultModel`, `modelOverrideDefaultsKey`, and `resolvedModel(defaults:)` from `OpenRouterSuggestionService` into `AI/Shared/AIModelPreference.swift`, copying the key string and default model id verbatim.
- [ ] 4.5 Add a unit test asserting the resolved model for a blank override, a whitespace-only override, and a set override, so the moved `UserDefaults` key is characterized.
- [ ] 4.6 Build and run both suites.

## 5. Collapse the two OpenRouter clients onto one transport

- [ ] 5.1 Add `AI/Shared/OpenRouterClient.swift` owning the endpoint, timeout, key guard, Bearer and content-type headers, `URLError.cancelled` → `CancellationError` translation, and the `HTTPURLResponse` cast, returning `(Data, statusCode)`.
- [ ] 5.2 Rewrite `OpenRouterSuggestionService` on top of `OpenRouterClient`, keeping its own request builder and parser.
- [ ] 5.3 Rewrite `OpenRouterPhotoMatchService` on top of `OpenRouterClient`, removing its cross-feature reads of the suggestion service's statics.
- [ ] 5.4 Add unit tests asserting both features map 401, 402, 429, and a malformed body to the same `AIError` cases, and that a cancelled task throws `CancellationError` from both.
- [ ] 5.5 Run the request-body fixture tests from 1.2 and confirm both bodies are still byte-identical; run both suites.

## 6. Add the persistence stores with tests

- [ ] 6.1 Add `Persistence/WorkoutStore.swift` with `finishDay(date:drafts:)`, moving the draft→session conversion out of the logging screen's `finishDay()` verbatim (insert session, insert ordered series, save, rollback and rethrow on failure).
- [ ] 6.2 Add unit tests for `WorkoutStore`: order and values preserved across drafts, and a failing save leaves the store at its pre-operation contents.
- [ ] 6.3 Add `Persistence/TemplateStore.swift` with `save(_:to:)`, `duplicate(_:)`, and `delete(_:)`, moving the bodies from `TemplateEditForm.save()` and `RoutineListView.duplicate/delete` verbatim.
- [ ] 6.4 Add unit tests for `TemplateStore`: duplicate preserves item order and target sets and derives the same primary/secondary muscle coverage; delete leaves saved sessions untouched.
- [ ] 6.5 Add `Persistence/ExerciseStore.swift` for the exercise-edit save path, with a unit test covering the user-modified flag and that a save failure rolls back.
- [ ] 6.6 Add the shared `persisting(_:_:)` helper preserving today's `assertionFailure`-on-throw policy. Build and run both suites (no view changes yet).

## 7. Switch views onto the stores

- [ ] 7.1 Replace the save logic in the logging screen with `WorkoutStore` + `persisting`.
- [ ] 7.2 Replace the save logic in `TemplateEditForm` and `RoutineListView` with `TemplateStore` + `persisting`.
- [ ] 7.3 Replace the save logic in `ExerciseEditForm` with `ExerciseStore` + `persisting`.
- [ ] 7.4 Verify the boundary invariant: no `modelContext.save/rollback/insert` remains under `Features/`. Build and run both suites.

## 8. Unify navigation routes

- [ ] 8.1 Add `App/ExerciseRoute.swift` with the `ExerciseRoute` enum and an `exerciseDestinations()` view modifier registering both destinations once.
- [ ] 8.2 Switch `ExerciseLibraryView` to `ExerciseRoute`, removing its `navigationDestination(for: String.self)` and its own progression registration.
- [ ] 8.3 Switch `ProgressTabView` and `ExerciseDetailView`'s progression link to `ExerciseRoute`, then delete `ProgressionDestination`.
- [ ] 8.4 Build and run both suites; confirm the progression screen still opens from the Exercises tab, the Progress tab, and the detail screen's history section.

## 9. Move locale resolution to the presentation boundary

- [ ] 9.1 Add `DesignSystem/ExerciseDisplay.swift` holding the ambient-locale conveniences (`localizedName`, `localizedSummary`, `localizedInstructionSteps`) and `matchesSearch(_:)`, with the current device-language and English-fallback behavior unchanged.
- [ ] 9.2 Remove `contentLanguageCode` and the ambient conveniences from `Exercise`, keeping the explicit `languageCode:` accessors on the entity.
- [ ] 9.3 Update `LocalizationTests`, `ExerciseCatalogSourceTests`, `CatalogSeederTests`, and `ExerciseOverrideTests` for the moved accessors, converting language-dependent assertions to explicit language codes where they were relying on the host language.
- [ ] 9.4 Verify the boundary invariant: no `Locale.current` under `Domain/Entities/`. Build and run both suites, plus one Spanish-pinned UI run (`-AppleLanguages "(es)"`) to confirm display sites still localize.

## 10. Quarantine the test scaffolding

- [ ] 10.1 Add `TestSupport/LaunchOptions.swift` as the single reader of `CommandLine.arguments`, exposing typed options for reset, seed, offline media, the two AI scenarios, and animation disabling.
- [ ] 10.2 Add `TestSupport/TestOverrides.swift` with the `#if DEBUG` seam returning overrides in Debug and `nil` in Release, and route `gymappApp`'s dependency resolution through it.
- [ ] 10.3 Move the reset routine into `TestSupport/UITestReset.swift`, delegating to `CatalogSeeder.restorePristineCatalog` and `seedIfNeeded` in `Persistence/`, and preserving the no-parse-unless-edited property.
- [ ] 10.4 Move the photo fixture and UI-test detection out of `PhotoMatchSheet` into `TestSupport/PhotoMatchFixture.swift`, delivering the fixture affordance to the sheet through the environment seam that already supplies its match service.
- [ ] 10.5 Wrap the stub services, in-memory key store, seeding, reset, and fixture in `#if DEBUG`.
- [ ] 10.6 Verify: a Release build compiles and contains no stub service; launching Release with `-uitest-reset -uitest-seed -uitest-ai success` wipes and seeds nothing; `CommandLine.arguments` appears only under `TestSupport/`; both suites still pass in Debug.

## 11. Split the two oversized views

- [ ] 11.1 Extract `DayPlanSection`, `DaySeriesSection`, and `TemplateApplyPicker` out of the logging screen as `@ViewBuilder` sections inside the same `List` — no new containers, no changed insets or spacing.
- [ ] 11.2 Rename `ContentView` to `LogView` and update `RootTabView` and the preview.
- [ ] 11.3 Extract `PhotoMatchCaptureSection` and `PhotoMatchResultsSection` out of `PhotoMatchSheet` as sections inside the same `Form`.
- [ ] 11.4 Run `scripts/uitest.sh -only-testing:gymappUITests/VisualSmokeUITests`, export the screenshot attachments, and compare them against the baseline from 1.1 for layout drift. Run both suites.

## 12. Extract the AI flow models

- [ ] 12.1 Add `Features/AI/SuggestionFlow.swift` as an `@Observable` flow whose `generate(goal:context:service:)` takes its dependencies as parameters, moving the body of `SuggestRoutineSheet.generate()` unchanged including cancellation and error mapping.
- [ ] 12.2 Add `Features/AI/PhotoMatchFlow.swift` the same way for `PhotoMatchSheet.findMatches()`, including the empty-muscle guard and the local-record id resolution.
- [ ] 12.3 Add unit tests for both flows against a stub service and an in-memory container: success resolves names and primary muscles from local records, unknown ids are dropped, `no-key` reaches the no-key state without a request, and an error maps to the expected `AIError`.
- [ ] 12.4 Add `Features/AI/AIFlowScaffold.swift` holding the shared no-key section, progress-with-cancel row, and failure alert with retry plus the AI-settings action, and adopt it in both sheets.
- [ ] 12.5 Run both suites, with particular attention to the AI UI tests for success, error, no-key, and mid-request cancellation in both features.

## 13. Documentation and close-out

- [ ] 13.1 Update `CLAUDE.md`: the new layer layout, the four boundary invariants, the `TestSupport/` + `#if DEBUG` rule, and replace the locale-pinning gotcha with the explicit-language-code guidance.
- [ ] 13.2 Verify the four boundary invariants one final time and confirm the unit and UI pass counts match the 1.1 baseline.
- [ ] 13.3 Run `openspec validate restructure-app-architecture` and archive the change.
