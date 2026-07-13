# ai-settings Specification

## Purpose
Settings screen for AI configuration — entering/clearing the OpenRouter API key (Keychain-backed, never stored in plaintext preferences), overriding the default model ID, and disclosing what data is sent to OpenRouter.

## Requirements

### Requirement: AI settings surface
The Routines tab SHALL provide access to an AI settings screen (toolbar action presenting a sheet) containing the OpenRouter API key entry and the model override. The screen and all its text MUST be localized in English and Spanish.

#### Scenario: Opening AI settings
- **WHEN** the user taps the settings action in the Routines tab toolbar
- **THEN** a settings sheet appears with an API key field and a model field

### Requirement: Secure API key storage
The OpenRouter API key SHALL be stored in the device Keychain and MUST NOT be written to UserDefaults, files, or logs. The entry field MUST mask input by default. The user MUST be able to replace and to clear the stored key; clearing MUST remove it from the Keychain and return the suggestion feature to its no-key state. The stored key value MUST NOT be displayed back in full after saving.

#### Scenario: Saving a key
- **WHEN** the user pastes an API key and saves
- **THEN** the key is stored in the Keychain and the settings screen indicates a key is configured without revealing it

#### Scenario: Clearing the key
- **WHEN** the user clears the stored key
- **THEN** the key is removed from the Keychain and the "Suggest with AI" action returns to its key-required state

#### Scenario: Key survives relaunch
- **WHEN** the app is terminated and relaunched after a key was saved
- **THEN** the suggestion feature is available without re-entering the key

### Requirement: Model override
The app SHALL use a single hardcoded default OpenRouter model ID for suggestion requests and SHALL let the user override it with a free-text model ID in AI settings. A blank override MUST mean the default model is used. The override MUST persist across launches and MUST be shown in the settings screen along with the default it replaces.

#### Scenario: Default model used
- **WHEN** the user has never set a model override and generates a suggestion
- **THEN** the request uses the app's default model ID

#### Scenario: Override applied
- **WHEN** the user enters a custom model ID and generates a suggestion
- **THEN** the request uses the custom model ID

#### Scenario: Clearing the override
- **WHEN** the user empties the model field
- **THEN** subsequent requests use the default model ID again

### Requirement: Privacy disclosure
The AI settings screen SHALL display a localized note describing what data is sent to OpenRouter when a suggestion is requested (exercise IDs, set counts, muscle-target metadata, session dates, and the optional goal text) and clarifying that requests happen only when the user explicitly asks for a suggestion, under the user's own API key.

#### Scenario: Privacy note visible
- **WHEN** the user opens AI settings on a Spanish-language device
- **THEN** the privacy note is shown in Spanish and lists the data categories sent to OpenRouter
