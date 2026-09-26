## 1. Catalog source and model

- [x] 1.1 Add `localizedNames: [String: String]` to `CatalogExercise` in `Setory/Services/ExerciseCatalogSource.swift` — stored property, init parameter defaulting to `[:]`, and `decodeIfPresent(...) ?? [:]` in the custom decoder alongside the existing localization fields
- [x] 1.2 Add `nameTranslations: [String: String] = [:]` to `Exercise` in `Setory/Models/Exercise.swift` (defaulted for lightweight SwiftData migration) plus the matching init parameter, mirroring `summaryTranslations`
- [x] 1.3 Replace the `localizedName` stub with the resolved accessor: `localizedName(languageCode:)` returning stored name verbatim when `isUserModified`, the non-empty translation for the language when present, canonical `name` otherwise; keep `var localizedName` delegating through `Self.contentLanguageCode`. Correct the now-false "names are English-only by design" doc comment
- [x] 1.4 Add `Exercise.matchesSearch(_:)` — true for empty text, otherwise `localizedStandardContains` against the resolved name or the canonical `name`

## 2. Seeding and catalog version

- [x] 2.1 Carry `entry.localizedNames` into the `Exercise(...)` insert in `CatalogSeeder.seed` and add the `nameTranslations` comparison to `align(_:with:)` in `Setory/Services/CatalogSeeder.swift`
- [x] 2.2 Bump `CatalogSeeder.bundledCatalogVersion` to 2, `"version"` in `Setory/Resources/exercise-catalog.json` to 2, and `CATALOG_VERSION` in `tools/catalog/transform.py` to 2

## 3. UI wiring

- [x] 3.1 Switch the search predicate in `ExerciseFilters.apply(to:searchText:)` (`Setory/Views/ExerciseFilterBar.swift`) to `matchesSearch`, covering the library and both exercise pickers
- [x] 3.2 Switch `filteredExercises` in `Setory/Views/ProgressTabView.swift` to `matchesSearch` and update its "match on the localized name" comment
- [x] 3.3 Audit the remaining `localizedName` call sites (detail, logging rows, routine summaries, set entry, media sheets, template form, photo-match rows) — confirm each still reads the accessor and needs no edit; note any that read `.name` where they should read the resolved name

## 4. Keep machine-facing payloads canonical

- [x] 4.1 Add a comment at `PhotoMatchRequestBuilder.payload` (`Setory/Services/PhotoMatchRequestBuilder.swift`) stating the catalog listing sends canonical English `name` deliberately, never `localizedName`, so the listing is identical in every language
- [x] 4.2 Verify no other outbound payload builder (`SuggestionPromptBuilder`, `PhotoMatchRequestBuilder`) reads a language-resolved value

## 5. Catalog tooling

- [x] 5.1 Extract the 1,324 `localizedNames` maps from `Setory/Resources/exercise-catalog.json` into `tools/catalog/name-translations.json`, keyed by exercise id
- [x] 5.2 Load that sidecar in `tools/catalog/transform.py`, emit `localizedNames` per entry, and append a problem (fail-loudly, like the existing unmapped-taxonomy checks) for any emitted exercise with no non-empty Spanish name
- [x] 5.3 Document the sidecar in `tools/catalog/README.md` — what it is, that it is hand-curated and checked in, and that it must be extended when a dataset upgrade introduces new exercise ids

## 6. Tests

- [x] 6.1 `SetoryTests/ExerciseCatalogSourceTests.swift` — assert `localizedNames` decodes when present and defaults to empty when the field is absent from the payload
- [x] 6.2 `SetoryTests/ExerciseOverrideTests.swift` — replace `displayNameIsAlwaysTheStoredName` with per-language resolution coverage: `es` returns the translation, `en` and `fr` fall back to canonical, a user-modified exercise returns its stored name in every language, an exercise with no translations returns its stored name, and an empty-string translation falls back. Use the explicit `languageCode:` variant so the assertions hold under the simulator's Spanish default
- [x] 6.3 `SetoryTests/CatalogSeederTests.swift` — extend the fixture with `localizedNames`, assert a fresh seed stores `nameTranslations`, that `align` backfills them onto a pre-existing row while leaving a user-modified row untouched, and that `restorePristineCatalog` restores them
- [x] 6.4 `SetoryTests/LocalizationTests.swift` — assert every bundled catalog entry has a non-empty `localizedNames["es"]`; update the file's header comment that currently claims names are English-only
- [x] 6.5 New search coverage: a Spanish-only query matches via the translation, a canonical English query matches the same exercise, and both hold with a muscle/equipment filter applied
- [x] 6.6 `SetoryTests/PhotoMatchRequestBuilderTests.swift` — assert the catalog listing carries the canonical English name for an exercise that has a Spanish translation

## 7. Verification

- [x] 7.1 Run the unit suite: `xcodebuild test -project Setory.xcodeproj -scheme Setory -destination "platform=iOS Simulator,name=iPhone 17 Pro" -derivedDataPath /tmp/setory-deriveddata -only-testing:SetoryTests`
- [x] 7.2 Run `scripts/uitest.sh` — the suite pins English, so no on-screen literal should change; investigate any diff rather than updating the expected string
- [x] 7.3 Launch the app in Spanish (`-AppleLanguages "(es)" -AppleLocale es_ES`) on a store seeded under the previous catalog version and confirm the reseed lands: library rows, pickers, detail title, and progression list all show Spanish names, and a user-edited exercise still shows its own name
- [x] 7.4 Re-run `python3 tools/catalog/transform.py <dataset-dir>` against the pinned dataset extract and confirm the emitted catalog still contains `localizedNames` for all 1,324 entries (guards decision 6 against regressing)
