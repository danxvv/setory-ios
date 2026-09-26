# Source-file reference

[Documentation index](README.md)

Paths below link to every Swift source in the application target. Directories are organizational modules in one target. For behavior across files, start with [screens](screens.md) and [architecture](architecture.md).

## Setory/AI/PhotoMatch

| File | Responsibility |
| --- | --- |
| [PhotoExerciseMatchService.swift](../Setory/AI/PhotoMatch/PhotoExerciseMatchService.swift) | Photo service protocol and OpenRouter builder/transport/parser composition. |
| [PhotoMatchModels.swift](../Setory/AI/PhotoMatch/PhotoMatchModels.swift) | Photo payload, confidence vocabulary, and structured match results. |
| [PhotoMatchRequestBuilder.swift](../Setory/AI/PhotoMatch/PhotoMatchRequestBuilder.swift) | Photo limits, hint normalization, muscle filtering, multimodal prompt, and response schema. |
| [PhotoMatchResponseParser.swift](../Setory/AI/PhotoMatch/PhotoMatchResponseParser.swift) | Filters unknown and duplicate match IDs, allowing valid empty results. |
| [PhotoPreprocessor.swift](../Setory/AI/PhotoMatch/PhotoPreprocessor.swift) | Image downsizing, JPEG encoding, and inline data URL construction. |

## Setory/AI/Shared

| File | Responsibility |
| --- | --- |
| [AIEnvironment.swift](../Setory/AI/Shared/AIEnvironment.swift) | Environment dependency seams for key storage, AI services, and a test photo. |
| [AIError.swift](../Setory/AI/Shared/AIError.swift) | Shared typed AI errors, localized descriptions, and settings-vs-retry recovery classification. |
| [AIModelPreference.swift](../Setory/AI/Shared/AIModelPreference.swift) | Default model ID and trimmed UserDefaults override resolution. |
| [APIKeyStore.swift](../Setory/AI/Shared/APIKeyStore.swift) | APIKeyStoring protocol and Keychain generic-password implementation. |
| [ChatCompletionResponse.swift](../Setory/AI/Shared/ChatCompletionResponse.swift) | HTTP error mapping, completion-envelope validation, and structured-content JSON decoding. |
| [OpenRouterClient.swift](../Setory/AI/Shared/OpenRouterClient.swift) | Shared authenticated AI transport, timeout, model resolution, and cancellation translation. |

## Setory/AI/Suggestion

| File | Responsibility |
| --- | --- |
| [RoutineSuggestionService.swift](../Setory/AI/Suggestion/RoutineSuggestionService.swift) | Suggestion service protocol and OpenRouter builder/transport/parser composition. |
| [SuggestionModels.swift](../Setory/AI/Suggestion/SuggestionModels.swift) | Codable suggestion request/history/catalog and response structures. |
| [SuggestionPromptBuilder.swift](../Setory/AI/Suggestion/SuggestionPromptBuilder.swift) | History summary, bounded catalog selection, goal keyword matching, prompt, schema, and request body. |
| [SuggestionResponseParser.swift](../Setory/AI/Suggestion/SuggestionResponseParser.swift) | Rejects unusable suggestions, filters IDs, deduplicates items, and clamps set targets. |

## Setory/App

| File | Responsibility |
| --- | --- |
| [AppModelContainer.swift](../Setory/App/AppModelContainer.swift) | Defines the five-model schema and constructs the disk store, reset/seed sequence, and startup failure handling. |
| [ExerciseRoute.swift](../Setory/App/ExerciseRoute.swift) | Shared typed navigation to exercise detail and progression, plus destination registration. |
| [RootTabView.swift](../Setory/App/RootTabView.swift) | Four root tabs, Routines navigation stack, accent tint, and rounded typography. |
| [SetoryApp.swift](../Setory/App/SetoryApp.swift) | Application entry point; constructs and injects persistence, media, credentials, and AI services. |

## Setory/DesignSystem

