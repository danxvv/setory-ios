# Tasks — Replace Exercise Catalog with Gym Visual Dataset

## 1. Dataset transform tooling (offline)

- [x] 1.1 Create `tools/catalog/transform.py`: download/read the dataset at a pinned commit SHA; emit `Setory/Resources/exercise-catalog.json` with `gv`-prefixed ids, cleaned names (mojibake, casing), category mapping (`body_part == cardio` → `cardio`, else `strength`), muscle taxonomy mapping onto the 16 `Muscle` raw values, equipment raw value, media file names, en/es summary and instruction steps, and a catalog version stamp
- [x] 1.2 Author `tools/catalog/legacy-mapping.json`: hand-reviewed map of all 40 legacy ids → dataset ids (38 mapped; `face-pull`, `rowing-machine` marked unmappable), and copy it into app resources for the migrator
- [x] 1.3 Run the transform; copy the 1,324 thumbnails into `Setory/Resources/ExerciseThumbnails/` (added to Xcode as a folder reference, files named by exercise id); record the pinned SHA and jsDelivr base URL in the transform README
- [x] 1.4 Spot-check transform output: record counts, muscle raw values all valid, en/es content non-empty, media file names match bundled thumbnails

## 2. Model and catalog source

- [x] 2.1 Extend `Exercise` with `equipmentRaw`, media reference (media file name or nil), and per-locale summary/instruction-steps storage; update content resolution to user-modified → per-locale → English; make `localizedName` return the stored name
- [x] 2.2 Add `Equipment` enum (28 raw values) with localized display names in `Localizable.xcstrings` (en + es)
- [x] 2.3 Update `CatalogExercise` and `BundledCatalogSource` for the new payload shape (equipment, media, per-locale content, catalog version); point them at `exercise-catalog.json`
- [x] 2.4 Delete `ExerciseNames.xcstrings` and `ExerciseContent.xcstrings` and remove their lookup code paths; delete legacy `Resources/exercises.json`

## 3. Migration and seeding

- [x] 3.1 Implement the legacy migrator: version/flag-gated, remaps mapped legacy ids in place, converts referenced unmapped legacy exercises to user-space (`isCustom`), deletes unreferenced unmapped ones; runs before seeding
- [x] 3.2 Add version-gated seeding to `CatalogSeeder`: parse and seed/align only when the stored catalog version differs from the bundled one
- [x] 3.3 Unit tests: migration permutations (mapped with history, mapped user-modified, unmapped with history, unmapped unreferenced, second run is a no-op), idempotent reseed at 1,324, version gate skips parsing
- [x] 3.4 Verify the `-uitest-reset` / `-uitest-seed` launch paths still produce a deterministic store with the new catalog

## 4. Media layer

- [x] 4.1 Implement `ExerciseMediaStore`: bundle thumbnail lookup by id; GIF disk cache (Caches directory, keyed by id); on-demand fetch from the pinned jsDelivr URL; async API returning cached-data/downloading/unavailable states
- [x] 4.2 Implement dependency-free `AnimatedGIFView` (`UIViewRepresentable` + ImageIO `CGAnimateImageDataWithBlock`)
- [x] 4.3 Thumbnail view component with category-icon fallback for exercises without media
- [x] 4.4 Unit tests for media store cache behavior (hit, miss→store, fetch failure surfaces the degraded state)

## 5. Exercise selection and library UI

- [x] 5.1 Build the shared searchable exercise picker sheet (search + muscle/equipment filters + thumbnail rows); replace the `Menu` picker in `ContentView`
- [x] 5.2 Rework `ExerciseMultiPicker` (template editor) on the shared component, preserving multi-select and existing accessibility identifiers where feasible
- [x] 5.3 Add muscle and equipment filters and thumbnail rows to `ExerciseLibraryView`; verify scroll performance with 1,324 rows on device
- [x] 5.4 Update `ExerciseDetailView`: media section (animated demo, thumbnail fallback with retry, attribution footer) above descriptive content; equipment label; per-locale content rendering
- [x] 5.5 Add About/licenses surface (MIT + Gym visual NOTICE) reachable from settings
- [x] 5.6 Update UI tests for the new picker interactions (replacing Menu-based flows) and library filters

## 6. AI payload capping

- [x] 6.1 Implement catalog-subset selection in `SuggestionPromptBuilder`: recent-history exercises + goal-relevant muscles + stratified sample, deduplicated, fixed cap; include equipment in payload lines; build the response-schema id enum from the subset
- [x] 6.2 Unit tests: subset bounded at full catalog size, recent exercises always included, goal keywords pull matching muscles, empty-history sampling still valid
- [x] 6.3 Verify `SuggestionResponseParser` behavior is unchanged (validates against the full local store) and stub service fixtures use new catalog ids

## 7. Localization and polish

- [x] 7.1 Add new UI strings (filters, retry, attribution, About) to `Localizable.xcstrings` with Spanish translations; audit for completeness
- [x] 7.2 Manual pass on a Spanish device/simulator: library, picker, detail (Spanish instructions from per-locale content), AI suggestion flow
- [x] 7.3 Full test suite run + fresh-install and upgrade-install (legacy store with logged history) smoke tests
