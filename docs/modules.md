# Source-file reference

[Documentation index](README.md)

Paths below link to every Swift source in the application target. Directories are organizational modules in one target. For behavior across files, start with [screens](screens.md) and [architecture](architecture.md).

## gymapp/AI/PhotoMatch

| File | Responsibility |
| --- | --- |
| [PhotoExerciseMatchService.swift](../gymapp/AI/PhotoMatch/PhotoExerciseMatchService.swift) | Photo service protocol and OpenRouter builder/transport/parser composition. |
| [PhotoMatchModels.swift](../gymapp/AI/PhotoMatch/PhotoMatchModels.swift) | Photo payload, confidence vocabulary, and structured match results. |
| [PhotoMatchRequestBuilder.swift](../gymapp/AI/PhotoMatch/PhotoMatchRequestBuilder.swift) | Photo limits, hint normalization, muscle filtering, multimodal prompt, and response schema. |
| [PhotoMatchResponseParser.swift](../gymapp/AI/PhotoMatch/PhotoMatchResponseParser.swift) | Filters unknown and duplicate match IDs, allowing valid empty results. |
| [PhotoPreprocessor.swift](../gymapp/AI/PhotoMatch/PhotoPreprocessor.swift) | Image downsizing, JPEG encoding, and inline data URL construction. |

## gymapp/AI/Shared

| File | Responsibility |
| --- | --- |
| [AIEnvironment.swift](../gymapp/AI/Shared/AIEnvironment.swift) | Environment dependency seams for key storage, AI services, and a test photo. |
| [AIError.swift](../gymapp/AI/Shared/AIError.swift) | Shared typed AI errors, localized descriptions, and settings-vs-retry recovery classification. |
| [AIModelPreference.swift](../gymapp/AI/Shared/AIModelPreference.swift) | Default model ID and trimmed UserDefaults override resolution. |
| [APIKeyStore.swift](../gymapp/AI/Shared/APIKeyStore.swift) | APIKeyStoring protocol and Keychain generic-password implementation. |
| [ChatCompletionResponse.swift](../gymapp/AI/Shared/ChatCompletionResponse.swift) | HTTP error mapping, completion-envelope validation, and structured-content JSON decoding. |
| [OpenRouterClient.swift](../gymapp/AI/Shared/OpenRouterClient.swift) | Shared authenticated AI transport, timeout, model resolution, and cancellation translation. |

## gymapp/AI/Suggestion

| File | Responsibility |
| --- | --- |
| [RoutineSuggestionService.swift](../gymapp/AI/Suggestion/RoutineSuggestionService.swift) | Suggestion service protocol and OpenRouter builder/transport/parser composition. |
| [SuggestionModels.swift](../gymapp/AI/Suggestion/SuggestionModels.swift) | Codable suggestion request/history/catalog and response structures. |
| [SuggestionPromptBuilder.swift](../gymapp/AI/Suggestion/SuggestionPromptBuilder.swift) | History summary, bounded catalog selection, goal keyword matching, prompt, schema, and request body. |
| [SuggestionResponseParser.swift](../gymapp/AI/Suggestion/SuggestionResponseParser.swift) | Rejects unusable suggestions, filters IDs, deduplicates items, and clamps set targets. |

## gymapp/App

| File | Responsibility |
| --- | --- |
| [AppModelContainer.swift](../gymapp/App/AppModelContainer.swift) | Defines the five-model schema and constructs the disk store, reset/seed sequence, and startup failure handling. |
| [ExerciseRoute.swift](../gymapp/App/ExerciseRoute.swift) | Shared typed navigation to exercise detail and progression, plus destination registration. |
| [RootTabView.swift](../gymapp/App/RootTabView.swift) | Four root tabs, Routines navigation stack, accent tint, and rounded typography. |
| [gymappApp.swift](../gymapp/App/gymappApp.swift) | Application entry point; constructs and injects persistence, media, credentials, and AI services. |

## gymapp/DesignSystem

