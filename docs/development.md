# Development and testing

[Documentation index](README.md)

## Project setup

Open [Setory.xcodeproj](../Setory.xcodeproj) in Xcode and select the `Setory` scheme. The checked-in project sets the iOS deployment target to 26.5 and Swift language mode to 5.0. [CLAUDE.md](../CLAUDE.md) records Xcode 26.6, the iOS 26.5 SDK, and iPhone 17 Pro as the project's development setup; these are repository settings/notes, not a freshly verified local toolchain inventory.

The application and test directories use `PBXFileSystemSynchronizedRootGroup`: adding files beneath `Setory/`, `SetoryTests/`, or `SetoryUITests/` includes them in their respective targets without manual project-file entries. This `docs/` directory sits outside those source roots.

Core functionality uses bundled data and local persistence. An OpenRouter key is optional and configured in the running app. GIF demonstrations are fetched on demand. There is no package installation or separate app-server startup step in the inspected project.

## Test entry points

The following commands reproduce the repository's documented workflow. Use a scratch DerivedData directory; the project notes that Xcode previews can interfere with app bundles in the default location. Give concurrent runs distinct directories.

```sh
# Unit suite
xcodebuild test -project Setory.xcodeproj -scheme Setory \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -derivedDataPath /tmp/setory-docs-tests \
  -only-testing:SetoryTests

# UI suite through the repository runner
scripts/uitest.sh

# One UI suite with fewer simulator workers and isolated build output
WORKERS=3 DERIVED_DATA=/tmp/setory-ui-tests \
  scripts/uitest.sh -only-testing:SetoryUITests/ProgressUITests
```

[scripts/uitest.sh](../scripts/uitest.sh) boots the base simulator before starting parallel workers, defaults to six workers and the iPhone 17 Pro, and forwards additional arguments. `DEVICE`, `DERIVED_DATA`, and `WORKERS` can override its defaults. Its default test target is the UI suite unless an explicit `-only-testing:` argument is supplied.

These are run instructions, not a claim that the suites were executed for this documentation-only change.

## Coverage map

| Tests | Main concern |
| --- | --- |
| `ModelTests`, `TemplateModelTests`, `DayPlanTests`, `TemplateDraftTests`, `RoutineSummaryTests` | Relationships, order, draft conversion, target counts, and summaries |
| `PersistenceStoreTests`, `ExerciseOverrideTests` | Store writes, injected save failures, and exercise modification rules |
| `MonthGridTests`, `ExerciseHistoryProviderTests`, `ProgressStatsProviderTests` | Calendar behavior, best sets, chart buckets, volume, and records |
| `ExerciseCatalogTests`, `CatalogSeederTests` | Payload validation and repeatable seeding |
| `LocalizationTests`, `ExerciseSearchTests` | Content fallback, language behavior, search/filtering |
| `APIKeyStoreTests`, `AIModelPreferenceTests` | Credentials and model resolution |
| Suggestion builder/parser/service tests | Request shape, response validation, and mocked HTTP exchanges |
| Photo request/service tests, `AIFlowTests` | Image matching contracts and end-to-end flow logic without UI |
| `RequestBodyFixtureTests` | Golden JSON request bodies |
| `ExerciseMediaStoreTests` | Bundled media and cache/network behavior |
| `SetoryUITests/` | Logging, library, routines/templates, progress, AI, photo matching, and visual flows |

Unit tests use Swift Testing; UI tests use XCTest/XCUITest. AI tests substitute service implementations or mock transport instead of depending on live paid requests. Persistence tests can construct in-memory containers and inject a throwing commit closure.

Golden request bodies are located with `#filePath`, not copied from the test bundle. The `UPDATE_REQUEST_FIXTURES=1` test environment switch rewrites them after deliberate changes; review those diffs as API contract changes.

## Debug launch options

[LaunchOptions.swift](../Setory/TestSupport/LaunchOptions.swift) is the single argument parser. [TestOverrides.swift](../Setory/TestSupport/TestOverrides.swift) exposes production-safe accessors and inert Release behavior. Supporting test-only implementations are Debug-gated.

| Argument | Effect |
| --- | --- |
| `-uitest-reset` | Clears user workout/template records and restores modified exercises to the pristine catalog |
| `-uitest-seed` | Adds known workouts after catalog seeding |
| `-uitest-offline-media` | Disables media downloads; app startup also clears the GIF cache for deterministic fallback |
| `-uitest-ai success\|error\|no-key` | Substitutes an in-memory key and stub AI services |
| `-uitest-photo-match success\|error\|no-key` | Same AI substitution plus a fixture photo, avoiding the system camera/picker |
| Any `-uitest` prefix | Disables UIKit animations during test launches |

The standard seeded history is today's bench press (`gv0025`, 10 reps at 40 kg) and run (`gv0685`, 15 minutes), plus squat (`gv0043`, 8 reps at 70 kg) three days earlier. Use reset and seed together for a predictable starting state.

Tests that assert literal UI text pin language/locale. Pure exercise-content tests should pass explicit language codes. Existing test screenshots are attached to results; visual smoke coverage alone does not cover every Log layout. Consult the relevant UI suite for accessibility identifiers and navigation helpers.

## Where to make changes

| Change | Files to inspect together |
| --- | --- |
| Logging fields or validation | `SetEntrySheet`, `DraftSeries`, `WorkoutSeries`, `WorkoutStore`, logging tests, statistics consumers |
| Template behavior | `TemplateEditForm`, `TemplateDraft`, `DayPlan`, `TemplateStore`, template/day-plan tests |
| New exercise data field | `Exercise`, `ExerciseCatalog`, `CatalogSeeder`, transformer, edit/display code, catalog tests |
| Progress calculation | `ProgressStatsProvider`, `ExerciseHistoryProvider`, progression UI, provider tests |
| AI contract | Feature builder, wire types, parser, service, flow, and fixture tests |
| Shared UI styling | `SetoryTheme` and shared rows/chips/media components |
| New persisted model | Entity implementation, `AppModelContainer.schema`, preview/test containers, and schema migration implications |

The project enables `MemberImportVisibility`; files using SwiftData extension APIs need an explicit SwiftData import. Keep code legible, use native language operations, and maintain the architectural boundaries described in [architecture.md](architecture.md).

[openspec/](../openspec) contains workflow configuration and archived change artifacts. Use it for design history, while checking current Swift source for actual behavior. Update these documentation pages alongside behavior changes, especially state lifetime, request fields, and statistics definitions.
