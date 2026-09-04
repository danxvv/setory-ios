//
//  ChatCompletionResponse.swift
//  gymapp
//
//  The part of OpenRouter's chat-completion contract every AI feature
//  shares: HTTP status → AIError mapping, envelope decoding, and
//  OpenRouter's habit of embedding provider errors inside a 200 response.
//  Feature-specific validation stays in the per-feature parsers.
//

import Foundation

enum ChatCompletionResponse {
    /// Non-2xx statuses each map to a typed error; the response body's
    /// error object adds nothing the UI needs beyond the status itself.
    static func error(forStatusCode statusCode: Int) -> AIError? {
        switch statusCode {
        case 200..<300: nil
        case 401: .invalidKey
        case 402: .insufficientCredits
        case 429: .rateLimited
        default: .badResponse
        }
    }

    /// The assistant message's content string, or a typed error for any
    /// failure shape (bad status, undecodable envelope, embedded provider
    /// error, missing content).
    static func content(from data: Data, statusCode: Int) throws -> String {
        if let failure = error(forStatusCode: statusCode) {
            throw failure
        }

        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
              envelope.error == nil,
              let choice = envelope.choices?.first
        else { throw AIError.badResponse }

        // OpenRouter can embed a provider error inside a 200 response.
        guard choice.error == nil, choice.finishReason != "error" else {
            throw AIError.badResponse
        }

        guard let content = choice.message?.content else {
            throw AIError.badResponse
        }
        return content
    }

    /// Decodes the structured-output JSON carried in the message content.
    /// Any decoding failure is `badResponse` — the model returned something
    /// the schema promised it wouldn't.
    static func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        statusCode: Int
    ) throws -> T {
        let content = try content(from: data, statusCode: statusCode)
        guard let decoded = try? JSONDecoder().decode(
            type,
            from: Data(content.trimmingCharacters(in: .whitespacesAndNewlines).utf8)
        ) else { throw AIError.badResponse }
        return decoded
    }

    /// The slice of the chat-completion response the app reads.
    /// `finish_reason` and the error objects capture OpenRouter's
    /// embedded-error shape.
    private struct Envelope: Decodable {
        struct ErrorObject: Decodable {}

        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }

            let message: Message?
            let finishReason: String?
            let error: ErrorObject?

            enum CodingKeys: String, CodingKey {
                case message
                case error
                case finishReason = "finish_reason"
            }
        }

        let choices: [Choice]?
        let error: ErrorObject?
    }
}