| File | Responsibility |
| --- | --- |
| [AnimatedGIFView.swift](../gymapp/DesignSystem/AnimatedGIFView.swift) | ImageIO-to-UIImageView animation bridge with callback generation cancellation. |
| [ExerciseDisplay.swift](../gymapp/DesignSystem/ExerciseDisplay.swift) | Current-language exercise display/search/sorting conveniences and localized session names. |
| [ExerciseMediaView.swift](../gymapp/DesignSystem/ExerciseMediaView.swift) | Demonstration loading, GIF playback, thumbnail fallback, retry, and attribution. |
| [ExerciseRowContent.swift](../gymapp/DesignSystem/ExerciseRowContent.swift) | Reusable exercise-list row content including thumbnail and metadata. |
| [ExerciseThumbnailView.swift](../gymapp/DesignSystem/ExerciseThumbnailView.swift) | Small bundled exercise image with category fallback. |
| [GymTheme.swift](../gymapp/DesignSystem/GymTheme.swift) | Shared colors, card/list styling, primary buttons, icons, and introductory panels. |
| [MuscleChips.swift](../gymapp/DesignSystem/MuscleChips.swift) | Reusable primary/secondary muscle label chips. |
| [NumberBadge.swift](../gymapp/DesignSystem/NumberBadge.swift) | Visual numbering for zero-based ordered rows. |
| [Persisting.swift](../gymapp/DesignSystem/Persisting.swift) | View call-site wrapper that applies assertion-based reporting to thrown persistence errors. |
| [RoutineMediaSheet.swift](../gymapp/DesignSystem/RoutineMediaSheet.swift) | Reusable demonstration sheet and routine-thumbnail action component. |

## gymapp/Domain/Drafts

| File | Responsibility |
| --- | --- |
| [DayPlan.swift](../gymapp/Domain/Drafts/DayPlan.swift) | Stages a template as a temporary checklist, merges duplicate exercises, and counts logged drafts. |
| [DraftSeries.swift](../gymapp/Domain/Drafts/DraftSeries.swift) | Unsaved set values and shared human-readable series summaries. |
| [ExerciseEdit.swift](../gymapp/Domain/Drafts/ExerciseEdit.swift) | Normalizes exercise form values and validates name/primary muscles. |
| [TemplateDraft.swift](../gymapp/Domain/Drafts/TemplateDraft.swift) | Value-state template editing, session conversion, name suggestion access, and item write mapping. |

## gymapp/Domain/Entities

| File | Responsibility |
| --- | --- |
| [Exercise.swift](../gymapp/Domain/Entities/Exercise.swift) | Persisted exercise metadata, stable ID, content translations, and explicit-language lookup/search. |
| [RoutineTemplate.swift](../gymapp/Domain/Entities/RoutineTemplate.swift) | Defines RoutineTemplate and RoutineTemplateItem, ordering, target limits, and derived muscle coverage. |
| [WorkoutSession.swift](../gymapp/Domain/Entities/WorkoutSession.swift) | Defines WorkoutSession and WorkoutSeries, day identity, series ordering, and worked muscles. |

## gymapp/Domain/Stats

| File | Responsibility |
| --- | --- |
| [ExerciseHistoryProvider.swift](../gymapp/Domain/Stats/ExerciseHistoryProvider.swift) | Groups saved exercise history and selects best sets and recent sessions. |
| [MonthGrid.swift](../gymapp/Domain/Stats/MonthGrid.swift) | Calendar month dates, weekday ordering, leading blanks, and adjacent-month calculations. |
| [ProgressStatsProvider.swift](../gymapp/Domain/Stats/ProgressStatsProvider.swift) | Weekly totals, muscle balance, progression values, weighted volume, and record flags. |
| [TemplateNameSuggester.swift](../gymapp/Domain/Stats/TemplateNameSuggester.swift) | Deterministic localized name suggestions from primary-muscle votes and exercise category. |

## gymapp/Domain/Vocabulary

| File | Responsibility |
| --- | --- |
| [Equipment.swift](../gymapp/Domain/Vocabulary/Equipment.swift) | Equipment vocabulary, stable serialized raw values, and localized labels. |
| [ExerciseCategory.swift](../gymapp/Domain/Vocabulary/ExerciseCategory.swift) | Strength/cardio category vocabulary used by catalog data and set entry. |
| [Muscle.swift](../gymapp/Domain/Vocabulary/Muscle.swift) | Muscle vocabulary, stable serialized raw values, and localized labels. |

## gymapp/Features/AI

