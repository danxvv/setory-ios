//
//  RequestBodyFixtureTests.swift
//  gymappTests
//
//  Golden-file guard on the two OpenRouter request bodies. These exist for
//  the app-architecture restructure: the transport is being collapsed into a
//  single shared client, and the one thing that must not move is the bytes on
//  the wire. Any diff here means the REST contract changed — model, system
//  prompt, message shape, payload encoding, or the strict response schema.
//
//  Inputs are deliberately date-free (no sessions) so the goldens can't drift
//  with the host's time zone; history summarization is covered separately in
//  SuggestionPromptBuilderTests.
//
//  Goldens live next to this file and are located through #filePath rather
//  than the test bundle, so no resource-copy build phase is involved. Set
//  UPDATE_REQUEST_FIXTURES=1 in the environment to rewrite them after an
//  intentional contract change.
//

import Foundation
import Testing
@testable import gymapp

struct RequestBodyFixtureTests {

    // MARK: - Fixed inputs

    /// Three exercises spanning both categories, an equipment value, and
    /// multi-muscle primary/secondary metadata.
    private func makeExercises() -> [Exercise] {
        [
            Exercise(
                id: "bench-press", name: "Bench Press", category: .strength,
                primaryMuscles: [.chest], secondaryMuscles: [.triceps, .shoulders],
                equipment: .barbell
            ),
            Exercise(
                id: "squat", name: "Squat", category: .strength,
                primaryMuscles: [.quads, .glutes], secondaryMuscles: [.hamstrings, .lowerBack],
                equipment: .olympicBarbell
            ),
            Exercise(
                id: "treadmill-run", name: "Treadmill Run", category: .cardio,
                primaryMuscles: [.fullBody]
            ),
        ]
    }

    /// Fixed bytes, not encoded images: the builder base64s whatever it is
    /// handed, so literal bytes keep the golden stable without invoking JPEG
    /// encoding (which is not bit-reproducible across OS versions).
    private var photos: [Data] {
        [Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]), Data([0x01, 0x02, 0x03])]
    }

    // MARK: - Golden files

    private func fixtureURL(_ name: String, file: StaticString = #filePath) -> URL {
        URL(fileURLWithPath: String(describing: file))
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
            .appendingPathComponent(name)
    }

    /// Compares `data` against the golden, or writes the golden when it is
    /// missing (first run) or when UPDATE_REQUEST_FIXTURES is set.
    private func expectMatchesGolden(_ data: Data, _ name: String) throws {
        let url = fixtureURL(name)
        let shouldWrite = ProcessInfo.processInfo.environment["UPDATE_REQUEST_FIXTURES"] == "1"
            || !FileManager.default.fileExists(atPath: url.path)

        if shouldWrite {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
            Issue.record("Wrote request-body golden \(name); re-run to compare against it.")
            return
        }

        let golden = try Data(contentsOf: url)
        guard data == golden else {
            // Dump the actual body so the diff is inspectable.
            let actual = url.deletingPathExtension().appendingPathExtension("actual.json")
            try? data.write(to: actual, options: .atomic)
            Issue.record("""
                Request body no longer matches \(name).
                Golden: \(golden.count) bytes · actual: \(data.count) bytes.
                Actual body written to \(actual.path).
                If this change is intentional, re-run with UPDATE_REQUEST_FIXTURES=1.
                """)
            return
        }
    }

    // MARK: - Tests

    @Test func suggestionRequestBodyMatchesGolden() throws {
        let payload = SuggestionPromptBuilder.payload(
            exercises: makeExercises(), sessions: [], goal: "focus legs, 45 minutes"
        )
        let data = try SuggestionPromptBuilder.requestBody(
            model: "openai/gpt-5.4-mini", payload: payload, languageCode: "en"
        )
        try expectMatchesGolden(data, "suggestion-request-body.json")
    }

    @Test func photoMatchRequestBodyMatchesGolden() throws {
        let payload = PhotoMatchRequestBuilder.payload(
            exercises: makeExercises(),
            photos: photos,
            description: "  a leg press machine with a blue seat  ",
            muscle: nil
        )
        let data = try PhotoMatchRequestBuilder.requestBody(
            model: "openai/gpt-5.4-mini", payload: payload
        )
        try expectMatchesGolden(data, "photo-match-request-body.json")
    }

    /// The muscle-filtered variant takes a different path through the prompt
    /// (extra labeled line) and a narrower id enum, so it gets its own golden.
    @Test func photoMatchRequestBodyWithMuscleHintMatchesGolden() throws {
        let payload = PhotoMatchRequestBuilder.payload(
            exercises: makeExercises(),
            photos: photos,
            description: nil,
            muscle: .quads
        )
        let data = try PhotoMatchRequestBuilder.requestBody(
            model: "openai/gpt-5.4-mini", payload: payload
        )
        try expectMatchesGolden(data, "photo-match-request-body-muscle.json")
    }

    /// Byte-identical output for identical inputs is the property the goldens
    /// rely on; assert it directly so a nondeterminism regression is not
    /// mistaken for a contract change.
    @Test func repeatedBuildsAreByteIdentical() throws {
        let exercises = makeExercises()
        let first = try SuggestionPromptBuilder.requestBody(
            model: "m", payload: SuggestionPromptBuilder.payload(exercises: exercises, sessions: [], goal: "legs"),
            languageCode: "en"
        )
        let second = try SuggestionPromptBuilder.requestBody(
            model: "m", payload: SuggestionPromptBuilder.payload(exercises: exercises.shuffled(), sessions: [], goal: "legs"),
            languageCode: "en"
        )
        #expect(first == second)

        let photoFirst = try PhotoMatchRequestBuilder.requestBody(
            model: "m", payload: PhotoMatchRequestBuilder.payload(exercises: exercises, photos: photos)
        )
        let photoSecond = try PhotoMatchRequestBuilder.requestBody(
            model: "m", payload: PhotoMatchRequestBuilder.payload(exercises: exercises.shuffled(), photos: photos)
        )
        #expect(photoFirst == photoSecond)
    }
}
