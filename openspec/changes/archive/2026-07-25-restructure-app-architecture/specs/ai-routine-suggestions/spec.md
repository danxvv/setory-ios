## MODIFIED Requirements

### Requirement: Deterministic suggestions for automated tests

The app SHALL support a launch-argument test hook that replaces the OpenRouter client with a deterministic stub (success and failure scenarios) so unit and UI tests never perform network requests. The hook and its stub SHALL be present only in test builds: in a Release build the stub MUST be absent from the binary and the launch argument MUST be inert, leaving the app on the Keychain key store and the real OpenRouter REST client. Because both AI features share one key store, this hook MUST stub the whole AI stack so a test that stubs suggestions never leaves photo matching reading the real Keychain.

#### Scenario: Stubbed success in UI tests

- **WHEN** the app launches with the AI stub argument set to a success scenario
- **THEN** generating a suggestion presents the stub routine without any network traffic

#### Scenario: Hook is inert in Release

- **WHEN** a Release build is launched with the AI stub argument
- **THEN** no stub is installed, the app resolves the Keychain key store and the OpenRouter REST client, and the argument changes nothing else

#### Scenario: Hook stubs the shared AI stack

- **WHEN** the app launches with the AI stub argument set to `no-key`
- **THEN** both the suggestion service and the photo match service are stubs over an empty in-memory key store, and neither reads the real Keychain
