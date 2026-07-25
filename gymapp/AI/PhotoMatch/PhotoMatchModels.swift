//
//  PhotoMatchModels.swift
//  gymapp
//
//  Wire types of the photo exercise-match contract.
//  PhotoMatchRequestPayload is what the request builder turns into the
//  multimodal user message (catalog listing as a text part, photos as
//  image parts); PhotoMatchResult is the structured-output JSON the model
//  must return. Field names and the Muscle/Equipment raw values are the
//  stable serialization keys — renaming them breaks the API contract.
//

import Foundation

/// Everything the model needs to name the exercises in a photo: the local
/// catalog (ids plus the human-readable metadata it must match against),
/// the already-downscaled JPEG photos, and the optional hints the user
/// attached to this request.
struct PhotoMatchRequestPayload: Equatable, Sendable {
    /// One catalog exercise as the model sees it. Names are included (unlike
    /// the suggestion payload) because vision matching is name-driven.
    struct CatalogEntry: Codable, Equatable, Sendable {
        let id: String
        /// English catalog name — the dataset ships no translated names.
        let name: String
        /// Equipment raw value (e.g. "barbell"); omitted when unknown.
        let equipment: String?
        /// Muscle raw values (e.g. "chest", "lower_back").
        let primaryMuscles: [String]
    }

    /// The local catalog ordered by id so payloads are deterministic —
    /// every exercise when `muscle` is nil, the primary-muscle subset when
    /// it is set. The response schema's id enum is built from this list, so
    /// narrowing it narrows what the model can answer.
    let catalog: [CatalogEntry]
    /// JPEG-encoded photos, already downscaled by `PhotoPreprocessor`.
    /// Never persisted: they live only for the duration of one request.
    let photos: [Data]
    /// Optional free-text hint from the user, already trimmed and capped by
    /// `PhotoMatchRequestBuilder.payload`. Transient like the photos.
    var userDescription: String?
    /// Optional main muscle the user picked; the catalog above is already
    /// filtered by it. Carried so the prompt can say why the list is short.
    var muscle: Muscle?
}

/// How sure the model is about a match. A closed enum so the UI can badge
/// results without parsing free text.
enum PhotoMatchConfidence: String, Codable, CaseIterable, Sendable {
    case high
    case medium
    case low

    var displayName: String {
        switch self {
        case .high: String(localized: "High match")
        case .medium: String(localized: "Possible match")
        case .low: String(localized: "Weak match")
        }
    }
}

/// One matched catalog exercise. Muscle metadata is intentionally absent —
/// it is always resolved from the local Exercise record.
struct PhotoMatch: Codable, Equatable, Sendable {
    let exerciseId: String
    let confidence: PhotoMatchConfidence
}

/// The structured output the model returns: matches best-first. An empty
/// list is a valid "nothing recognized" answer, not an error.
struct PhotoMatchResult: Codable, Equatable, Sendable {
    var matches: [PhotoMatch]
}