| File | Responsibility |
| --- | --- |
| [AIFlowScaffold.swift](../gymapp/Features/AI/AIFlowScaffold.swift) | Shared missing-key section, progress/cancel presentation, and AI failure alert helpers. |
| [AISettingsView.swift](../gymapp/Features/AI/AISettingsView.swift) | Key management, model preference, privacy explanation, and About navigation. |
| [CameraCaptureView.swift](../gymapp/Features/AI/CameraCaptureView.swift) | UIKit camera capture bridge returning a UIImage to the photo flow. |
| [PhotoMatchCaptureSection.swift](../gymapp/Features/AI/PhotoMatchCaptureSection.swift) | Photo attachment/removal UI, description and muscle hints, and send/cancel controls. |
| [PhotoMatchFlow.swift](../gymapp/Features/AI/PhotoMatchFlow.swift) | Observable request controller; image preparation, catalog fetch/filter, service call, and ID resolution. |
| [PhotoMatchResultsSection.swift](../gymapp/Features/AI/PhotoMatchResultsSection.swift) | Confidence-labelled selectable matches, empty results, and return-to-capture action. |
| [PhotoMatchSheet.swift](../gymapp/Features/AI/PhotoMatchSheet.swift) | Capture/results sheet orchestration, photo selection, settings, and confirmed exercise callback. |
| [SuggestRoutineSheet.swift](../gymapp/Features/AI/SuggestRoutineSheet.swift) | Goal input, generation UI, settings recovery, and RoutineSuggestion handoff to the editor. |
| [SuggestionFlow.swift](../gymapp/Features/AI/SuggestionFlow.swift) | Observable generation controller and testable fetch/build/call/resolve operation. |

## gymapp/Features/Catalog

| File | Responsibility |
| --- | --- |
| [ExerciseDetailView.swift](../gymapp/Features/Catalog/ExerciseDetailView.swift) | Catalog detail, media, instructions, history, related exercises, and in-place edit mode. |
| [ExerciseEditForm.swift](../gymapp/Features/Catalog/ExerciseEditForm.swift) | Editable exercise fields, normalization comparison, no-op detection, and save through ExerciseStore. |
| [ExerciseFilterBar.swift](../gymapp/Features/Catalog/ExerciseFilterBar.swift) | UI controls for primary-muscle and equipment selection. |
| [ExerciseFilters.swift](../gymapp/Features/Catalog/ExerciseFilters.swift) | Value-state filter pipeline combining muscle, equipment, and localized/canonical search. |
| [ExerciseLibraryView.swift](../gymapp/Features/Catalog/ExerciseLibraryView.swift) | Exercises-tab navigation and shared filtered-list integration. |
| [ExerciseMultiPicker.swift](../gymapp/Features/Catalog/ExerciseMultiPicker.swift) | Multi-selection picker returning exercises in localized-name order. |
| [ExercisePickerSheet.swift](../gymapp/Features/Catalog/ExercisePickerSheet.swift) | Single-exercise picker used by daily logging. |
| [FilteredExerciseList.swift](../gymapp/Features/Catalog/FilteredExerciseList.swift) | Shared searchable/filterable list shell, localized ordering, and no-results state. |

## gymapp/Features/Log

| File | Responsibility |
| --- | --- |
| [DayPlanSection.swift](../gymapp/Features/Log/DayPlanSection.swift) | Checklist rows with progress, last saved-set reference, logging callback, and media callback. |
| [DaySeriesSection.swift](../gymapp/Features/Log/DaySeriesSection.swift) | Saved/unsaved logging sections, draft deletion, empty guidance, and entry actions. |
| [LogView.swift](../gymapp/Features/Log/LogView.swift) | Selected-day drafts/plans, logging and template sheets, plan replacement, and Finish Day. |
| [MonthCalendarView.swift](../gymapp/Features/Log/MonthCalendarView.swift) | Month navigation and accessible date grid with selected/today/saved markers. |
| [SeriesRow.swift](../gymapp/Features/Log/SeriesRow.swift) | Shared logging row presentation for recorded effort and exercise media access. |
| [SetEntrySheet.swift](../gymapp/Features/Log/SetEntrySheet.swift) | Category-specific input, strength/cardio validation, and single-draft confirmation. |
| [TemplateApplyPicker.swift](../gymapp/Features/Log/TemplateApplyPicker.swift) | Lists templates and returns a chosen plan source to Log. |

## gymapp/Features/Progress

| File | Responsibility |
| --- | --- |
| [ExerciseProgressionView.swift](../gymapp/Features/Progress/ExerciseProgressionView.swift) | Per-exercise metric charts, best performance, and record presentation. |
| [ProgressTabView.swift](../gymapp/Features/Progress/ProgressTabView.swift) | Overview chart, week/month totals, muscle balance, and performed-exercise search/navigation. |

## gymapp/Features/Routines