| File | Responsibility |
| --- | --- |
| [AnimatedGIFView.swift](../Setory/DesignSystem/AnimatedGIFView.swift) | ImageIO-to-UIImageView animation bridge with callback generation cancellation. |
| [ExerciseDisplay.swift](../Setory/DesignSystem/ExerciseDisplay.swift) | Current-language exercise display/search/sorting conveniences and localized session names. |
| [ExerciseMediaView.swift](../Setory/DesignSystem/ExerciseMediaView.swift) | Demonstration loading, GIF playback, thumbnail fallback, retry, and attribution. |
| [ExerciseRowContent.swift](../Setory/DesignSystem/ExerciseRowContent.swift) | Reusable exercise-list row content including thumbnail and metadata. |
| [ExerciseThumbnailView.swift](../Setory/DesignSystem/ExerciseThumbnailView.swift) | Small bundled exercise image with category fallback. |
| [SetoryTheme.swift](../Setory/DesignSystem/SetoryTheme.swift) | Shared colors, card/list styling, primary buttons, icons, and introductory panels. |
| [MuscleChips.swift](../Setory/DesignSystem/MuscleChips.swift) | Reusable primary/secondary muscle label chips. |
| [NumberBadge.swift](../Setory/DesignSystem/NumberBadge.swift) | Visual numbering for zero-based ordered rows. |
| [Persisting.swift](../Setory/DesignSystem/Persisting.swift) | View call-site wrapper that applies assertion-based reporting to thrown persistence errors. |
| [RoutineMediaSheet.swift](../Setory/DesignSystem/RoutineMediaSheet.swift) | Reusable demonstration sheet and routine-thumbnail action component. |

## Setory/Domain/Drafts

| File | Responsibility |
| --- | --- |
| [DayPlan.swift](../Setory/Domain/Drafts/DayPlan.swift) | Stages a template as a temporary checklist, merges duplicate exercises, and counts logged drafts. |
| [DraftSeries.swift](../Setory/Domain/Drafts/DraftSeries.swift) | Unsaved set values and shared human-readable series summaries. |
| [ExerciseEdit.swift](../Setory/Domain/Drafts/ExerciseEdit.swift) | Normalizes exercise form values and validates name/primary muscles. |
| [TemplateDraft.swift](../Setory/Domain/Drafts/TemplateDraft.swift) | Value-state template editing, session conversion, name suggestion access, and item write mapping. |

## Setory/Domain/Entities

| File | Responsibility |
| --- | --- |
| [Exercise.swift](../Setory/Domain/Entities/Exercise.swift) | Persisted exercise metadata, stable ID, content translations, and explicit-language lookup/search. |
| [RoutineTemplate.swift](../Setory/Domain/Entities/RoutineTemplate.swift) | Defines RoutineTemplate and RoutineTemplateItem, ordering, target limits, and derived muscle coverage. |
| [WorkoutSession.swift](../Setory/Domain/Entities/WorkoutSession.swift) | Defines WorkoutSession and WorkoutSeries, day identity, series ordering, and worked muscles. |

## Setory/Domain/Stats

| File | Responsibility |
| --- | --- |
| [ExerciseHistoryProvider.swift](../Setory/Domain/Stats/ExerciseHistoryProvider.swift) | Groups saved exercise history and selects best sets and recent sessions. |
| [MonthGrid.swift](../Setory/Domain/Stats/MonthGrid.swift) | Calendar month dates, weekday ordering, leading blanks, and adjacent-month calculations. |
| [ProgressStatsProvider.swift](../Setory/Domain/Stats/ProgressStatsProvider.swift) | Weekly totals, muscle balance, progression values, weighted volume, and record flags. |
| [TemplateNameSuggester.swift](../Setory/Domain/Stats/TemplateNameSuggester.swift) | Deterministic localized name suggestions from primary-muscle votes and exercise category. |

## Setory/Domain/Vocabulary

| File | Responsibility |
| --- | --- |
| [Equipment.swift](../Setory/Domain/Vocabulary/Equipment.swift) | Equipment vocabulary, stable serialized raw values, and localized labels. |
| [ExerciseCategory.swift](../Setory/Domain/Vocabulary/ExerciseCategory.swift) | Strength/cardio category vocabulary used by catalog data and set entry. |
| [Muscle.swift](../Setory/Domain/Vocabulary/Muscle.swift) | Muscle vocabulary, stable serialized raw values, and localized labels. |

## Setory/Features/AI

