# localization Specification (Delta)

## MODIFIED Requirements

### Requirement: Spanish translation completeness
Every localizable string in the app's string catalogs SHALL have a Spanish translation. Keys without a Spanish value MUST NOT ship, except where the source value is intentionally language-neutral (numbers, punctuation joiners). Exercise display names are exempt: they are English-only by design (the catalog dataset provides no translated names) and are not resolved through string catalogs. Exercise descriptions and instruction steps SHALL be available in Spanish via the per-locale content stored with each catalog exercise (see `exercise-catalog`), not via string catalogs.

#### Scenario: Catalog audit
- **WHEN** the string catalogs are audited for the `es` locale
- **THEN** no user-facing key is missing a Spanish translation

#### Scenario: Catalog exercise content is available in Spanish
- **WHEN** the seeded catalog is audited on a Spanish device
- **THEN** every catalog exercise resolves a Spanish description and Spanish instruction steps from its stored per-locale content

#### Scenario: Equipment labels are translated
- **WHEN** the equipment vocabulary is audited for the `es` locale
- **THEN** every equipment raw value has a Spanish display name
