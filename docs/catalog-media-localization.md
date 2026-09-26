# Catalog, media, and localization

[Documentation index](README.md)

## Bundled catalog

[exercise-catalog.json](../Setory/Resources/exercise-catalog.json) contains 1,324 exercises imported into SwiftData. [ExerciseCatalog.swift](../Setory/Persistence/ExerciseCatalog.swift) defines its decoding types. Stable exercise IDs use the `gv` prefix, such as `gv0025`.

[CatalogSeeder](../Setory/Persistence/CatalogSeeder.swift) currently declares bundled version 2. On launch it skips loading the JSON when the stored version matches and at least one exercise exists. Otherwise it reads the catalog and:

1. Inserts missing exercise IDs.
2. Aligns fields on existing, non-user-modified exercises.
3. Leaves user-modified exercises intact.
4. Saves when rows were inserted or changed, then records the seed version after success.

This is an upsert/backfill pass, not an exact mirror: it does not generally remove old IDs missing from a newer catalog. The separate pristine-restore function serves test resets and may delete modified exercises that have no catalog counterpart.

## Content generation

[tools/catalog/transform.py](../tools/catalog/transform.py) builds the checked-in JSON and 180×180 JPEG thumbnails from a pinned exercises dataset. [name-translations.json](../tools/catalog/name-translations.json) supplies curated Spanish names; description and instruction translations come from the dataset. The transformer rejects missing required content/media/translations and unmapped taxonomy values.

The pinned dataset revision is `118e4bd6b14da6df0e36605d7169b65db18389a4`. When changing catalog content, keep the transformer's `CATALOG_VERSION`, JSON `version`, and `CatalogSeeder.bundledCatalogVersion` aligned. When upgrading the media source, align the transformer's `PINNED_COMMIT` and `ExerciseMediaStore.datasetCommit`, and add Spanish names for new IDs.

[The catalog tooling guide](../tools/catalog/README.md) provides its input/output workflow. Its older `Setory/Services/ExerciseMediaStore.swift` reference has moved to [Setory/Media/ExerciseMediaStore.swift](../Setory/Media/ExerciseMediaStore.swift).

## Two localization layers

| Layer | Source | Behavior |
| --- | --- | --- |
| UI labels, enum labels, messages | [Localizable.xcstrings](../Setory/Localizable.xcstrings) and localized string calls | English/Spanish UI text follows platform localization |
| Exercise names, descriptions, instructions | Translation dictionaries on `Exercise`, seeded from JSON | Explicit language-code methods resolve translated content with stored-text fallback |

`Exercise.localizedName(languageCode:)` falls back when a translation is missing or empty. Instructions similarly fall back for missing/empty translated arrays. Summary falls back when its translation key is absent. `isUserModified` bypasses translation lookup for all three content fields.

[ExerciseDisplay.swift](../Setory/DesignSystem/ExerciseDisplay.swift) supplies current-language convenience properties, localized sorting/search, and localized session exercise names. Persisted entity methods accept explicit language codes so tests need not depend on the simulator's language.

Search checks both the localized and stored name, so an unmodified Spanish-display exercise can still be found by its English catalog name. Filtering uses stable raw taxonomy values. Template names are saved user content and do not automatically translate after a locale change.

## Media delivery

`ExerciseMediaStore.thumbnail` loads bundled `<exercise-id>.jpg` images. GIF filenames come from catalog metadata. A GIF load first checks `Caches/ExerciseGIFs/<exercise-id>.gif`; otherwise it downloads from jsDelivr at the pinned dataset revision. A successful response must have HTTP 200 and nonempty data. Cache directory creation and writes are best effort, so a cache write failure does not discard downloaded bytes.

`ExerciseMediaView` starts loading when shown, displays a thumbnail and loading indicator until GIF bytes arrive, and falls back to thumbnail plus Retry on failure. `AnimatedGIFView` bridges ImageIO animation into a UIKit image view and stops old animation callbacks on data changes or teardown. Routine rows open the same media through `RoutineMediaSheet`.

There is no built-in cache expiry, size limit, or revision namespace: cache files are keyed only by exercise ID. A dataset/media upgrade should consider stale cached animations. The operating system may also reclaim cache files.

## Attribution

The app's About screen distinguishes dataset/instruction text from Gym visual media and includes the dataset MIT license and media attribution. The shared demonstration view displays `ExerciseMediaStore.attribution`. Preserve the existing attribution when modifying or reusing media surfaces; see [AboutView.swift](../Setory/Features/Settings/AboutView.swift) for the project's shipped wording.
