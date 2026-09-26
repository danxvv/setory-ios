# Add Photo Exercise Match

## Why

Finding the right exercise among 1324 catalog entries requires knowing its name, which is hard when the user is standing in front of an unfamiliar machine at the gym. Letting the user photograph the equipment (or pick existing photos) and having the AI identify matching catalog exercises removes the naming barrier and makes routine building faster at the point of use. The app already has the OpenRouter BYOK infrastructure (key storage, structured outputs, error mapping) this feature needs.

## What Changes

- New photo-based exercise matching flow: the user takes one or more photos with the camera or selects them from the photo library, the photos are sent to the OpenRouter vision-capable model together with a catalog listing (exercise id + name + metadata), and the model returns the matching exercise ids as a strict-schema structured output.
- Match results are validated against the local exercise store (unknown ids dropped) and presented as a selectable list with names, muscle targets, and thumbnails; the user picks one or more exercises to add to the routine template being edited.
- New entry point in the template editor's exercise section (alongside the existing picker) to launch the photo match flow.
- Camera capture requires a new `NSCameraUsageDescription`; photo library access uses `PhotosPicker` (no usage description needed).
- The AI settings privacy note is extended to disclose that photos are uploaded to OpenRouter when the user requests a photo match.
- Graceful degradation: without an API key the flow points to AI settings (same pattern as routine suggestions); network and API errors reuse the existing error taxonomy; workout tracking remains fully offline.
- Deterministic UI-test support via a `-uitest-photo-match <scenario>` launch hook that swaps in a stub match service and a bundled fixture image so tests never open the camera or `PhotosPicker`.

## Capabilities

### New Capabilities

- `photo-exercise-match`: Camera/photo-library capture, the vision request contract with OpenRouter (photos + catalog subset, strict JSON schema over catalog exercise ids), catalog-constrained validation of matches, the result-selection UI, the template-editor entry point, failure handling, and deterministic test hooks.

### Modified Capabilities

- `ai-settings`: The "Privacy disclosure" requirement changes — the privacy note must additionally disclose that user photos are sent to OpenRouter when a photo match is requested (and only then).

## Impact

- **New code**: photo match service + request builder (parallel to `RoutineSuggestionService` / `SuggestionPromptBuilder`, reusing `APIKeyStoring`, response-parsing envelope, and `SuggestionError`-style error mapping), a capture/selection view (`PhotosPicker` + `UIImagePickerController`-or-AVFoundation camera sheet), a match-results sheet, and a new `@Entry` environment value for injection.
- **Modified code**: `TemplateEditForm` (new entry point), `AISettingsView` (privacy note text), `SetoryApp.swift` (launch-argument hook), `Localizable.xcstrings` (new EN/ES strings).
- **Project settings**: `INFOPLIST_KEY_NSCameraUsageDescription` added to Debug/Release build settings in the pbxproj (one of the few required pbxproj edits).
- **External dependency**: OpenRouter chat completions REST contract, extended to multimodal user messages (`image_url` content parts with base64 data URLs); requires a vision-capable model. No new backend.
- **Tests**: unit tests for the request builder/response validation (Swift Testing, `MockURLProtocol` pattern), a UI test for the stubbed happy path and error path, and Spanish entries for every new string so `LocalizationTests` passes.
