//
//  PhotoMatchRequestBuilder.swift
//  gymapp
//
//  Builds the OpenRouter chat-completion request for a photo exercise
//  match: system prompt, a multimodal user message (catalog listing as one
//  text part, one image part per photo), and the strict response schema
//  whose exerciseId enum pins the answer to real catalog ids. Pure statics
//  over already-fetched models, so unit tests need no networking.
//

import Foundation

enum PhotoMatchRequestBuilder {
    /// Hard cap on photos per request; also enforced by the capture UI.
    static let maxPhotos = 3
    /// Upper bound on returned matches — a longer list is noise, not signal.
    static let maxMatches = 10
    /// Structured-output schema name required by OpenRouter.
    static let schemaName = "photo_exercise_matches"

    // MARK: - System prompt

    static var systemPrompt: String {
        """
        You are an expert strength coach identifying gym exercises from \
        photos. The user message contains a JSON exercise catalog followed \
        by one or more photos of gym equipment, a machine's instruction \
        placard, or someone performing an exercise.

        Rules:
        - Identify which catalog exercises the photos correspond to.
        - Answer only with exercise IDs from the catalog; never invent IDs \
        or exercises.
        - Return at most \(maxMatches) matches, best match first, each ID \
        at most once.
        - Prefer the exercises whose equipment and target muscles fit the \
        photographed equipment; when several catalog variants fit the same \
        machine, list them all ordered by likelihood.
        - Set confidence to "high" only when the equipment is unmistakable, \
        "medium" when the equipment type is clear but the exact variant is \
        not, and "low" for a guess.
        - If the photos show nothing recognizable as a catalog exercise, \
        return an empty match list.
        - Respond only with JSON matching the provided schema.
        """
    }

    // MARK: - User payload

    /// Snapshot of the local store for the user message: the entire catalog
    /// (custom exercises included), ordered by id so payloads are
    /// deterministic. Photos beyond `maxPhotos` are dropped.
    static func payload(exercises: [Exercise], photos: [Data]) -> PhotoMatchRequestPayload {
        let catalog = exercises
            .sorted { $0.id < $1.id }
            .map {
                PhotoMatchRequestPayload.CatalogEntry(
                    id: $0.id,
                    name: $0.name,
                    equipment: $0.equipmentRaw,
                    primaryMuscles: $0.primaryMuscleRaws
                )
            }
        return PhotoMatchRequestPayload(catalog: catalog, photos: Array(photos.prefix(maxPhotos)))
    }

    // MARK: - Response schema

    /// Strict JSON schema for `response_format`; `exerciseIds` becomes the
    /// enum constraining every match to the catalog that was sent.
    static func responseSchema(exerciseIds: [String]) -> [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "required": ["matches"],
            "properties": [
                "matches": [
                    "type": "array",
                    // No minItems: "nothing recognized" is a valid answer.
                    "maxItems": maxMatches,
                    "items": [
                        "type": "object",
                        "additionalProperties": false,
                        "required": ["exerciseId", "confidence"],
                        "properties": [
                            "exerciseId": ["type": "string", "enum": exerciseIds],
                            "confidence": [
                                "type": "string",
                                "enum": PhotoMatchConfidence.allCases.map(\.rawValue),
                            ],
                        ],
                    ],
                ],
            ],
        ]
    }

    // MARK: - Full request body

    /// The complete chat-completions body. The user message is a content
    /// **array** (not a plain string like the suggestion request): one text
    /// part carrying the catalog JSON, then one `image_url` part per photo.
    static func requestBody(model: String, payload: PhotoMatchRequestPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let catalogJSON = String(decoding: try encoder.encode(payload.catalog), as: UTF8.self)

        var content: [[String: Any]] = [[
            "type": "text",
            "text": """
            Exercise catalog (JSON array of {id, name, equipment, primaryMuscles}):
            \(catalogJSON)

            Identify the catalog exercises shown in the following \
            \(payload.photos.count == 1 ? "photo" : "photos").
            """,
        ]]
        content += payload.photos.map { photo in
            [
                "type": "image_url",
                "image_url": ["url": PhotoPreprocessor.dataURL(forJPEG: photo)],
            ]
        }

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": content],
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": schemaName,
                    "strict": true,
                    "schema": responseSchema(exerciseIds: payload.catalog.map(\.id)),
                ],
            ],
        ]
        return try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
    }
}
