# ai-routine-suggestions Specification

## Purpose
Generate a suggested routine template from recent workout history and an optional user goal via the OpenRouter API; review and edit the suggestion in the template editor before saving; constrain suggestions to catalog exercises; handle missing-key, network, and malformed-response failures gracefully.

## Requirements

### Requirement: AI suggestion entry point
The Routines tab SHALL offer a "Suggest with AI" action. When an OpenRouter API key is configured, the action MUST present a suggestion sheet with an optional free-text goal field and a generate control. When no API key is configured, the action MUST instead explain that a key is required and offer to open the AI settings; it MUST NOT attempt a network request.

#### Scenario: Entry point with a configured key
- **WHEN** the user taps "Suggest with AI" in the Routines tab and an API key is stored
- **THEN** a sheet appears with an optional goal text field and a generate button

#### Scenario: Entry point without a key
- **WHEN** the user taps "Suggest with AI" and no API key is stored
- **THEN** a localized explanation is shown with an action that opens the AI settings, and no network request is made

### Requirement: Suggestion request contract
Suggestions SHALL be obtained from the OpenRouter REST API (`POST https://openrouter.ai/api/v1/chat/completions`, authenticated with the stored key as a Bearer token) — inference never happens on-device. The request MUST use a structured-output response format (strict JSON schema) describing a routine as a name, a rationale, and an ordered list of items each holding a catalog exercise ID and a target set count. The request payload MUST include a bounded, relevance-filtered subset of the exercise catalog — not the full catalog — composed of: exercises from the user's recent workout history, exercises matching goal-relevant muscles when a goal is provided, and a sample spread across muscle groups and equipment for variety, deduplicated and capped at a fixed maximum. Each included exercise carries its ID, category, equipment, and muscle-target metadata (primary and secondary muscles, serialized as the stable `Muscle` raw values). The response schema's exercise-ID constraint MUST be built from the same subset. The payload MUST also include a summary of recent workout history (dates, exercise IDs with series counts, and muscles worked) and the user's goal text when provided. The request MUST instruct the model to respond with user-facing text (name, rationale) in the device language (English or Spanish).

#### Scenario: Payload is bounded at full catalog size
- **WHEN** a suggestion is generated with the full 1,300+ exercise catalog seeded
- **THEN** the request contains no more catalog entries than the fixed maximum, and every entry carries its ID, category, equipment, and muscle raw values

#### Scenario: Recent exercises are always included
- **WHEN** a suggestion is generated for a user with recent workout sessions
- **THEN** every exercise from the recent-history summary appears in the catalog subset sent to the API

#### Scenario: Goal text influences the subset
- **WHEN** the user enters "focus legs, 45 minutes" as the goal and generates
- **THEN** the request payload includes that goal text and the catalog subset includes exercises targeting leg muscles

#### Scenario: No history available
- **WHEN** a suggestion is generated before any workout has been logged
- **THEN** the request is still valid with a sampled catalog subset, indicating the history is empty, and the model is asked for a balanced starter routine

### Requirement: Catalog-constrained suggestion validation
The app SHALL validate every suggestion response before showing it: items whose exercise ID does not match an exercise in the local store MUST be dropped, target set counts MUST be clamped to the 1–10 range, and repeated exercises MUST be deduplicated preserving first occurrence. Muscle-target metadata for accepted items MUST be resolved from the local `Exercise` records, never from the model response. If no valid items remain after validation, the app MUST treat the response as a failure.

#### Scenario: Unknown exercise ID is dropped
- **WHEN** the API response contains items with IDs `bench-press` and `nonexistent-exercise`
- **THEN** the presented suggestion contains only `bench-press`, with its muscle targets read from the local catalog record

#### Scenario: Out-of-range target sets are clamped
- **WHEN** a response item specifies 15 target sets
- **THEN** the presented item shows 10 target sets

#### Scenario: Entirely invalid response fails
- **WHEN** every item in the response has an unknown exercise ID
- **THEN** a localized error is shown with a retry option and nothing is presented for review

### Requirement: Review and save flow
A validated suggestion SHALL open in the existing template editor as an editable draft pre-filled with the suggested name, exercises, and target set counts, with the model's rationale displayed alongside. The user MUST be able to edit everything before saving. Nothing SHALL be persisted until the user saves from the editor; saving MUST produce a standard routine template indistinguishable from a manually created one (including derived muscle coverage), and cancelling MUST discard the suggestion entirely.

#### Scenario: Accepting a suggestion
- **WHEN** a suggestion is generated and the user saves it from the editor without edits
- **THEN** a routine template with the suggested name, exercises, and target sets persists and appears in the Routines list with muscle coverage derived from its exercises

#### Scenario: Cancelling a suggestion
- **WHEN** the user cancels the editor after a suggestion was generated
- **THEN** no template is persisted and the Routines list is unchanged

### Requirement: Suggestion failure handling
The app SHALL map suggestion failures to localized, human-readable errors with a retry option: network unavailability, invalid API key (HTTP 401), insufficient credits (402), rate limiting (429), and malformed or schema-violating responses (including OpenRouter responses whose `finish_reason` is `error`). Invalid-key and credit errors MUST point the user to the AI settings. A failed or cancelled suggestion MUST leave all tracking and template features untouched.

#### Scenario: Offline generation attempt
- **WHEN** the user generates a suggestion without network connectivity
- **THEN** a localized network error with a retry option is shown, and logging and templates keep working

#### Scenario: Invalid key
- **WHEN** the API responds 401
- **THEN** the error message says the key appears invalid and offers to open AI settings

### Requirement: Generation progress and cancellation
While a suggestion request is in flight the app SHALL show a progress state and allow cancelling. Cancelling MUST abandon the request without an error alert and return to the suggestion sheet.

#### Scenario: User cancels mid-request
- **WHEN** the user cancels while the request is loading
- **THEN** the progress state ends, no error is shown, and no editor is presented

### Requirement: Deterministic suggestions for automated tests
The app SHALL support a launch-argument test hook that replaces the OpenRouter client with a deterministic stub (success and failure scenarios) so unit and UI tests never perform network requests.

#### Scenario: Stubbed success in UI tests
- **WHEN** the app launches with the AI stub argument set to a success scenario
- **THEN** generating a suggestion presents the stub routine without any network traffic
