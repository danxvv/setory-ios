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

### Requirement: Photo match context hints
The photo match capture phase SHALL let the user attach two optional hints to a match request: a short free-text description of the equipment or exercise, and a single main muscle chosen from the app's muscle-target values. Both MUST default to unset, MUST be editable until the request is sent, MUST be disabled while a request is in flight, and MUST remain transient — never persisted to disk or the data store, and discarded when the sheet is dismissed. Photos MUST remain required: hints alone SHALL NOT enable the match action.

#### Scenario: Sending without hints
- **WHEN** the user attaches a photo, leaves the description empty and the main muscle unset, and requests a match
- **THEN** the request carries the full local catalog listing and no description or muscle line, exactly as before the hints existed

#### Scenario: Selecting a main muscle
- **WHEN** the user selects "Chest" as the main muscle
- **THEN** the selection is shown as the active main-muscle value and can be cleared back to unset

#### Scenario: Hints are transient
- **WHEN** the user enters a description, selects a main muscle, and dismisses the sheet
- **THEN** no description or muscle selection is stored by the app, and reopening the flow shows both inputs unset

### Requirement: Main-muscle catalog narrowing
When the user selects a main muscle, the app SHALL restrict the catalog listing it sends to OpenRouter to exercises whose **primary** muscle-target metadata includes that muscle, using the same primary-muscle definition as the exercise library's muscle filter. Because the strict response schema's `exerciseId` enum is built from the catalog that was sent, the narrowed listing MUST also narrow the schema enum, making an off-muscle match structurally impossible. Secondary muscle targets SHALL NOT satisfy the filter.

#### Scenario: Catalog narrowed to the selected muscle
- **WHEN** the user selects "Chest" and requests a match
- **THEN** the catalog listing in the request contains only exercises whose primary muscles include chest, and the `response_format` schema's `exerciseId` enum contains exactly those ids

#### Scenario: Secondary muscles do not qualify
- **WHEN** the user selects "Triceps" and the catalog contains a bench press whose primary muscle is chest and secondary muscle is triceps
- **THEN** the bench press is absent from the catalog listing sent for that request

#### Scenario: No exercise targets the selected muscle
- **WHEN** the selected main muscle matches no exercise in the local store
- **THEN** no request is sent, the match action is unavailable, and the flow shows a localized message telling the user to change or clear the main muscle

### Requirement: Photo match request contract
When the user requests a match, the app SHALL send a single request to the OpenRouter chat completions REST endpoint (`POST https://openrouter.ai/api/v1/chat/completions`) under the user's stored API key, honoring the existing model override. The user message MUST be a multimodal content array containing one text part and one image part per photo, encoded as a base64 JPEG data URL after downscaling. The text part MUST contain the exercise catalog listing — id, name, equipment when present, and primary muscle-target metadata for every exercise sent — and, when the user supplied them, the selected main muscle and the user's description, each as its own labeled line kept distinct from the catalog listing. The names in the catalog listing MUST be the exercises' canonical (English) names, never the device-language variants, so the listing is byte-identical in every language and the model matches against the dataset's own vocabulary; user-modified exercises contribute their stored name, which is canonical for them. The description MUST be whitespace-trimmed, omitted when empty, and capped at 200 characters. The catalog listing MUST be the full local catalog (bundled and custom exercises) when no main muscle is selected, and the primary-muscle-filtered subset when one is. The request MUST use a strict JSON-schema structured output whose `exerciseId` values are constrained to an enum of the ids sent in the catalog listing and whose match list is capped at 10 entries, each carrying a confidence tier (`high`, `medium`, `low`). The system prompt MUST instruct the model to treat the user description as a hint about the photos and to answer only with ids from the catalog listing. Inference MUST NOT happen on-device.

#### Scenario: Request shape
- **WHEN** the user sends 2 photos for matching
- **THEN** the app issues one POST to the OpenRouter endpoint whose user message contains one text part with the catalog listing (ids, names, and muscle metadata) and exactly two image parts, and whose `response_format` is a strict JSON schema restricting `exerciseId` to the ids sent in that listing

#### Scenario: Catalog listing is language-independent
- **WHEN** the same photo-match request is built on a Spanish device and on an English device
- **THEN** the catalog listing carries the canonical English exercise names in both cases and the two payloads are identical

#### Scenario: Description carried in the text part
- **WHEN** the user enters "seat pushes forward, handles at chest height" and requests a match
- **THEN** the text part contains that description on its own labeled line, separate from the catalog listing, and the image parts are unchanged

#### Scenario: Overlong description is capped
- **WHEN** the user enters a description longer than 200 characters
- **THEN** the request carries at most the first 200 characters of it

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

### Requirement: Match results show localized names
The photo match results list SHALL display each matched exercise's resolved display name for the current device language, while the underlying selection and the items appended to the routine draft continue to be keyed by locale-independent exercise `id`. Muscle-target metadata shown alongside each match MUST use localized muscle labels over unchanged raw values.

#### Scenario: Spanish device shows Spanish match names
- **WHEN** the model returns matches on a Spanish device
- **THEN** each result row shows the exercise's Spanish name with localized primary-muscle labels, and confirming the selection appends items referencing the same exercise ids as on an English device

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
The app SHALL support a `-uitest-photo-match <scenario>` launch argument that swaps in a stubbed match service and a bundled fixture image path so automated tests exercise the flow without opening the camera or photo library. Scenarios MUST cover at least `success` (fixed known catalog ids), `error` (network failure), and `no-key` (empty key store). The description field and the main-muscle selection MUST be drivable by automated tests through stable accessibility identifiers, and the stubbed scenarios MUST behave identically whether or not hints are set so results stay deterministic. Assertions about the narrowed catalog listing and the description line SHALL be verifiable from the serialized request body without any network traffic.

#### Scenario: Stubbed success flow
- **WHEN** the app is launched with `-uitest-photo-match success` and the test drives the photo match flow using the fixture image
- **THEN** the results list deterministically shows the stub's known catalog exercises without any network traffic or system picker UI

#### Scenario: Driving the hints from a UI test
- **WHEN** a UI test types a description and selects a main muscle before requesting a match
- **THEN** both inputs are reachable by accessibility identifier and the flow proceeds to the stubbed results without opening system UI