| File | Responsibility |
| --- | --- |
| [AIFlowScaffold.swift](../Setory/Features/AI/AIFlowScaffold.swift) | Shared missing-key section, progress/cancel presentation, and AI failure alert helpers. |
| [AISettingsView.swift](../Setory/Features/AI/AISettingsView.swift) | Key management, model preference, privacy explanation, and About navigation. |
| [CameraCaptureView.swift](../Setory/Features/AI/CameraCaptureView.swift) | UIKit camera capture bridge returning a UIImage to the photo flow. |
| [PhotoMatchCaptureSection.swift](../Setory/Features/AI/PhotoMatchCaptureSection.swift) | Photo attachment/removal UI, description and muscle hints, and send/cancel controls. |
| [PhotoMatchFlow.swift](../Setory/Features/AI/PhotoMatchFlow.swift) | Observable request controller; image preparation, catalog fetch/filter, service call, and ID resolution. |
| [PhotoMatchResultsSection.swift](../Setory/Features/AI/PhotoMatchResultsSection.swift) | Confidence-labelled selectable matches, empty results, and return-to-capture action. |
| [PhotoMatchSheet.swift](../Setory/Features/AI/PhotoMatchSheet.swift) | Capture/results sheet orchestration, photo selection, settings, and confirmed exercise callback. |
| [SuggestRoutineSheet.swift](../Setory/Features/AI/SuggestRoutineSheet.swift) | Goal input, generation UI, settings recovery, and RoutineSuggestion handoff to the editor. |
| [SuggestionFlow.swift](../Setory/Features/AI/SuggestionFlow.swift) | Observable generation controller and testable fetch/build/call/resolve operation. |

## Setory/Features/Catalog

| File | Responsibility |
| --- | --- |
| [ExerciseDetailView.swift](../Setory/Features/Catalog/ExerciseDetailView.swift) | Catalog detail, media, instructions, history, related exercises, and in-place edit mode. |
| [ExerciseEditForm.swift](../Setory/Features/Catalog/ExerciseEditForm.swift) | Editable exercise fields, normalization comparison, no-op detection, and save through ExerciseStore. |
| [ExerciseFilterBar.swift](../Setory/Features/Catalog/ExerciseFilterBar.swift) | UI controls for primary-muscle and equipment selection. |
| [ExerciseFilters.swift](../Setory/Features/Catalog/ExerciseFilters.swift) | Value-state filter pipeline combining muscle, equipment, and localized/canonical search. |
| [ExerciseLibraryView.swift](../Setory/Features/Catalog/ExerciseLibraryView.swift) | Exercises-tab navigation and shared filtered-list integration. |
| [ExerciseMultiPicker.swift](../Setory/Features/Catalog/ExerciseMultiPicker.swift) | Multi-selection picker returning exercises in localized-name order. |
| [ExercisePickerSheet.swift](../Setory/Features/Catalog/ExercisePickerSheet.swift) | Single-exercise picker used by daily logging. |
| [FilteredExerciseList.swift](../Setory/Features/Catalog/FilteredExerciseList.swift) | Shared searchable/filterable list shell, localized ordering, and no-results state. |

## Setory/Features/Log

| File | Responsibility |
| --- | --- |
| [DayPlanSection.swift](../Setory/Features/Log/DayPlanSection.swift) | Checklist rows with progress, last saved-set reference, logging callback, and media callback. |
| [DaySeriesSection.swift](../Setory/Features/Log/DaySeriesSection.swift) | Saved/unsaved logging sections, draft deletion, empty guidance, and entry actions. |
| [LogView.swift](../Setory/Features/Log/LogView.swift) | Selected-day drafts/plans, logging and template sheets, plan replacement, and Finish Day. |
| [MonthCalendarView.swift](../Setory/Features/Log/MonthCalendarView.swift) | Month navigation and accessible date grid with selected/today/saved markers. |
| [SeriesRow.swift](../Setory/Features/Log/SeriesRow.swift) | Shared logging row presentation for recorded effort and exercise media access. |
| [SetEntrySheet.swift](../Setory/Features/Log/SetEntrySheet.swift) | Category-specific input, strength/cardio validation, and single-draft confirmation. |
| [TemplateApplyPicker.swift](../Setory/Features/Log/TemplateApplyPicker.swift) | Lists templates and returns a chosen plan source to Log. |

## Setory/Features/Progress

| File | Responsibility |
| --- | --- |
| [ExerciseProgressionView.swift](../Setory/Features/Progress/ExerciseProgressionView.swift) | Per-exercise metric charts, best performance, and record presentation. |
| [ProgressTabView.swift](../Setory/Features/Progress/ProgressTabView.swift) | Overview chart, week/month totals, muscle balance, and performed-exercise search/navigation. |

## Setory/Features/Routines

