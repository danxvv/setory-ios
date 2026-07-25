## MODIFIED Requirements

### Requirement: Deterministic photo matching for automated tests

The app SHALL support a `-uitest-photo-match <scenario>` launch argument that swaps in a stubbed match service and a bundled fixture image path so automated tests exercise the flow without opening the camera or photo library. Scenarios MUST cover at least `success` (fixed known catalog ids), `error` (network failure), and `no-key` (empty key store). The description field and the main-muscle selection MUST be drivable by automated tests through stable accessibility identifiers, and the stubbed scenarios MUST behave identically whether or not hints are set so results stay deterministic. Assertions about the narrowed catalog listing and the description line SHALL be verifiable from the serialized request body without any network traffic.

The hook's argument detection and fixture-image lookup MUST live in the app's test-support layer, not in the photo match feature's view code: the sheet receives the fixture affordance through the same injection seam that supplies its match service. The hook and its stub SHALL be present only in test builds — in a Release build the stub and the fixture affordance MUST be absent from the binary and the launch argument MUST be inert, leaving the app on the Keychain key store and the real OpenRouter REST client.

#### Scenario: Stubbed success flow

- **WHEN** the app is launched with `-uitest-photo-match success` and the test drives the photo match flow using the fixture image
- **THEN** the results list deterministically shows the stub's known catalog exercises without any network traffic or system picker UI

#### Scenario: Driving the hints from a UI test

- **WHEN** a UI test types a description and selects a main muscle before requesting a match
- **THEN** both inputs are reachable by accessibility identifier and the flow proceeds to the stubbed results without opening system UI

#### Scenario: Feature view carries no test hook

- **WHEN** the photo match feature's sources are audited
- **THEN** no file reads launch arguments, exposes a UI-testing flag, or loads the fixture image directly

#### Scenario: Hook is inert in Release

- **WHEN** a Release build is launched with `-uitest-photo-match success`
- **THEN** no stub is installed, no fixture affordance appears in the capture phase, and the flow uses the Keychain key store and the real OpenRouter REST client
