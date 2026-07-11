# localization Specification

## Purpose
Provide full localization of the app's user-facing text in English and Spanish, including plural-aware quantity strings, localized muscle display names, locale-aware date and number rendering, and localized accessibility strings, while keeping stored identifiers and serialization keys locale-independent.

## Requirements

### Requirement: Localized user interface
All user-facing text in the app SHALL be resolved through the localization system. The app SHALL support English (`en`, the development language) and Spanish (`es`). When the device language is Spanish, all app-provided text — navigation titles, tab labels, buttons, form labels and placeholders, section headers, footers, and empty states — MUST appear in Spanish. When the device language is unsupported, the app MUST fall back to English.

#### Scenario: Spanish device shows Spanish UI
- **WHEN** the app runs on a device set to Spanish
- **THEN** every screen (logging, set entry, routines list, routine detail, exercises library, exercise detail, exercise edit form, progress tab, exercise progression, tab bar) renders its app-provided text in Spanish

#### Scenario: English device shows English UI
- **WHEN** the app runs on a device set to English
- **THEN** all app-provided text renders in English

#### Scenario: Unsupported language falls back to English
- **WHEN** the app runs on a device set to a language other than English or Spanish
- **THEN** all app-provided text renders in English

### Requirement: Spanish translation completeness
Every localizable string in the app's string catalogs SHALL have a Spanish translation. Keys without a Spanish value MUST NOT ship, except where the source value is intentionally language-neutral (numbers, punctuation joiners).

#### Scenario: Catalog audit
- **WHEN** the string catalogs are audited for the `es` locale
- **THEN** no user-facing key is missing a Spanish translation

#### Scenario: Bundled exercise names are fully translated
- **WHEN** the exercise-name catalog is compared against the bundled `exercises.json`
- **THEN** every exercise id in the seed data has a Spanish display-name entry

#### Scenario: Bundled exercise content is fully translated
- **WHEN** the exercise-content catalog is compared against the bundled `exercises.json`
- **THEN** every exercise id in the seed data has a Spanish entry for its description and for each of its instruction steps

### Requirement: Plural-aware quantity strings
Quantity strings — repetitions, minutes, and series counts — SHALL use language-appropriate plural rules in both English and Spanish. Singular quantities MUST NOT render with plural nouns.

#### Scenario: Singular rep in English
- **WHEN** a series with 1 repetition is summarized on an English device
- **THEN** the summary reads "1 rep", not "1 reps"

#### Scenario: Plural series count in Spanish
- **WHEN** a saved session with 2 series is listed on the Routines screen on a Spanish device
- **THEN** the row shows "2 series" using the Spanish plural form, and a session with 1 series shows the singular "1 serie"

#### Scenario: Weight and duration units localize
- **WHEN** a series with weight and a series with duration are summarized on a Spanish device
- **THEN** the weight and duration values render with Spanish-appropriate unit strings and locale-correct number formatting

### Requirement: Localized muscle display names
The display names of all muscle values SHALL be localized in English and Spanish. Muscle raw identifiers (e.g. `chest`, `full_body`) MUST remain unchanged as serialization keys in the seed data and persistent store — localization applies only at display time, keeping muscle-target metadata stable for the AI-suggestion contract.

#### Scenario: Muscle names in Spanish
- **WHEN** the routine detail view shows muscle-target information on a Spanish device
- **THEN** muscle names render in Spanish (e.g. `chest` displays as "Pecho")

#### Scenario: Raw identifiers unaffected
- **WHEN** exercises are seeded or persisted while the device is set to Spanish
- **THEN** stored muscle values and exercise ids are identical to those stored under English

### Requirement: Locale-aware date and number rendering
Dates and numbers displayed by the app SHALL follow the device locale's conventions using system formatting APIs. No date or number format MUST be pinned to a fixed locale in app code.

#### Scenario: Calendar and dates in Spanish
- **WHEN** the logging calendar and routine dates render on a Spanish device
- **THEN** month names, weekday symbols, and date strings appear in Spanish with locale-correct ordering

#### Scenario: Decimal weight input with comma
- **WHEN** a Spanish-locale user enters a weight using a decimal comma (e.g. "40,5")
- **THEN** the value is accepted and stored as 40.5 kg

### Requirement: Localized accessibility strings
Accessibility labels and values provided by the app SHALL be localized. Stable accessibility identifiers used for test automation MUST remain locale-independent.

#### Scenario: VoiceOver on a saved day
- **WHEN** VoiceOver reads a calendar day with a saved workout on a Spanish device
- **THEN** the announced value is in Spanish

#### Scenario: Test identifiers are stable across locales
- **WHEN** the app runs under any supported language
- **THEN** accessibility identifiers (e.g. `day-*`) are byte-identical to the English run
