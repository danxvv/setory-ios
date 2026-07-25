# Replace Exercise Catalog with Gym Visual Dataset

## Why

The bundled catalog has only 40 hand-curated exercises and no visual guidance, which limits workout variety, the usefulness of the exercise library, and the pool the AI can suggest from. The open `hasaneyldrm/exercises-dataset` (MIT data/text, Gym visual media redistributed with permission) provides 1,324 exercises with equipment metadata, English and Spanish instructions, 180×180 thumbnails, and animated demonstration GIFs — replacing the bespoke catalog eliminates ongoing curation work and adds exercise media the app has never had.

## What Changes

- **BREAKING** — The 40-exercise bundled catalog is removed and replaced by a 1,324-exercise catalog derived from the Gym visual dataset. Catalog exercise ids change (`bench-press` → `gv0025`-style dataset ids). Exercise display names become English-only (the dataset has no translated names); descriptions and instruction steps remain localized (en/es) via per-locale text imported from the dataset.
- **BREAKING** — The exercise-name and exercise-content string catalogs (`ExerciseNames.xcstrings`, `ExerciseContent.xcstrings`) are removed. Localized exercise content resolves from per-locale text stored on the exercise instead of `.xcstrings` lookup.
- A one-time offline transform pipeline (checked-in tooling, pinned to a dataset commit SHA) produces the bundled catalog JSON: languages slimmed to en/es, dataset taxonomy (body part / target / secondary muscles) mapped onto the app's 16-value `Muscle` enum and `strength`/`cardio` categories, names cleaned (mojibake, casing), and a legacy-id mapping table for migration.
- A one-time store migration remaps existing `Exercise` rows to their dataset equivalents **in place** (38 of the 40 legacy ids map directly), preserving all `WorkoutSeries` history and `RoutineTemplateItem` references. The two unmappable legacy exercises (`face-pull`, `rowing-machine`) are kept as user-space (custom) exercises when referenced by history or templates, otherwise deleted.
- `Exercise` (and the catalog source contract) gains equipment metadata, a media reference, and per-locale content storage.
- New exercise media capability: bundled thumbnails (~8.5 MB) shown in lists and pickers; animated demonstration GIFs fetched on demand from a CDN pinned to the dataset commit, cached on disk, rendered dependency-free; Gym visual attribution shown wherever media appears.
- Exercise selection UI is reworked for catalog scale: the logging screen's `Menu` dropdown is replaced by a searchable picker sheet, and the library gains muscle and equipment filters.
- The AI suggestion request no longer embeds the full catalog: the payload is filtered/capped to a relevant subset (the full catalog at 1,324 entries would bloat every request by tens of thousands of tokens).

## Capabilities

### New Capabilities

- `exercise-media`: Exercise thumbnails and animated demonstration GIFs — bundled thumbnail delivery, on-demand GIF download and disk cache, offline degradation, and Gym visual attribution display.

### Modified Capabilities

- `exercise-catalog`: Catalog content is now dataset-derived (1,324 exercises); exercises gain equipment and media metadata and per-locale content; localized display names are no longer resolved via string catalogs (names are English-only, content per-locale from stored text); seeding gains a catalog-version gate; a legacy-store migration requirement is added.
- `exercise-library`: Rows gain thumbnails and equipment context; the list gains muscle and equipment filters to stay navigable at 1,324 entries.
- `exercise-detail`: The detail screen gains a media section (animated demonstration with graceful offline fallback), equipment display, and mandatory media attribution.
- `workout-logging`: Exercise selection changes from a dropdown listing all exercises to a searchable, filterable picker (a `Menu` is unusable at 1,324 entries).
- `ai-routine-suggestions`: The request contract changes from "payload includes the exercise catalog" to "payload includes a bounded, relevance-filtered catalog subset"; validation still constrains results to the local store.
- `localization`: Exercise display names are exempted from the Spanish-translation completeness requirement (English-only names by design); exercise descriptions/instructions resolve from per-locale stored text instead of string catalogs; muscle names and UI strings unchanged.

## Impact

- **Models**: `Exercise` gains `equipmentRaw`, media reference, per-locale content fields; `CatalogExercise` payload contract extended to match. `Muscle` enum unchanged (dataset taxonomy is mapped at transform time).
- **Services**: `ExerciseCatalogSource`, `CatalogSeeder` (version-gated seeding + legacy migration), `SuggestionPromptBuilder` (payload capping), new media store/loader.
- **Views**: `ContentView` (picker rework), `ExerciseLibraryView` (filters, thumbnails), `ExerciseDetailView` (media hero, attribution), `ExerciseMultiPicker` (shared picker component), new About/attribution surface in settings.
- **Resources**: `Resources/exercises.json` replaced by dataset-derived catalog JSON (~3 MB) plus ~1,324 bundled thumbnails (~8.5 MB); `ExerciseNames.xcstrings` and `ExerciseContent.xcstrings` deleted. App size grows ~12 MB.
- **Tooling**: new checked-in transform script + legacy-id mapping table; dataset pinned by commit SHA.
- **Network**: first non-AI network dependency — GIF fetches from a CDN serving the pinned dataset commit. Fully optional: all features work offline except GIF playback, which degrades to the bundled thumbnail.
- **License obligation**: "© Gym visual — https://gymvisual.com/" attribution must remain visible with media; MIT + NOTICE text shipped in an About screen.
- **Existing user data**: preserved via in-place id remap; no logged series or template item is lost. Two legacy exercises may surface as custom exercises.
- **Tests**: seeder/migration unit tests, prompt-builder cap tests, picker UI tests all need updates; catalog-size assumptions (40) break wherever hardcoded.
