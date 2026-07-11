# localization Delta Spec

## MODIFIED Requirements

### Requirement: Localized user interface
All user-facing text in the app SHALL be resolved through the localization system. The app SHALL support English (`en`, the development language) and Spanish (`es`). When the device language is Spanish, all app-provided text — navigation titles, tab labels, buttons, form labels and placeholders, section headers, footers, and empty states — MUST appear in Spanish. When the device language is unsupported, the app MUST fall back to English.

#### Scenario: Spanish device shows Spanish UI
- **WHEN** the app runs on a device set to Spanish
- **THEN** every screen (logging, set entry, routines list, routine detail, exercises library, exercise detail, exercise edit form, tab bar) renders its app-provided text in Spanish

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
