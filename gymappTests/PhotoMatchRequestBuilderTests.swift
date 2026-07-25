//
//  PhotoMatchRequestBuilderTests.swift
//  gymappTests
//
//  Photo-match request assembly: the catalog listing sent as the user
//  message's text part, one image part per photo, the strict
//  response_format schema with its catalog-ID enum, and the image
//  preprocessing that feeds the data URLs.
//

import Foundation
import Testing
import UIKit
@testable import gymapp

struct PhotoMatchRequestBuilderTests {
    private func makeExercises() -> [Exercise] {
        [
            Exercise(
                id: "squat", name: "Barbell Full Squat", category: .strength,
                primaryMuscles: [.quads, .glutes], secondaryMuscles: [.hamstrings],
                equipment: .barbell
            ),
            Exercise(
                id: "bench-press", name: "Barbell Bench Press", category: .strength,
                primaryMuscles: [.chest], secondaryMuscles: [.triceps],
                equipment: .barbell
            ),
            Exercise(id: "custom-row", name: "My Row", category: .strength, primaryMuscles: [.back]),
        ]
    }

    /// A tiny solid-color JPEG; content is irrelevant, only the bytes are.
    private func makePhoto(size: CGSize = CGSize(width: 8, height: 8)) throws -> Data {
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.gray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return try #require(image.jpegData(compressionQuality: 0.7))
    }

