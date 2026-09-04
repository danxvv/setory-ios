# test-support-isolation Specification

## Purpose
Keep every affordance that exists only to serve automated tests — stub AI services, the in-memory key store, UI-test session seeding, the reset hook, the bundled photo fixture, and launch-argument parsing — consolidated in a single `TestSupport/` directory that is compiled out of Release builds, so feature code carries no test hooks, launch arguments have exactly one parser, and the reset path stays free of full catalog reseeding.

## Requirements

### Requirement: Consolidated test scaffolding
All scaffolding that exists only to serve automated tests SHALL live in a single `TestSupport/` directory of the app target. This includes the stubbed AI services for both AI features, the in-memory API key store, the UI-test session seeding, the reset routine that clears test data and restores a pristine catalog, the bundled photo fixture lookup, and the launch-argument parsing. Catalog operations the reset routine relies on — pristine restore and seeding — remain owned by the persistence layer and are unit-tested there; the reset routine delegates to them rather than reimplementing them.

Feature code MUST NOT contain test-only affordances. In particular, the photo match sheet's UI-test detection and its fixture-image lookup MUST move out of the feature's view file, with the sheet receiving whatever it needs through the same injection seam it already uses for its service.

Test scaffolding MUST remain reachable from the app target, because XCUITest drives the app out of process and cannot inject types into it; moving the stubs into the test target is not an option.

#### Scenario: Scaffolding is discoverable in one place
- **WHEN** a developer looks for everything the automated tests depend on inside the app target
- **THEN** the stub AI services, in-memory key store, UI-test seeding, catalog restore hook, photo fixture, and launch-argument parsing are all under `TestSupport/`

#### Scenario: Feature views carry no test hooks
- **WHEN** the sources under `Features/` are audited for test-only affordances
- **THEN** no feature view reads launch arguments, exposes a UI-testing flag, or loads a test fixture image

### Requirement: Centralized launch-argument parsing
Launch-argument parsing SHALL be performed by a single type in `TestSupport/` that exposes the parsed options as typed values. No other file in the app target MUST read `CommandLine.arguments`.

The recognized options and their meanings SHALL be unchanged: any argument prefixed `-uitest` disables UIKit animations; `-uitest-reset` wipes sessions, series, and templates and restores edited catalog exercises to pristine; `-uitest-seed` inserts the two known sessions; `-uitest-offline-media` disables the media store's network path and clears its cache directory; `-uitest-ai <scenario>` and `-uitest-photo-match <scenario>` swap in the in-memory key store and stubbed AI services for the `success`, `error`, and `no-key` scenarios; and `-uitest-disable-animations` carries no behavior beyond its `-uitest` prefix.

Because both AI features share one key store, either AI scenario hook MUST stub the whole AI stack, so a test stubbing one feature never leaves the other reading the real Keychain.

#### Scenario: One parser owns the arguments
- **WHEN** the sources are audited for `CommandLine.arguments`
- **THEN** exactly one file references it, and that file is under `TestSupport/`

#### Scenario: Existing launch arguments behave identically
- **WHEN** the UI test suite launches the app with each of its current launch-argument combinations
- **THEN** each produces the same app state it produced before the restructure, and every UI test passes unchanged

#### Scenario: Either AI hook stubs the whole AI stack
- **WHEN** the app launches with `-uitest-photo-match success`
- **THEN** both the photo match service and the routine suggestion service are stubs, and neither reads the real Keychain

### Requirement: Test scaffolding absent from Release builds
The contents of `TestSupport/` SHALL be compiled out of Release builds, so no stub AI service, in-memory key store, UI-test seeding path, or launch-argument hook is present in a shipped binary. In a Release build the `-uitest-*` arguments MUST be inert: passing them changes nothing, and the app uses the Keychain key store, the real OpenRouter clients, and the live media path.

Debug builds MUST keep the full scaffolding available, because the UI test suite runs the Debug configuration.

#### Scenario: Release binary has no stubs
- **WHEN** a Release build of the app target is produced
- **THEN** it contains no stub AI service and no in-memory key store, and the AI dependencies resolve to the Keychain store and the OpenRouter clients unconditionally

#### Scenario: Launch arguments are inert in Release
- **WHEN** a Release build is launched with `-uitest-reset -uitest-seed -uitest-ai success`
- **THEN** no data is wiped or seeded, no stub is installed, and the app behaves exactly as it does with no arguments

#### Scenario: Debug builds keep the hooks
- **WHEN** the UI test suite runs against a Debug build
- **THEN** every launch-argument hook works and the whole suite passes

### Requirement: Reset hook stays reseed-free
The `-uitest-reset` path SHALL restore a pristine catalog without wiping and reseeding the whole exercise table. It MUST re-align exercises the user edited, and it MUST parse the bundled catalog JSON only when at least one edited exercise exists.

This constraint is a performance requirement on the UI suite: a full wipe and reseed of the ~1,300-row catalog on every launch dominated total UI-test wall time. The restructure MUST NOT reintroduce it.

#### Scenario: Clean reset does no catalog parsing
- **WHEN** the app launches with `-uitest-reset` and no exercise has been edited
- **THEN** the bundled catalog JSON is not parsed, and no exercise row is deleted or reinserted

#### Scenario: Leaked edit is restored
- **WHEN** the app launches with `-uitest-reset` after a prior test renamed a catalog exercise
- **THEN** that exercise's name, category, equipment, muscle-target metadata, media reference, and per-locale content are restored to their catalog values, and its user-modified flag is cleared
