## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Match results show localized names
The photo match results list SHALL display each matched exercise's resolved display name for the current device language, while the underlying selection and the items appended to the routine draft continue to be keyed by locale-independent exercise `id`. Muscle-target metadata shown alongside each match MUST use localized muscle labels over unchanged raw values.

#### Scenario: Spanish device shows Spanish match names
- **WHEN** the model returns matches on a Spanish device
- **THEN** each result row shows the exercise's Spanish name with localized primary-muscle labels, and confirming the selection appends items referencing the same exercise ids as on an English device
