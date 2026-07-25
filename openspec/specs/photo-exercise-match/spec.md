# photo-exercise-match Specification

## Purpose
Identify catalog exercises from user-supplied photos: capture or select photos in the template editor, send them with a catalog listing to a vision-capable OpenRouter model under the user's own key, validate the returned ids against the local exercise store, and let the user add the matching exercises to the routine template being edited — with graceful failure handling, transient photo handling, and deterministic test hooks.

## Requirements

### Requirement: Photo match entry point
The template editor SHALL offer a photo match action alongside the existing exercise picker that opens the photo match flow. The action MUST be available for both new and existing templates.

#### Scenario: Launching photo match from the template editor
- **WHEN** the user editing a routine template taps the photo match action
- **THEN** the photo match sheet opens in its capture phase

### Requirement: Photo capture and selection
The photo match flow SHALL let the user provide up to 3 photos per request, either by taking a photo with the camera or by selecting existing photos from the photo library. The camera option MUST be hidden on devices where the camera is unavailable, leaving the library path fully functional. The user MUST be able to review and remove chosen photos before sending.

#### Scenario: Selecting photos from the library
- **WHEN** the user picks two photos from the photo library
- **THEN** both photos appear as removable previews in the sheet and the send action becomes enabled

#### Scenario: Photo limit enforced
- **WHEN** the user has already attached 3 photos
- **THEN** the flow does not accept additional photos until one is removed

#### Scenario: Camera unavailable
- **WHEN** the flow is opened on a device without a camera (e.g. the Simulator)
- **THEN** the camera option is not shown and the library option remains available

### Requirement: Photo match request contract
When the user requests a match, the app SHALL send a single request to the OpenRouter chat completions REST endpoint (`POST https://openrouter.ai/api/v1/chat/completions`) under the user's stored API key, honoring the existing model override. The user message MUST be a multimodal content array containing one text part with the full exercise catalog listing — id, name, equipment when present, and primary muscle-target metadata for every catalog and custom exercise — and one image part per photo, encoded as a base64 JPEG data URL after downscaling. The request MUST use a strict JSON-schema structured output whose `exerciseId` values are constrained to an enum of the ids sent in the catalog listing and whose match list is capped at 10 entries, each carrying a confidence tier (`high`, `medium`, `low`). Inference MUST NOT happen on-device.

#### Scenario: Request shape
- **WHEN** the user sends 2 photos for matching
- **THEN** the app issues one POST to the OpenRouter endpoint whose user message contains one text part with the catalog listing (ids, names, and muscle metadata) and exactly two image parts, and whose `response_format` is a strict JSON schema restricting `exerciseId` to catalog ids

#### Scenario: Missing API key short-circuits
- **WHEN** the user requests a match with no API key configured
- **THEN** no network request is made and the flow surfaces the missing-key error that points to AI settings

### Requirement: Catalog-constrained match validation
The app SHALL validate the model's response against the local exercise store before showing results: ids not present in the store are dropped and duplicate ids are collapsed, preserving the model's best-first ordering. An empty list after validation SHALL be presented as a localized "no matches" state, not an error.

#### Scenario: Unknown ids dropped
- **WHEN** the response contains ids `gv0025`, `zz9999`, and `gv0025` again
- **THEN** the results list shows only the exercise for `gv0025`, once

#### Scenario: No matches found
- **WHEN** validation leaves no exercises
- **THEN** the sheet shows a localized no-matches message with the option to try different photos

### Requirement: Match result selection
The photo match flow SHALL present validated matches as a selectable list where each row shows the exercise's localized name, its primary muscle-target metadata, its thumbnail when media exists, and its confidence tier. The user MUST be able to select one or more results and confirm, which appends the selected exercises to the routine template draft as unsaved items with the default target set count; the template's existing save/cancel semantics are unchanged. Dismissing the sheet without confirming MUST NOT modify the draft.

#### Scenario: Adding a matched exercise to the routine
- **WHEN** the user selects "Barbell Bench Press" from the results and confirms
- **THEN** the sheet closes and the exercise appears as a new draft item in the template editor with the default target set count, pending the normal save

#### Scenario: Cancel adds nothing
- **WHEN** the user dismisses the sheet from the results phase without confirming
- **THEN** the template draft is unchanged

### Requirement: Match progress and cancellation
While a match request is in flight, the flow SHALL show a localized progress state and allow cancellation. Cancellation MUST abort the network request and return to the capture phase without an error alert.

#### Scenario: Cancelling a match
- **WHEN** the user cancels while the request is in flight
- **THEN** the request is aborted and the sheet returns to the capture phase showing the attached photos

### Requirement: Photo match failure handling
Failures SHALL be reported with the existing localized AI error taxonomy: invalid key, insufficient credits, rate limiting, network failure, and malformed response each produce their localized message, with key-related errors pointing to AI settings and a retry affordance that reuses the already-attached photos. Workout tracking and template editing MUST remain fully functional when matching fails or the device is offline.

#### Scenario: Network failure
- **WHEN** the match request fails with a transport error
- **THEN** a localized network-error alert is shown with a retry option, and retrying resends the same photos without re-picking them

### Requirement: Photo handling privacy
Photos SHALL be uploaded only when the user explicitly requests a match, MUST NOT be persisted to disk or the data store, and MUST be discarded when the sheet is dismissed.

#### Scenario: Photos are transient
- **WHEN** the user attaches photos and then dismisses the sheet
- **THEN** no photo data remains stored by the app

### Requirement: Deterministic photo matching for automated tests
The app SHALL support a `-uitest-photo-match <scenario>` launch argument that swaps in a stubbed match service and a bundled fixture image path so automated tests exercise the flow without opening the camera or photo library. Scenarios MUST cover at least `success` (fixed known catalog ids), `error` (network failure), and `no-key` (empty key store).

#### Scenario: Stubbed success flow
- **WHEN** the app is launched with `-uitest-photo-match success` and the test drives the photo match flow using the fixture image
- **THEN** the results list deterministically shows the stub's known catalog exercises without any network traffic or system picker UI
