## MODIFIED Requirements

### Requirement: Spanish translation completeness
Every localizable string in the app's string catalogs SHALL have a Spanish translation. Keys without a Spanish value MUST NOT ship, except where the source value is intentionally language-neutral (numbers, punctuation joiners). Exercise display names, descriptions, and instruction steps are not resolved through string catalogs: they SHALL be available in Spanish via the per-locale content stored with each catalog exercise (see `exercise-catalog`). Every catalog exercise MUST carry a non-empty Spanish name, a non-empty Spanish description, and non-empty Spanish instruction steps; a catalog entry missing any of them MUST NOT ship.

#### Scenario: Catalog audit
- **WHEN** the string catalogs are audited for the `es` locale
- **THEN** no user-facing key is missing a Spanish translation

#### Scenario: Catalog exercise names are available in Spanish
- **WHEN** the bundled catalog is audited for the `es` locale
- **THEN** every catalog exercise carries a non-empty Spanish name variant

#### Scenario: Catalog exercise content is available in Spanish
- **WHEN** the seeded catalog is audited on a Spanish device
- **THEN** every catalog exercise resolves a Spanish name, a Spanish description, and Spanish instruction steps from its stored per-locale content

#### Scenario: Equipment labels are translated
- **WHEN** the equipment vocabulary is audited for the `es` locale
- **THEN** every equipment raw value has a Spanish display name

### Requirement: Localized muscle display names
The display names of all muscle values SHALL be localized in English and Spanish. Muscle raw identifiers (e.g. `chest`, `full_body`) MUST remain unchanged as serialization keys in the seed data and persistent store — localization applies only at display time, keeping muscle-target metadata stable for the AI-suggestion contract. The same separation applies to exercise names: exercise `id` values and the exercise names sent to the AI REST endpoints stay locale-independent regardless of the device language.

#### Scenario: Muscle names in Spanish
- **WHEN** the routine detail view shows muscle-target information on a Spanish device
- **THEN** muscle names render in Spanish (e.g. `chest` displays as "Pecho")

#### Scenario: Raw identifiers unaffected
- **WHEN** exercises are seeded or persisted while the device is set to Spanish
- **THEN** stored muscle values and exercise ids are identical to those stored under English

#### Scenario: AI payloads stay locale-independent
- **WHEN** a request is built for the AI suggestion or photo-match REST endpoints on a Spanish device
- **THEN** the exercise ids, muscle raw values, and any exercise names it carries are byte-identical to those built on an English device