| File | Responsibility |
| --- | --- |
| [RoutineDetailView.swift](../Setory/Features/Routines/RoutineDetailView.swift) | Read-only saved session display and Save as template entry. |
| [RoutineListView.swift](../Setory/Features/Routines/RoutineListView.swift) | Template/history sections, template management, AI entry points, and suggestion-to-editor handoff. |
| [TemplateEditForm.swift](../Setory/Features/Routines/TemplateEditForm.swift) | Unified create/edit/prefill editor with targets, ordering, naming, photo matching, and save. |

## Setory/Features/Settings

| File | Responsibility |
| --- | --- |
| [AboutView.swift](../Setory/Features/Settings/AboutView.swift) | Dataset license and exercise-media attribution screen. |

## Setory/Media

| File | Responsibility |
| --- | --- |
| [ExerciseMediaStore.swift](../Setory/Media/ExerciseMediaStore.swift) | Bundled thumbnails, pinned CDN URLs, disk GIF cache, and media environment dependency. |

## Setory/Persistence

| File | Responsibility |
| --- | --- |
| [CatalogSeeder.swift](../Setory/Persistence/CatalogSeeder.swift) | Version-gated catalog inserts/backfills and pristine restoration for tests. |
| [ExerciseCatalog.swift](../Setory/Persistence/ExerciseCatalog.swift) | Decodable bundled-catalog and exercise payload structures. |
| [ExerciseStore.swift](../Setory/Persistence/ExerciseStore.swift) | Persists normalized exercise edits and marks records user-modified. |
| [PersistenceStore.swift](../Setory/Persistence/PersistenceStore.swift) | Common injectable commit and rollback/rethrow policy. |
| [TemplateStore.swift](../Setory/Persistence/TemplateStore.swift) | Creates, updates, duplicates, and deletes templates through the common commit policy. |
| [WorkoutStore.swift](../Setory/Persistence/WorkoutStore.swift) | Converts daily drafts to a saved session with ordered series. |

## Setory/TestSupport

| File | Responsibility |
| --- | --- |
| [InMemoryAPIKeyStore.swift](../Setory/TestSupport/InMemoryAPIKeyStore.swift) | Debug key-store substitute for tests and previews. |
| [LaunchOptions.swift](../Setory/TestSupport/LaunchOptions.swift) | Central parser for UI-test launch arguments. |
| [PhotoMatchFixture.swift](../Setory/TestSupport/PhotoMatchFixture.swift) | Deterministic test photo for matching without camera/library interaction. |
| [StubPhotoMatchService.swift](../Setory/TestSupport/StubPhotoMatchService.swift) | Debug photo-match outcomes and optional delays. |
| [StubSuggestionService.swift](../Setory/TestSupport/StubSuggestionService.swift) | Debug suggestion outcomes and optional delays. |
| [TestOverrides.swift](../Setory/TestSupport/TestOverrides.swift) | Debug substitutions with inert production accessors. |
| [UITestReset.swift](../Setory/TestSupport/UITestReset.swift) | Clears workout/template data and restores edited catalog records for isolated UI tests. |
| [UITestSeeding.swift](../Setory/TestSupport/UITestSeeding.swift) | Known workout history used by deterministic UI scenarios. |

## Supporting files and directories

| Path | Responsibility |
| --- | --- |
| [Setory.xcodeproj](../Setory.xcodeproj) | Target configuration, build settings, resources, and synchronized source groups |
| [Setory/Localizable.xcstrings](../Setory/Localizable.xcstrings) | User-interface string catalog |
| [Setory/Assets.xcassets](../Setory/Assets.xcassets) | App icon and asset-catalog colors/images |
| [Setory/Resources](../Setory/Resources) | Bundled exercise JSON and JPEG thumbnails |
| [SetoryTests](../SetoryTests) | Unit tests and golden JSON request fixtures; see the development guide coverage map |
| [SetoryUITests](../SetoryUITests) | End-to-end and visual UI suites; ScrollToElement.swift is a shared scrolling helper |
| [scripts/uitest.sh](../scripts/uitest.sh) | Simulator boot and parallel UI-test runner |
| [tools/catalog](../tools/catalog) | Dataset transformer, curated name translations, and catalog tooling guide |
| [openspec](../openspec) | Workflow configuration and change design/spec/task history |
| [CLAUDE.md](../CLAUDE.md) | Repository development conventions and test-environment notes |
| [docs](README.md) | Application and contributor documentation |