    private func sentBody(
        exercises: [Exercise],
        photos: [Data],
        model: String = "test/model",
        description: String? = nil,
        muscle: Muscle? = nil
    ) throws -> [String: Any] {
        let payload = PhotoMatchRequestBuilder.payload(
            exercises: exercises,
            photos: photos,
            description: description,
            muscle: muscle
        )
        let data = try PhotoMatchRequestBuilder.requestBody(model: model, payload: payload)
        return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    /// The `exerciseId` enum the strict schema pins the answer to — the
    /// thing a muscle filter has to shrink for the narrowing to be real.
    private func schemaExerciseIds(_ body: [String: Any]) throws -> [String] {
        let responseFormat = try #require(body["response_format"] as? [String: Any])
        let jsonSchema = try #require(responseFormat["json_schema"] as? [String: Any])
        let schema = try #require(jsonSchema["schema"] as? [String: Any])
        let properties = try #require(schema["properties"] as? [String: Any])
        let matches = try #require(properties["matches"] as? [String: Any])
        let items = try #require(matches["items"] as? [String: Any])
        let itemProperties = try #require(items["properties"] as? [String: Any])
        let exerciseId = try #require(itemProperties["exerciseId"] as? [String: Any])
        return try #require(exerciseId["enum"] as? [String])
    }

    private func textPart(_ body: [String: Any]) throws -> String {
        let content = try userContent(body)
        return try #require(content.first?["text"] as? String)
    }

    private func userContent(_ body: [String: Any]) throws -> [[String: Any]] {
        let messages = try #require(body["messages"] as? [[String: Any]])
        #expect(messages.count == 2)
        #expect(messages.first?["role"] as? String == "system")
        let user = try #require(messages.last)
        #expect(user["role"] as? String == "user")
        return try #require(user["content"] as? [[String: Any]])
    }

    // MARK: - Payload

    @Test func payloadCarriesIdsNamesEquipmentAndMusclesInIdOrder() {
        let payload = PhotoMatchRequestBuilder.payload(exercises: makeExercises(), photos: [])

        #expect(payload.catalog.map(\.id) == ["bench-press", "custom-row", "squat"])
        #expect(payload.catalog.map(\.name) == ["Barbell Bench Press", "My Row", "Barbell Full Squat"])
        #expect(payload.catalog.map(\.equipment) == ["barbell", nil, "barbell"])
        #expect(payload.catalog.last?.primaryMuscles == ["quads", "glutes"])
    }

    @Test func payloadCapsPhotosAtTheDocumentedMaximum() throws {
        let photo = try makePhoto()
        let payload = PhotoMatchRequestBuilder.payload(
            exercises: makeExercises(),
            photos: Array(repeating: photo, count: 5)
        )

        #expect(payload.photos.count == PhotoMatchRequestBuilder.maxPhotos)
    }

    // MARK: - Message shape

    @Test func userMessageIsOneTextPartFollowedByOneImagePartPerPhoto() throws {
        let photos = [try makePhoto(), try makePhoto(size: CGSize(width: 12, height: 6))]
        let content = try userContent(try sentBody(exercises: makeExercises(), photos: photos))

        #expect(content.count == 3)
        #expect(content.first?["type"] as? String == "text")
        #expect(content.dropFirst().allSatisfy { $0["type"] as? String == "image_url" })

        for part in content.dropFirst() {
            let image = try #require(part["image_url"] as? [String: Any])
            let url = try #require(image["url"] as? String)
            #expect(url.hasPrefix("data:image/jpeg;base64,"))
        }
    }

    @Test func textPartListsEveryCatalogEntryWithNameAndMuscles() throws {
        let content = try userContent(try sentBody(exercises: makeExercises(), photos: [try makePhoto()]))
        let text = try #require(content.first?["text"] as? String)

        #expect(text.contains("\"id\":\"bench-press\""))
        #expect(text.contains("\"name\":\"Barbell Bench Press\""))
        #expect(text.contains("\"equipment\":\"barbell\""))
        #expect(text.contains("\"primaryMuscles\":[\"chest\"]"))
        // Custom exercises travel too, even without equipment metadata.
        #expect(text.contains("\"id\":\"custom-row\""))
    }

    @Test func catalogListingSendsCanonicalNamesNotTranslations() throws {
        // The model reasons over the English dataset vocabulary, so the
        // listing must be identical on a Spanish device. Localizing it here
        // would degrade matches for Spanish users only.
        let exercises = makeExercises()
        exercises[1].nameTranslations = ["es": "Press de Banca con Barra"]

        let payload = PhotoMatchRequestBuilder.payload(exercises: exercises, photos: [])
        let text = try textPart(try sentBody(exercises: exercises, photos: [try makePhoto()]))

        #expect(payload.catalog.first?.name == "Barbell Bench Press")
        #expect(text.contains("\"name\":\"Barbell Bench Press\""))
        #expect(!text.contains("Press de Banca con Barra"))
    }

    // MARK: - Main-muscle narrowing

    @Test func mainMuscleNarrowsBothTheCatalogListingAndTheSchemaEnum() throws {
        let body = try sentBody(exercises: makeExercises(), photos: [try makePhoto()], muscle: .chest)
        let text = try textPart(body)

        #expect(text.contains("\"id\":\"bench-press\""))
        #expect(!text.contains("\"id\":\"squat\""))
        #expect(!text.contains("\"id\":\"custom-row\""))
        #expect(text.contains("filtered to it): chest"))

        let ids = try schemaExerciseIds(body)
        #expect(ids == ["bench-press"])
    }

    /// The filter is a `contains`, not a first-muscle check: squat lists
    /// quads before glutes.
    @Test func mainMuscleMatchesAnyPrimaryMuscleNotJustTheFirst() {
        let payload = PhotoMatchRequestBuilder.payload(
            exercises: makeExercises(), photos: [], muscle: .glutes
        )

        #expect(payload.catalog.map(\.id) == ["squat"])
        #expect(payload.muscle == .glutes)
    }

    @Test func secondaryMusclesDoNotSatisfyTheFilter() throws {
        // Triceps and hamstrings appear only as secondary targets here.
        let body = try sentBody(exercises: makeExercises(), photos: [try makePhoto()], muscle: .triceps)
        let text = try textPart(body)

        #expect(!text.contains("\"id\":\"bench-press\""))
        let ids = try schemaExerciseIds(body)
        #expect(ids.isEmpty)
    }

    @Test func withoutAMainMuscleTheFullCatalogIsSent() throws {
        let body = try sentBody(exercises: makeExercises(), photos: [try makePhoto()])
        let text = try textPart(body)

        let ids = try schemaExerciseIds(body)
        #expect(ids == ["bench-press", "custom-row", "squat"])
        #expect(!text.contains("Main muscle stated by the user"))
    }

    // MARK: - User description

    @Test func descriptionTravelsAsALabeledLineOutsideTheCatalogJSON() throws {
        let description = "seat pushes forward, handles at chest height"
        let payload = PhotoMatchRequestBuilder.payload(
            exercises: makeExercises(), photos: [try makePhoto()], description: description
        )
        let data = try PhotoMatchRequestBuilder.requestBody(model: "test/model", payload: payload)
        let body = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let text = try textPart(body)

        #expect(payload.userDescription == description)
        #expect(text.contains("User description of the equipment or exercise: \(description)"))

        // The hint is prose beside the listing, never a catalog field.
        let catalogJSON = String(decoding: try JSONEncoder().encode(payload.catalog), as: UTF8.self)
        #expect(!catalogJSON.contains(description))
    }

    @Test func blankDescriptionIsDroppedEntirely() throws {
        #expect(PhotoMatchRequestBuilder.normalizedDescription(nil) == nil)
        #expect(PhotoMatchRequestBuilder.normalizedDescription("") == nil)
        #expect(PhotoMatchRequestBuilder.normalizedDescription("  \n ") == nil)
        #expect(PhotoMatchRequestBuilder.normalizedDescription("  cable stack ") == "cable stack")

        let text = try textPart(
            try sentBody(exercises: makeExercises(), photos: [try makePhoto()], description: "   ")
        )
        #expect(!text.contains("User description"))
    }

    @Test func overlongDescriptionIsCappedAtTheDocumentedLength() throws {
        let cap = PhotoMatchRequestBuilder.maxDescriptionLength
        let long = String(repeating: "x", count: cap - 5) + "CUTHERE"
        let text = try textPart(
            try sentBody(exercises: makeExercises(), photos: [try makePhoto()], description: long)
        )

        #expect(text.contains(String(long.prefix(cap))))
        #expect(!text.contains("CUTHERE"))
    }

    @Test func modelIsForwardedVerbatim() throws {
        let body = try sentBody(exercises: makeExercises(), photos: [try makePhoto()], model: "vendor/vision-1")

        #expect(body["model"] as? String == "vendor/vision-1")
    }

    /// The photo client resolves the same model preference as suggestions,
    /// so the override and its blank fallback are shared behavior.
    @Test func modelOverrideIsHonoredAndBlankOverrideFallsBackToDefault() throws {
        let suiteName = "PhotoMatchRequestBuilderTests-model"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("vendor/vision-override", forKey: OpenRouterSuggestionService.modelOverrideDefaultsKey)
        #expect(OpenRouterPhotoMatchService(defaults: defaults).model == "vendor/vision-override")

        defaults.set("   ", forKey: OpenRouterSuggestionService.modelOverrideDefaultsKey)
        #expect(OpenRouterPhotoMatchService(defaults: defaults).model == OpenRouterSuggestionService.defaultModel)
    }

    // MARK: - Response schema

    @Test func schemaIsStrictAndConstrainsIdsToTheCatalogSent() throws {
        let body = try sentBody(exercises: makeExercises(), photos: [try makePhoto()])

        let responseFormat = try #require(body["response_format"] as? [String: Any])
        #expect(responseFormat["type"] as? String == "json_schema")
        let jsonSchema = try #require(responseFormat["json_schema"] as? [String: Any])
        #expect(jsonSchema["name"] as? String == PhotoMatchRequestBuilder.schemaName)
        #expect(jsonSchema["strict"] as? Bool == true)

        let schema = try #require(jsonSchema["schema"] as? [String: Any])
        let properties = try #require(schema["properties"] as? [String: Any])
        let matches = try #require(properties["matches"] as? [String: Any])
        #expect(matches["maxItems"] as? Int == PhotoMatchRequestBuilder.maxMatches)

        let items = try #require(matches["items"] as? [String: Any])
        let itemProperties = try #require(items["properties"] as? [String: Any])
        let exerciseId = try #require(itemProperties["exerciseId"] as? [String: Any])
        #expect(exerciseId["enum"] as? [String] == ["bench-press", "custom-row", "squat"])
        let confidence = try #require(itemProperties["confidence"] as? [String: Any])
        #expect(confidence["enum"] as? [String] == ["high", "medium", "low"])
    }

    // MARK: - Preprocessing

    @Test func downscalingBoundsTheLongestEdgeAndPreservesAspectRatio() {
        let large = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 1500)).image { _ in }
        let scaled = PhotoPreprocessor.downscaled(large)

        #expect(scaled.size.width == PhotoPreprocessor.maxDimension)
        #expect(scaled.size.height == PhotoPreprocessor.maxDimension / 2)
    }

    @Test func downscalingLeavesSmallImagesUntouched() {
        let small = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 100)).image { _ in }
        let scaled = PhotoPreprocessor.downscaled(small)

        #expect(scaled.size == small.size)
    }

    @Test func dataURLEncodesJPEGBytesAsBase64() throws {
        let photo = try makePhoto()
        let url = PhotoPreprocessor.dataURL(forJPEG: photo)

        let prefix = "data:image/jpeg;base64,"
        #expect(url.hasPrefix(prefix))
        #expect(Data(base64Encoded: String(url.dropFirst(prefix.count))) == photo)
    }
}
