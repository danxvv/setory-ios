## Context

The bundled catalog (`gymapp/Resources/exercise-catalog.json`, 1,324 entries, `version: 1`) already carries `localizedSummaries` and `localizedInstructions`; the working tree now adds a third per-entry map:

```json
{"id":"gv0001","name":"3/4 Sit-Up", ... ,"localizedNames":{"es":"Sit-Up 3/4"}}
```

Verified against the file: all 1,324 entries have a `localizedNames.es` value, none empty, and `es` is the only language key. Eight Spanish strings collide across different ids (e.g. two entries both named "Remo Inclinado con Barra") — the same kind of near-duplicate the English dataset already contains.

The app currently drops the field on the floor. `CatalogExercise` ([ExerciseCatalogSource.swift:26](gymapp/Services/ExerciseCatalogSource.swift:26)) decodes only the two content maps, `Exercise` stores `summaryTranslations` / `instructionTranslations` ([Exercise.swift:40](gymapp/Models/Exercise.swift:40)), and `Exercise.localizedName` is a stub that returns the stored name with a comment saying the dataset ships no translated names ([Exercise.swift:53](gymapp/Models/Exercise.swift:53)). That comment is now false.

The good news: ~25 call sites across views and models already read `exercise.localizedName` rather than `exercise.name`. The indirection was built for exactly this. Making the accessor honest is the whole UI change.

Constraints from the codebase:
- SwiftData store already exists on devices, so a new `Exercise` property must be defaulted for lightweight migration (same pattern as the two existing translation tables).
- `CatalogSeeder` is version-gated: without a version bump, installed apps never re-parse the JSON and never pick up the new field.
- Unit tests inherit the simulator's device language (Spanish on this machine), so anything asserting on the language-resolved accessor must go through the explicit `languageCode:` variant.
- UI tests pin English (`-AppleLanguages "(en)"`), where names are unchanged — the existing literal-name assertions stay valid.

## Goals / Non-Goals

**Goals:**
- Spanish devices show Spanish exercise names everywhere `localizedName` is already read: library, pickers, detail, logging rows, routine summaries, progress list and charts, photo-match results.
- Same three-step resolution the rest of the catalog content uses, so `isUserModified` keeps meaning one thing.
- Search finds an exercise by its Spanish name *or* its canonical English name.
- Everything machine-facing (ids, muscle raws, the OpenRouter photo-match catalog listing) stays byte-identical across languages.
- The catalog pipeline can be re-run without silently deleting the translations.

**Non-Goals:**
- New languages. The map is keyed by language code, so adding one is data, not code.
- Translating user-created or user-edited exercise names — an edit still freezes the exercise to its stored text.
- Re-translating the descriptions and instructions, which already ship in Spanish.
- Changing what the AI suggestion flow sends (it sends ids and muscle metadata, no names).
- Deduplicating the eight colliding Spanish names.

## Decisions

### 1. Mirror the existing translation-table pattern rather than inventing a name-specific mechanism

`Exercise` gains `var nameTranslations: [String: String] = [:]`, `CatalogExercise` gains `let localizedNames: [String: String]` decoded with `decodeIfPresent(...) ?? [:]`, and `CatalogSeeder` carries it in both the insert branch and `align(_:with:)`.

`localizedName` becomes:

```swift
var localizedName: String { localizedName(languageCode: Self.contentLanguageCode) }

func localizedName(languageCode: String) -> String {
    guard !isUserModified else { return name }
    if let translated = nameTranslations[languageCode], !translated.isEmpty { return translated }
    return name
}
```

The non-empty guard matters here in a way it doesn't for summaries: a blank name would render an empty row, so an empty-string translation falls back rather than displaying.

*Alternative rejected:* resolving names through `Localizable.xcstrings` keyed by English name. That would put 1,324 catalog rows into the UI string catalog, break on the eight duplicate names, and split catalog content across two storage mechanisms.

### 2. Search matches resolved name OR canonical English name, via one shared model helper

Two independent search predicates exist today — [ExerciseFilterBar.swift:31](gymapp/Views/ExerciseFilterBar.swift:31) (library, both pickers) and [ProgressTabView.swift:169](gymapp/Views/ProgressTabView.swift:169) (progression list). Both get replaced by a single `Exercise.matchesSearch(_:)` so they can't drift:

```swift
func matchesSearch(_ text: String) -> Bool {
    text.isEmpty
        || localizedName.localizedStandardContains(text)
        || name.localizedStandardContains(text)
}
```

`localizedStandardContains` is already case- and diacritic-insensitive, which is what the spec requires. Testing the canonical name as well is a deliberate widening: the dataset vocabulary is English, users transcribe English names off gym equipment, and AI/photo-match results are reasoned about in English. The cost is a second substring scan over ≤1,324 short strings per keystroke — the same order of work the list already does to sort.

