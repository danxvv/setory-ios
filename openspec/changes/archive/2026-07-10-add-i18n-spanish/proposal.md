# Proposal: add-i18n-spanish

## Why

The app is English-only: every user-facing string is a hardcoded literal, exercise and muscle display names are raw English strings, and there is no localization infrastructure at all (`knownRegions = (en, Base)`, no String Catalog). Spanish-speaking users — the app's primary early audience — get an entirely English UI even when their device is set to Spanish. Internationalizing now, while the app has only 5 views and ~45 strings, is far cheaper than retrofitting later.

## What Changes

- Add internationalization infrastructure: a `Localizable.xcstrings` String Catalog, `es` added to the project's known regions. Build settings are already primed (`LOCALIZATION_PREFERS_STRING_CATALOGS`, `SWIFT_EMIT_LOC_STRINGS`, `STRING_CATALOG_GENERATE_SYMBOLS` are all on).
- Externalize all user-facing UI strings (navigation titles, tab labels, buttons, form labels, section headers, empty states, footers, accessibility values) into the String Catalog and provide complete Spanish translations.
- Localize the series summary format strings in `DraftSeries` (`"N reps"`, `"N min"`, `"N kg"`) with proper plural rules — fixing the existing `"1 reps"` / `"1 min"` pluralization bug in English as a side effect.
- Localize the 16 hardcoded `Muscle.displayName` strings.
- Localize exercise catalog display names at render time via each exercise's stable `id` (e.g. `bench-press`), keeping the stored SwiftData `name` as the canonical English value — no data migration, and custom/unknown exercises fall back to their stored name.
- Localize the pluralized series count on the Routines list (`"N series"` → es `"N serie(s)"`).
- Pin UI tests to English via launch arguments so existing string assertions keep passing; keep unit tests valid against stored (English) catalog data.
- Date and number formatting already uses locale-aware `FormatStyle` APIs; no changes needed there beyond verification under `es`.

## Capabilities

### New Capabilities

- `localization`: App-wide internationalization — all user-facing text resolved through the localization system, complete Spanish (`es`) translations with English as the development/fallback language, correct plural forms in both languages, and locale-aware date/number rendering.

### Modified Capabilities

- `exercise-catalog`: Exercise display names become locale-dependent — resolved from the exercise's stable `id` with fallback to the stored name — and the selection-UI query sorts by the localized display name using locale-aware comparison (Spanish alphabetization differs from English).

## Impact

- **Code**: All 6 view files (`ContentView`, `SetEntrySheet`, `RoutineListView`, `RoutineDetailView`, `RootTabView`, `MonthCalendarView`), `Models/DraftSeries.swift`, `Models/Muscle.swift`, `Models/Exercise.swift` (new localized-name accessor), `Models/WorkoutSession.swift` (`exerciseNames` summary), `Services/CatalogSeeder.swift` (unchanged seeding, but sort behavior in the catalog query changes).
- **Resources**: New `gymapp/Localizable.xcstrings` (picked up automatically by the synchronized file group); `exercises.json` unchanged.
- **Project file**: `knownRegions` gains `es` in `project.pbxproj`.
- **Tests**: `gymappUITests` gain a forced-English launch configuration (assertions on literal English strings otherwise break under a Spanish simulator); unit tests unaffected because stored data stays English.
- **Out of scope**: localizing user-generated content, the AI suggestion backend contract (external dependency), and additional languages beyond Spanish.
