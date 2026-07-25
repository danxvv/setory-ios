# Design — Replace Exercise Catalog with Gym Visual Dataset

## Context

The app seeds a 40-exercise catalog from `gymapp/Resources/exercises.json` through the `ExerciseCatalogSource` protocol → `CatalogSeeder` pipeline into SwiftData. Exercise text localizes at render time from two id-keyed string catalogs (`ExerciseNames.xcstrings`, `ExerciseContent.xcstrings`). There is no media handling anywhere (SF Symbols only), no equipment concept, and the AI suggestion request embeds the entire catalog plus an id-enum response schema.

The source dataset (`github.com/hasaneyldrm/exercises-dataset`) provides 1,324 exercises: one 15 MB JSON (instructions in 9 languages), 8.5 MB of 180×180 JPG thumbnails, and 123 MB of 180×180 animated GIFs (~95 KB each). Data/instruction text is MIT; media is © Gym visual, redistributed with permission at this resolution, attribution string required.

Constraints:
- Zero third-party dependencies (deliberate stance; keep it).
- Existing on-device data (logged `WorkoutSeries`, `RoutineTemplateItem`) references `Exercise` rows by SwiftData relationship — the old catalog cannot simply be deleted.
- Local-first: everything except AI suggestions must work offline today, and must continue to.
- en/es localization; the dataset has en/es instructions but English-only names.

## Goals / Non-Goals

**Goals:**
- Ship the full 1,324-exercise dataset catalog as the app's only catalog.
- Preserve every logged series and template item across the catalog swap.
- Show thumbnails offline everywhere exercises are listed; show demo GIFs in detail with one-time download per exercise.
- Keep the app usable at 34× the catalog size (pickers, library, AI payload).
- Honor the Gym visual attribution requirement.

**Non-Goals:**
- Spanish exercise names (dataset has none; AI-assisted translation is a possible future change).
- The other 6 dataset languages (it/tr/ru/zh/hi/ko) — dropped at transform time to keep the bundle small; re-adding is a transform-flag away.
- A user-facing "create custom exercise" flow (`isCustom` stays reserved; migration may set it on ≤2 orphaned legacy rows).
- Editing equipment metadata in the exercise edit form.
- Offline bulk-download of all GIFs ("download all demos" toggle is a natural fast-follow).
- Re-encoding GIFs to a smaller format (would require re-hosting media).
- Curating out near-duplicate dataset entries ("v. 2", "(female)", pov variants) — search and filters absorb the noise.

## Decisions

### D1 — Offline transform pipeline, checked-in outputs

A Python script in `tools/catalog/` reads the dataset at a **pinned commit SHA** and emits:
- `gymapp/Resources/exercise-catalog.json` (~3 MB): id, cleaned name, category, mapped muscles, equipment, media file names, en/es summary + instruction steps.
- `gymapp/Resources/ExerciseThumbnails/` (blue folder reference): the 1,324 JPGs, named by exercise id.
- `tools/catalog/legacy-mapping.json`: hand-curated 40-row map from legacy ids to dataset ids (38 direct, 2 marked unmappable).

The transform runs offline, once per dataset upgrade; the app never parses the raw 15 MB dataset. Rationale: keeps launch cost low, keeps taxonomy mapping and name cleanup (mojibake like `45в°`, title-casing) out of app code, and makes dataset upgrades an explicit, reviewable diff.
*Alternative rejected:* runtime transform of the raw dataset JSON — 5× parse cost on device and app-side mapping logic for no benefit.

### D2 — Dataset ids prefixed as `gv<id>`

Catalog ids become `gv0025`-style (dataset id `0025`), guaranteeing no collision with legacy slugs or future id schemes and making provenance obvious. Ids remain the stable join key for the store, the AI contract, and media file names.
*Alternative rejected:* slugified names (`barbell-bench-press`) — dataset names contain duplicates and artifacts; slugs would break on upstream renames.

### D3 — Taxonomy mapped onto the existing 16-value `Muscle` enum at transform time

Dataset `target`/`secondary_muscles` values map to existing enum cases (pectorals→chest, delts→shoulders, upper back→back, spine/lower back→lower_back, levator scapulae→traps, serratus anterior→chest, abductors→glutes, adductors→quads, cardiovascular system→full_body). `body_part == cardio` → category `cardio`, else `strength`. The `Muscle` enum, its localized names, and the AI muscle contract stay untouched.
*Alternative rejected:* extending the enum (abductors, adductors, …) — ripples into localization, AI prompt vocabulary, and progress stats for marginal precision.

### D4 — Equipment as a new stored raw string + enum

`Exercise.equipmentRaw: String` plus a new `Equipment` enum (28 dataset values, localized display names in `Localizable.xcstrings`). Used for library/picker filtering and included in the AI catalog payload lines.

### D5 — Per-locale content stored on the model; exercise string catalogs deleted

`Exercise` stores canonical English `summary`/`instructionSteps` (as today) plus Codable-backed per-locale variants (es imported from the dataset). Resolution order for content: user-modified → stored per-locale for current language → English. `localizedName` returns the stored name (English) verbatim; `ExerciseNames.xcstrings` and `ExerciseContent.xcstrings` are deleted.
*Alternative rejected:* generating ~9,000 xcstrings entries — bloats compile time, and the mechanism can't cover names anyway (no translated names exist). The per-locale storage also keeps the door open for the other 6 languages.

### D6 — Migration: in-place id remap, then seed