| File | Responsibility |
| --- | --- |
| [RoutineDetailView.swift](../gymapp/Features/Routines/RoutineDetailView.swift) | Read-only saved session display and Save as template entry. |
| [RoutineListView.swift](../gymapp/Features/Routines/RoutineListView.swift) | Template/history sections, template management, AI entry points, and suggestion-to-editor handoff. |
| [TemplateEditForm.swift](../gymapp/Features/Routines/TemplateEditForm.swift) | Unified create/edit/prefill editor with targets, ordering, naming, photo matching, and save. |

## gymapp/Features/Settings

| File | Responsibility |
| --- | --- |
| [AboutView.swift](../gymapp/Features/Settings/AboutView.swift) | Dataset license and exercise-media attribution screen. |

## gymapp/Media

| File | Responsibility |
| --- | --- |
| [ExerciseMediaStore.swift](../gymapp/Media/ExerciseMediaStore.swift) | Bundled thumbnails, pinned CDN URLs, disk GIF cache, and media environment dependency. |

## gymapp/Persistence

| File | Responsibility |
| --- | --- |
| [CatalogSeeder.swift](../gymapp/Persistence/CatalogSeeder.swift) | Version-gated catalog inserts/backfills and pristine restoration for tests. |
| [ExerciseCatalog.swift](../gymapp/Persistence/ExerciseCatalog.swift) | Decodable bundled-catalog and exercise payload structures. |
| [ExerciseStore.swift](../gymapp/Persistence/ExerciseStore.swift) | Persists normalized exercise edits and marks records user-modified. |
| [PersistenceStore.swift](../gymapp/Persistence/PersistenceStore.swift) | Common injectable commit and rollback/rethrow policy. |
| [TemplateStore.swift](../gymapp/Persistence/TemplateStore.swift) | Creates, updates, duplicates, and deletes templates through the common commit policy. |
| [WorkoutStore.swift](../gymapp/Persistence/WorkoutStore.swift) | Converts daily drafts to a saved session with ordered series. |

## gymapp/TestSupport

| File | Responsibility |
| --- | --- |
| [InMemoryAPIKeyStore.swift](../gymapp/TestSupport/InMemoryAPIKeyStore.swift) | Debug key-store substitute for tests and previews. |
| [LaunchOptions.swift](../gymapp/TestSupport/LaunchOptions.swift) | Central parser for UI-test launch arguments. |
| [PhotoMatchFixture.swift](../gymapp/TestSupport/PhotoMatchFixture.swift) | Deterministic test photo for matching without camera/library interaction. |
| [StubPhotoMatchService.swift](../gymapp/TestSupport/StubPhotoMatchService.swift) | Debug photo-match outcomes and optional delays. |
| [StubSuggestionService.swift](../gymapp/TestSupport/StubSuggestionService.swift) | Debug suggestion outcomes and optional delays. |
| [TestOverrides.swift](../gymapp/TestSupport/TestOverrides.swift) | Debug substitutions with inert production accessors. |
| [UITestReset.swift](../gymapp/TestSupport/UITestReset.swift) | Clears workout/template data and restores edited catalog records for isolated UI tests. |
| [UITestSeeding.swift](../gymapp/TestSupport/UITestSeeding.swift) | Known workout history used by deterministic UI scenarios. |

## Supporting files and directories

| Path | Responsibility |
| --- | --- |
| [gymapp.xcodeproj](../gymapp.xcodeproj) | Target configuration, build settings, resources, and synchronized source groups |
| [gymapp/Localizable.xcstrings](../gymapp/Localizable.xcstrings) | User-interface string catalog |
| [gymapp/Assets.xcassets](../gymapp/Assets.xcassets) | App icon and asset-catalog colors/images |
| [gymapp/Resources](../gymapp/Resources) | Bundled exercise JSON and JPEG thumbnails |
| [gymappTests](../gymappTests) | Unit tests and golden JSON request fixtures; see the development guide coverage map |
| [gymappUITests](../gymappUITests) | End-to-end and visual UI suites; ScrollToElement.swift is a shared scrolling helper |
| [scripts/uitest.sh](../scripts/uitest.sh) | Simulator boot and parallel UI-test runner |
| [tools/catalog](../tools/catalog) | Dataset transformer, curated name translations, and catalog tooling guide |
| [openspec](../openspec) | Workflow configuration and change design/spec/task history |
| [CLAUDE.md](../CLAUDE.md) | Repository development conventions and test-environment notes |
| [docs](README.md) | Application and contributor documentation |
