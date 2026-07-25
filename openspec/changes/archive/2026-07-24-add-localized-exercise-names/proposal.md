## Why

The bundled catalog now ships a `localizedNames` map on every one of its 1,324 exercises (`{"es": "Press de Banca con Barra"}` alongside the canonical English `name`), but the app ignores it: `Exercise.localizedName` is hardcoded to return the stored English name, and the field never reaches the store. A Spanish user sees a fully Spanish UI with Spanish descriptions and Spanish instruction steps — and English exercise titles on every screen. Exercise names are the most-read text in the app (library rows, pickers, logging rows, routine summaries, progress charts), so this is the single largest remaining gap in Spanish coverage.

## What Changes

- Decode `localizedNames` from the catalog JSON into `CatalogExercise`, leniently (absent → empty map), matching how `localizedSummaries` / `localizedInstructions` already decode.
- Persist name translations on `Exercise` as a new `nameTranslations: [String: String]` property (defaulted for lightweight SwiftData migration) and have the seeder insert and align it like the other translation tables.
- Make `Exercise.localizedName` resolve per language with the same three-step order already used for descriptions and instructions: user-modified stored name verbatim → current language's translation → canonical English name. Every existing call site (library, pickers, detail, logging, routines, progress, photo match) picks the change up unchanged.
- Extend search so a query matches either the localized name or the canonical English name. Spanish users keep finding "Press de Banca"; users who know the English dataset names (or paste them from an AI result) keep finding "Bench Press". Sorting stays on the localized name so the Spanish list reads alphabetically in Spanish.
- Keep every machine-facing use of the name canonical English: the exercise catalog listing sent to OpenRouter for photo matching must keep sending `name`, not `localizedName`, so the model matches against dataset vocabulary regardless of device language.
- Bump the catalog version (JSON `version`, `CatalogSeeder.bundledCatalogVersion`, `CATALOG_VERSION` in `transform.py`) so already-installed stores reseed once and pick up the name table.
- Preserve the name translations in the catalog pipeline: `transform.py` does not produce `localizedNames`, so re-running it today would silently delete them. Extract the translations into a checked-in sidecar the script merges in, and fail loudly when an exercise has no Spanish name.
- Retire the "exercise names are English-only by design" carve-out in the localization audit and replace it with a completeness test that requires a non-empty Spanish name on every catalog entry.

No breaking changes: English devices, custom exercises, and user-modified exercises all behave exactly as they do today.

## Capabilities

### New Capabilities

None. This extends existing catalog and localization behavior.

### Modified Capabilities

- `exercise-catalog`: catalog entries and seeded exercises gain per-locale display names; the display-name resolution order (user-modified verbatim → current language → canonical English) becomes part of the catalog contract, and the catalog-source entry shape (also the future REST payload contract) gains the name-translation field.
- `localization`: exercise display names are no longer exempt from Spanish coverage — every catalog exercise must resolve a Spanish name, audited the same way descriptions and instructions are.
- `exercise-library`: search matches the localized display name **or** the canonical English name, so both vocabularies find the same exercise; sorting remains on the localized name.
- `photo-exercise-match`: the catalog listing sent to OpenRouter is pinned to canonical English names (locale-independent), while match results continue to display the localized name.

## Impact

- **Models**: `gymapp/Models/Exercise.swift` — new `nameTranslations` property (defaulted, lightweight migration), `localizedName` becomes language-resolved with a `languageCode:` variant.
- **Services**: `gymapp/Services/ExerciseCatalogSource.swift` (decode `localizedNames`), `gymapp/Services/CatalogSeeder.swift` (insert, align, version bump), `gymapp/Services/PhotoMatchRequestBuilder.swift` (assert canonical name stays).
- **Views**: `gymapp/Views/ExerciseFilterBar.swift` (search predicate); all other `localizedName` call sites are unchanged.
- **Data & tooling**: `gymapp/Resources/exercise-catalog.json` (version bump), `tools/catalog/transform.py` + new name-translations sidecar + `tools/catalog/README.md`.
- **Tests**: `ExerciseOverrideTests` (name resolution + override), `ExerciseCatalogSourceTests` (lenient decode), `CatalogSeederTests` (seed/align/restore), `LocalizationTests` (Spanish-name completeness); UI tests continue to run pinned to English, where names are unchanged.
- **No** network, storage-location, or privacy changes; SwiftData migration is additive with a default value.
