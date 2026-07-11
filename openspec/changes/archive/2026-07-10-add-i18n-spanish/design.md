# Design: add-i18n-spanish

## Context

The app has zero localization infrastructure: `knownRegions = (en, Base)`, no `.xcstrings`/`.strings` files, and every user-facing string is a bare literal. However, the project is already primed for modern localization — `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`, `SWIFT_EMIT_LOC_STRINGS = YES` (app target), and `STRING_CATALOG_GENERATE_SYMBOLS = YES` are set, and all targets use synchronized file groups (`PBXFileSystemSynchronizedRootGroup`), so new resource files are picked up without pbxproj membership edits.

Three classes of strings need different treatment:

1. **View-layer literals** (~30 across 6 views): SwiftUI's `Text`/`Label`/`Button`/`.navigationTitle` string literals are already `LocalizedStringKey`, so they extract into a String Catalog automatically at build time.
2. **Model-layer format strings**: `DraftSeries.summary` builds `"N reps"`, `"N min"`, `"N kg"` via plain interpolation (with an existing `"1 reps"` plural bug), and `Muscle.displayName` hardcodes 16 English names. These are plain `String`s and need explicit `String(localized:)` adoption.
3. **Persisted display names**: `CatalogSeeder` inserts 40 exercises into SwiftData with `Exercise.name` as a raw English string (e.g. `"Bench Press"`). Bundle localization cannot reach values stored in the database.

Existing UI tests assert literal English strings ("No routines yet", "10 reps · 40 kg", "Muscles worked", …); unit tests assert stored English names ("Bench Press").

## Goals / Non-Goals

**Goals:**
- Every user-facing string (including accessibility values) resolves through the localization system, with complete Spanish translations and English as the development/fallback language.
- Exercise and muscle display names render localized without a data migration.
- Correct plural forms in both languages (fixes English "1 reps"/"1 min").
- Existing test suites keep passing deterministically regardless of the host simulator's locale.

**Non-Goals:**
- Localizing user-generated content (custom exercise names entered by users stay as typed).
- Languages beyond Spanish; per-region variants (single `es` localization).
- Localizing the AI-suggestion REST contract (external dependency; machine-facing).
- App Store metadata, app display name (`InfoPlist.xcstrings`) — can follow later.
- Replacing the manual decimal-comma handling in `SetEntrySheet` (already accepts `,` and `.`).

## Decisions

### D1: String Catalog (`Localizable.xcstrings`), not legacy `.strings`
The build settings already opt into catalogs, Xcode auto-extracts SwiftUI `LocalizedStringKey` literals at build time, and one JSON file carries all languages with per-key translation state. Alternative — `.lproj/Localizable.strings` pairs — rejected: legacy format, no extraction state tracking, no built-in plural support (would also need `.stringsdict`).

The catalog lives at `gymapp/Localizable.xcstrings`; the synchronized root group includes it automatically. `es` is added to `knownRegions` in `project.pbxproj` (the one required project-file edit).

### D2: View literals stay as literals; non-view strings adopt `String(localized:)`
View code keeps `Text("Workout Log")` etc. — already `LocalizedStringKey`, zero code churn, auto-extracted. Model-layer strings (`DraftSeries.summary` components, `Muscle.displayName`, the `"Exercise"` fallback name) switch to `String(localized:)` so they extract too. Alternative — routing everything through a central strings enum — rejected as ceremony the 5-view app doesn't need; the generated-symbols setting already provides compile-time safety where wanted.

### D3: Exercise names localize at render time, keyed by stable `id`; stored `name` is the fallback
`Exercise` gains a computed `localizedName` that resolves `Bundle.main.localizedString(forKey: "exercise.\(id)", value: name, table: "ExerciseNames")`. A second catalog, `ExerciseNames.xcstrings`, holds the 40 keys (`exercise.bench-press`, …) with English and Spanish values. Views display `localizedName`; the stored `name` remains the canonical English value used by seeding, uniqueness, and unit tests.

Why this over alternatives:
- **Re-seeding/migrating localized names into SwiftData** — rejected: names would freeze in whatever language was active at seed time, break when the user changes device language, and require a migration.
- **Storing per-language name columns** — rejected: schema change for a problem the bundle already solves.
- The `value:` parameter gives automatic fallback: an id with no catalog entry (e.g. a future custom exercise) displays its stored name unchanged. Muscle-target metadata is untouched — `Muscle` raw values (`chest`, `full_body`, …) remain the serialization identifiers in JSON and SwiftData.

A separate table keeps the 40 manually-maintained keys from mixing with auto-extracted UI strings (extraction can prune/flag manual entries in the main table).

### D4: Selection UI sorts by localized display name, in memory
SwiftData can't sort on a computed property, so the exercise picker query fetches and sorts in memory with `localizedStandardCompare` on `localizedName`. 40 rows make this free. Under English the localized names equal stored names, so `CatalogSeederTests`' alphabetical-order assertion still holds.

### D5: Plurals via String Catalog plural variation
`DraftSeries.summary` components become `String(localized:)` with interpolated integers; the catalog defines plural variants: en `"1 rep"/"%lld reps"`, `"%lld min"`, es `"%lld serie"/"%lld series"` for the Routines list count, etc. This fixes the English `"1 reps"` bug. UI tests assert `"10 reps · 40 kg"` and `"15 min"` — plural-correct English leaves those strings unchanged. The `" · "` joiner stays hardcoded (punctuation, not language).

### D6: UI tests pin the app to English via launch arguments
Each UI test launch adds `-AppleLanguages (en)` and `-AppleLocale en_US` to `launchArguments` (alongside the existing `-uitest-reset` flag), making the ~40 literal-English assertions deterministic on any simulator. Alternative — rewriting all assertions to accessibility identifiers — far more churn for no product value; identifiers like `day-*` remain locale-independent already. Unit tests need nothing: stored data stays English.

### D7: Dates and numbers — verify, don't change
All formatting already uses locale-aware `FormatStyle` (`.formatted(.dateTime…)`, `.number.precision(…)`) and `Calendar.current`; under `es` these localize for free. The only work is manual verification in a Spanish simulator.

## Risks / Trade-offs

- **[Hand-edited `.xcstrings` JSON is easy to malform]** → The file is plain JSON with a documented shape; validate by building (`xcodebuild` fails on a corrupt catalog) and by round-tripping in Xcode. Keep UI strings auto-extracted (build regenerates entries) so only `ExerciseNames.xcstrings` and plural variants are hand-authored.
- **[Catalog drift: new exercise added to `exercises.json` without a matching `ExerciseNames` entry]** → Fallback shows the English stored name (degraded, not broken). Add a unit test asserting every id in `exercises.json` has an `es` entry in `ExerciseNames.xcstrings`.
- **[Auto-extraction only runs on build; forgotten literals silently stay English]** → After implementation, audit the catalog against the survey inventory (all 6 views); the completeness unit test plus a Spanish-simulator walkthrough of every screen covers the rest.
- **[Localized sort order differs per language]** → Intentional (spec change): Spanish users see Spanish alphabetization. Sort assertions in tests run under English where order is unchanged.
- **[`assertionFailure`/`fatalError` messages stay English]** → Deliberate; developer-facing, never shown in release UI.

## Migration Plan

No data migration: SwiftData schema and seeded values are unchanged; localization is resolved at render time. Rollback = revert the commit (catalog files and `knownRegions` entry are additive). Ship order: infrastructure → externalize strings → translations → test pinning, all in one change.

## Open Questions

None blocking. If a future change adds user-created custom exercises, their names bypass localization by design (D3 fallback).