On first launch after upgrade, before seeding, a one-time migrator (guarded by a stored catalog-version flag):
1. For each existing `Exercise` whose id appears in the bundled legacy mapping: rewrite `id` to the dataset id in place. Relationships from `WorkoutSeries`/`RoutineTemplateItem` are object references, so history survives untouched. Non-user-modified rows get their fields backfilled by the normal seeder alignment; user-modified rows keep their frozen text but still gain the new id (and thus media).
2. Unmappable legacy rows (`face-pull`, `rowing-machine`): if referenced by any series or template item → mark `isCustom = true` and keep (no media, stored text verbatim); else delete.
3. Seed the new catalog (idempotent by id; remapped rows are updated, not duplicated). Seeding is gated by a catalog version stamp so the 3 MB JSON is parsed only when the bundled catalog version changes, not on every launch.

*Alternative rejected:* delete-and-reseed — nulls out `WorkoutSeries.exercise`, destroying history labels.

### D7 — Media delivery: thumbnails bundled, GIFs on-demand from pinned CDN

- Thumbnails ship in the bundle (blue folder), loaded by id — lists and pickers are fully offline.
- GIFs are fetched lazily from `https://cdn.jsdelivr.net/gh/hasaneyldrm/exercises-dataset@<SHA>/videos/<file>.gif` (jsDelivr serves any public GitHub repo; pinning to the SHA makes URLs immutable), cached permanently in the app's caches directory, keyed by exercise id. A new `ExerciseMediaStore` owns both paths.
- Offline/failed fetch degrades to the bundled thumbnail plus a quiet retry affordance — no blocking, no error alerts.

*Alternatives rejected:* bundling GIFs (+123 MB app size); On-Demand Resources (requires App Store hosting, dead in development/sideload installs); self-hosting (infrastructure for a personal app — a fork of the dataset repo is the cheap mitigation if upstream disappears).

### D8 — Dependency-free GIF rendering

A small `UIViewRepresentable` wrapping ImageIO's `CGAnimateImageDataWithBlock` (iOS 13+) plays GIF data into a `UIImageView`. ~40 lines, no SPM package, honors the zero-dependency stance.
*Alternative rejected:* Nuke/SDWebImage — first external dependency for one small view.

### D9 — Picker rework: shared searchable sheet

The logging screen's `Menu` picker (unusable and untestable at 1,324 items; see existing XCUITest Menu quirks) is replaced by a searchable sheet with muscle/equipment filters and thumbnail rows. The same list component backs `ExerciseMultiPicker` (template editor) and the library's filter UI, so filtering/search behavior is implemented once.

### D10 — AI payload capping

`SuggestionPromptBuilder` no longer embeds the whole catalog. It sends a bounded subset (target ~150–250 entries): exercises the user has recently performed, plus exercises matching goal-relevant muscles (when a goal is given), plus a stratified sample across muscle groups/equipment for variety, deduplicated and capped. The response-schema id enum is built from the same subset. Validation (`SuggestionResponseParser`) still checks against the full local store, so a model hallucinating outside the subset is dropped exactly as today.
*Alternative rejected:* sending all 1,324 (≈40–60k tokens per request — slow, costly, worse model focus).

### D11 — Attribution surfaces

"© Gym visual — https://gymvisual.com/" appears as a footer in the exercise detail media section, and a new About/licenses entry (AI Settings screen gains a sibling section) ships the MIT license and NOTICE text. This is a license obligation, not a nicety.

## Risks / Trade-offs

- [Upstream repo deleted → GIF URLs die] → Thumbnails and all data are bundled, so only animations degrade; mitigate by forking the dataset repo and switching the CDN base URL constant to the fork.
- [Legacy mapping errors mislabel history] → The 40-row mapping is hand-reviewed and unit-tested (every legacy id must resolve to an existing dataset id or be explicitly marked unmappable); migration is verified by tests seeding a legacy store first.
- [Migration runs on real user data with no rollback] → Migration is idempotent and version-gated; unit tests cover mapped/unmapped/user-modified/referenced permutations before ship.
- [1,324 rows slow down `@Query` lists] → Thumbnails are 180×180 JPGs (~6 KB) loaded lazily per row; search/filters reduce visible rows; verify scrolling on device before ship.
- [Dataset names are noisy ("v. 2", "(male)")] → Transform cleans encoding artifacts and casing only; variants remain searchable rather than curated away (non-goal).
- [English-only names on Spanish devices] → Accepted product trade-off (gym vocabulary is largely English); instructions remain Spanish. Revisit with AI translation later.
- [Larger AI enum/schema still sizable at ~200 ids] → Cap is tunable in one place; parser guarantees correctness regardless of subset size.
- [App size +~12 MB] → Acceptable; thumbnails dominate and are the product feature.

## Migration Plan

1. Ship transform outputs + code in one release; `CatalogSeeder` version gate triggers migration then reseed on first launch.
2. Rollback = reverting the release; the version gate prevents re-runs, and remapped ids remain valid rows (orphaned from the old catalog JSON but functional), so a downgraded app still shows history.
3. UI tests run against the new catalog via the existing `-uitest-reset` / `-uitest-seed` launch arguments.

## Open Questions

- None blocking. Tunables left to implementation: exact AI subset size (~150–250), GIF cache eviction policy (none vs. LRU — 123 MB worst case is acceptable for caches), whether the picker sheet paginates or relies on search alone.