*Alternative rejected:* searching every value in `nameTranslations`. On a two-language catalog that is identical to the above for `es` and would surprise an English user by matching Spanish text they can't see.

### 3. Sort by resolved name, filter by raw values

Sorting stays `localizedName.localizedStandardCompare` (already the case at all five sort sites), so a Spanish list reads alphabetically in Spanish. Muscle/equipment filtering already operates on raw values and is untouched, so filtered result *sets* stay language-independent while their *order* localizes.

### 4. Pin the OpenRouter photo-match listing to canonical names — explicitly

[PhotoMatchRequestBuilder.swift:79](gymapp/Services/PhotoMatchRequestBuilder.swift:79) already sends `$0.name`, so today this is correct by accident. Once `localizedName` becomes language-dependent, a well-meaning "localize this too" edit would start sending Spanish names to a model reasoning over an English dataset, degrading matches only for Spanish users — a bug that would never show up in an English test run. This gets a comment at the call site and a regression test asserting the payload carries the canonical name even when a Spanish translation exists.

### 5. Version bump to 2, in all three places

`version` in the JSON, `CATALOG_VERSION` in [transform.py](tools/catalog/transform.py), and `CatalogSeeder.bundledCatalogVersion` ([CatalogSeeder.swift:18](gymapp/Services/CatalogSeeder.swift:18)) all move 1 → 2. Without it, `seedIfNeeded` short-circuits and no existing install ever gains the name table. `align(_:with:)` then backfills `nameTranslations` on every non-user-modified row on next launch; user-modified rows are skipped by the existing `guard`.

### 6. Preserve the translations in the transform pipeline via a checked-in sidecar

`transform.py` builds each entry from the dataset and would re-emit the catalog *without* `localizedNames` — a silent data loss on the next dataset upgrade. Fix: extract the current map to `tools/catalog/name-translations.json` (`{"gv0001": {"es": "Sit-Up 3/4"}, ...}`), have the script merge it in by id, and add it to the script's existing fail-loudly problem list when an emitted exercise has no Spanish name. This matches how `legacy-mapping.json` already lives beside the script as hand-curated data.

*Alternative rejected:* generating the sidecar from the JSON at build time. That inverts the source of truth — the JSON becomes the input to producing its own input.

### 7. Localization audit gains a name check; the carve-out goes away

`LocalizationTests.everyCatalogExerciseHasSpanishContent` asserts Spanish summaries and instructions and its file comment states names are English-only by design. It gains a Spanish-name assertion, and the stale comments in that file, in `Exercise.localizedName`, and in `ExerciseOverrideTests.displayNameIsAlwaysTheStoredName` are corrected.

## Risks / Trade-offs

- **[Existing installs need a reseed pass over 1,324 rows]** → Already the designed path for catalog changes; `align` mutates only rows whose values actually differ and saves once. One-time cost on the first launch after upgrade.
- **[Broadened search returns more hits per query]** → Intended. A Spanish query matching only the Spanish name and an English query matching only the canonical name are disjoint in practice; overlap is rare and harmless.
- **[Eight duplicate Spanish names]** → Rows stay distinguishable by thumbnail, muscles, and equipment, and everything is keyed by `id`. Not worth hand-editing the dataset; if it proves confusing, the fix is a data patch in the sidecar, not code.
- **[Unit tests asserting `localizedName` would follow the simulator's Spanish language]** → All new assertions use the explicit `localizedName(languageCode:)` variant; the only test on the ambient accessor asserts it agrees with the explicit lookup for `Exercise.contentLanguageCode`, which holds in any language.
- **[UI tests could regress if any run unpinned]** → The suite pins English, where resolution returns the canonical name, so no on-screen string changes. Any UI test that does surface Spanish names must assert on identifiers (`progression-row-<id>`), not literals.
- **[Someone later "fixes" the photo-match payload to use `localizedName`]** → Guarded by the call-site comment and the regression test in decision 4.

## Migration Plan

1. Ship the model property with a default (`[:]`) — SwiftData lightweight migration, no schema version or mapping model needed, identical to how `summaryTranslations` landed.
2. Version bump to 2 makes `seedIfNeeded` re-parse the catalog once per install; `align` backfills the new field and leaves user-modified exercises alone.
3. Rollback: reverting the code leaves an unused `nameTranslations` column and a stored version stamp of 2. Reverting also drops `bundledCatalogVersion` back to 1, which differs from the stored 2 and therefore re-triggers one alignment pass against the reverted catalog — self-healing, no manual step.

## Open Questions

None blocking. Two deferred: whether to translate names for languages beyond Spanish (data-only, no code change), and whether the eight duplicate Spanish names deserve hand-disambiguation in the sidecar.
