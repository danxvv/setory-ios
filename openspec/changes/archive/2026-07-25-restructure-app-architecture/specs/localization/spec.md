## ADDED Requirements

### Requirement: Content locale resolution seam

Per-locale exercise content — display name, description, and instruction steps — SHALL be resolved through accessors that take an explicit language code. Resolution of the ambient device language SHALL happen at the presentation boundary; the `Exercise` entity MUST NOT read `Locale.current`.

Resolution semantics are unchanged and MUST hold for any requested language code: a user-modified exercise renders its stored text verbatim with no translation applied, an empty or absent translation for the requested language falls back to the canonical English value, and exercise search continues to match both the resolved display name and the canonical English name so English dataset vocabulary stays findable on a Spanish device.

This seam makes content-resolution behavior verifiable without pinning the test host's device language, which stored identifiers, muscle raw values, and AI request payloads already are (see the locale-independence requirements above).

#### Scenario: Explicit language code resolves content

- **WHEN** a unit test asks a seeded exercise for its display name, description, and instruction steps with language code `es`, and then with `en`, on a test host running any device language
- **THEN** each call returns that language's content, and neither result depends on the host's configured language

#### Scenario: Missing translation falls back to English

- **WHEN** content is requested with a language code for which an exercise carries no translation, or carries an empty one
- **THEN** the canonical English name, description, and instruction steps are returned

#### Scenario: User-modified exercise ignores translations

- **WHEN** content is requested in `es` for an exercise the user has edited
- **THEN** the user's stored name, description, and instruction steps are returned verbatim

#### Scenario: Display sites still resolve the device language

- **WHEN** the exercise library, exercise detail, logging rows, routine history, and progression list render on a Spanish device
- **THEN** each shows the Spanish display name, identical to the pre-change rendering
