# Tasks — Photo Exercise Match

## 1. Service layer

- [x] 1.1 Create `Setory/Models/PhotoMatchModels.swift`: `PhotoMatchRequestPayload` (catalog entries with `id`, `name`, `equipment?`, `primaryMuscles`; photo JPEG data array), `PhotoMatchResult` / `PhotoMatch` (`exerciseId`, `confidence` enum `high|medium|low`), all `Codable` + `Sendable`
- [x] 1.2 Create `Setory/Services/PhotoMatchRequestBuilder.swift`: system prompt, multimodal user message (one text part with compact catalog JSON + one `image_url` data-URL part per photo), strict `response_format` JSON schema with `exerciseId` enum over payload ids and `maxItems: 10`, honoring model + `aiModelOverride`
- [x] 1.3 Generalize the response envelope: extract the chat-completion envelope + HTTP status → `SuggestionError` mapping from `SuggestionResponseParser` so both suggestion and photo-match responses reuse it (no behavior change to the suggestion path)
- [x] 1.4 Create `Setory/Services/PhotoExerciseMatchService.swift`: `PhotoExerciseMatchService` protocol and `OpenRouterPhotoMatchService` (key store, `URLSession`, defaults injection; missing-key short-circuit; 60 s timeout; `URLError.cancelled` → `CancellationError`)
- [x] 1.5 Add image preprocessing helper (downscale to 1024 px max dimension, JPEG ~0.7, base64 data URL) as a small testable unit
- [x] 1.6 Add `@Entry var photoMatchService` to `Setory/Services/AIEnvironment.swift`; create `StubPhotoMatchService` with `uiTestService(scenario:)` for `success` / `error` / `no-key`

## 2. Unit tests (service layer)

- [x] 2.1 `SetoryTests/PhotoMatchRequestBuilderTests.swift` (Swift Testing): content-parts shape (text part + N image parts), catalog listing includes ids/names/muscle metadata, schema enum matches payload ids, `maxItems` cap, model override and blank-override fallback
- [x] 2.2 `SetoryTests/PhotoMatchServiceTests.swift` with `MockURLProtocol` (read `httpBodyStream`, `@Suite(.serialized)`): endpoint/method/headers, missing key makes no request, success decode, 401/402/429 mapping, transport failure, cancellation
- [x] 2.3 Validation tests: unknown ids dropped against an in-memory `ModelContainer`, duplicates collapsed preserving order, empty-after-validation result distinguishable from error

## 3. Capture & results UI

- [x] 3.1 Create `Setory/Views/CameraCaptureView.swift`: `UIViewRepresentable` wrapper over `UIImagePickerController(sourceType: .camera)`; availability check hides the camera path in Simulator
- [x] 3.2 Add `INFOPLIST_KEY_NSCameraUsageDescription` to Debug and Release configurations in `Setory.xcodeproj/project.pbxproj`
- [x] 3.3 Create `Setory/Views/PhotoMatchSheet.swift` capture phase: `PhotosPicker` multi-select + camera button, up-to-3 removable photo previews, send button enabled only with ≥1 photo, missing-key guidance pointing to AI settings
- [x] 3.4 Add loading phase: progress state with cancel (task cancellation returns to capture phase, no alert), error alerts via the shared `SuggestionError` localized messages with retry reusing attached photos
- [x] 3.5 Add results phase: validated matches with thumbnail, localized name, primary-muscle chips, confidence badge; multi-select; confirm invokes `onAdd: ([Exercise]) -> Void`; localized no-matches state; AX ids (`photo-match-button`, `photo-match-find-button`, `photo-match-result-<id>`, `photo-match-add-button`, `photo-match-cancel-button`)
- [x] 3.6 Wire entry point in `Setory/Views/TemplateEditForm.swift`: photo match button in the exercises section presenting `PhotoMatchSheet`, appending selected exercises to `draft.items` exactly like the multi-picker callback

## 4. Settings, app wiring & localization

- [x] 4.1 Update the privacy note in `Setory/Views/AISettingsView.swift` to disclose photo upload for photo matching (explicit request only, photos not stored)
- [x] 4.2 Add `-uitest-photo-match <scenario>` parsing to `Setory/SetoryApp.swift` (mirror `-uitest-ai`): swap key store + stub service via `.environment(...)`; add a bundled fixture image and a test-only attach path that bypasses camera/`PhotosPicker`
- [x] 4.3 Add all new EN strings with ES translations to `Setory/Localizable.xcstrings`; extend `SetoryTests/LocalizationTests.swift` key list; run unit tests to confirm no missing Spanish values

## 5. UI tests & verification

- [x] 5.1 `SetoryUITests/PhotoMatchUITests.swift`: `success` scenario — launch with `-uitest-reset -uitest-photo-match success`, open template editor, attach fixture image, run match, select a known result (e.g. `gv0025`), confirm it lands in the draft and saves; `error` scenario — localized alert with Retry; `no-key` scenario — guidance to AI settings; pin locale with `-AppleLanguages "(en)" -AppleLocale en_US`
- [x] 5.2 Run the full unit suite and `scripts/uitest.sh`; verify no regressions in `AISuggestionUITests` (shared parser/error changes) and capture screenshots via existing `XCTAttachment` conventions
