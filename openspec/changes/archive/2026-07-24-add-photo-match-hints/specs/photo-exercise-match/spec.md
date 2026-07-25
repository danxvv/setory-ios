## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Photo match request contract
When the user requests a match, the app SHALL send a single request to the OpenRouter chat completions REST endpoint (`POST https://openrouter.ai/api/v1/chat/completions`) under the user's stored API key, honoring the existing model override. The user message MUST be a multimodal content array containing one text part and one image part per photo, encoded as a base64 JPEG data URL after downscaling. The text part MUST contain the exercise catalog listing — id, name, equipment when present, and primary muscle-target metadata for every exercise sent — and, when the user supplied them, the selected main muscle and the user's description, each as its own labeled line kept distinct from the catalog listing. The description MUST be whitespace-trimmed, omitted when empty, and capped at 200 characters. The catalog listing MUST be the full local catalog (bundled and custom exercises) when no main muscle is selected, and the primary-muscle-filtered subset when one is. The request MUST use a strict JSON-schema structured output whose `exerciseId` values are constrained to an enum of the ids sent in the catalog listing and whose match list is capped at 10 entries, each carrying a confidence tier (`high`, `medium`, `low`). The system prompt MUST instruct the model to treat the user description as a hint about the photos and to answer only with ids from the catalog listing. Inference MUST NOT happen on-device.

#### Scenario: Request shape
- **WHEN** the user sends 2 photos for matching
- **THEN** the app issues one POST to the OpenRouter endpoint whose user message contains one text part with the catalog listing (ids, names, and muscle metadata) and exactly two image parts, and whose `response_format` is a strict JSON schema restricting `exerciseId` to the ids sent in that listing

#### Scenario: Description carried in the text part
- **WHEN** the user enters "seat pushes forward, handles at chest height" and requests a match
- **THEN** the text part contains that description on its own labeled line, separate from the catalog listing, and the image parts are unchanged

#### Scenario: Overlong description is capped
- **WHEN** the user enters a description longer than 200 characters
- **THEN** the request carries at most the first 200 characters of it

#### Scenario: Missing API key short-circuits
- **WHEN** the user requests a match with no API key configured
- **THEN** no network request is made and the flow surfaces the missing-key error that points to AI settings

### Requirement: Deterministic photo matching for automated tests
The app SHALL support a `-uitest-photo-match <scenario>` launch argument that swaps in a stubbed match service and a bundled fixture image path so automated tests exercise the flow without opening the camera or photo library. Scenarios MUST cover at least `success` (fixed known catalog ids), `error` (network failure), and `no-key` (empty key store). The description field and the main-muscle selection MUST be drivable by automated tests through stable accessibility identifiers, and the stubbed scenarios MUST behave identically whether or not hints are set so results stay deterministic. Assertions about the narrowed catalog listing and the description line SHALL be verifiable from the serialized request body without any network traffic.

#### Scenario: Stubbed success flow
- **WHEN** the app is launched with `-uitest-photo-match success` and the test drives the photo match flow using the fixture image
- **THEN** the results list deterministically shows the stub's known catalog exercises without any network traffic or system picker UI

#### Scenario: Driving the hints from a UI test
- **WHEN** a UI test types a description and selects a main muscle before requesting a match
- **THEN** both inputs are reachable by accessibility identifier and the flow proceeds to the stubbed results without opening system UI
