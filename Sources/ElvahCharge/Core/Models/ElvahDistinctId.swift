// Copyright elvah. All rights reserved.

import Foundation

/// A unique identifier for Elvah distinct IDs.
///
/// `ElvahDistinctId` generates cryptographically secure random strings with the prefix `evdid_`
/// followed by a Base62-encoded random string. This ensures uniqueness and readability while
/// maintaining security for tracking and identification purposes.
package struct ElvahDistinctId: Codable {
    /// The raw string value of the distinct ID.
    package var rawValue: String

    /// Creates a new distinct ID with the specified raw value.
    ///
    /// - Parameter rawValue: The raw string value for the distinct ID.
    package init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Generates a new cryptographically secure distinct ID.
    ///
    /// Creates a random Base62 string of the specified length, prefixed with "evdid_".
    /// Uses `SystemRandomNumberGenerator` for cryptographic security.
    ///
    /// - Parameter length: The length of the random portion (default: 32 characters).
    /// - Returns: A new `ElvahDistinctId` instance with a unique identifier.
    package static func generate(length: Int = 32) -> ElvahDistinctId {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
        var generator = SystemRandomNumberGenerator()

        let randomString = String((0 ..< length).compactMap { _ in
            charset.randomElement(using: &generator)
        })

        return ElvahDistinctId(rawValue: "evdid_\(randomString)")
    }

    package func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    package init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodedString = try container.decode(String.self)
        
        // Validate that the string has the expected prefix and minimum length
        guard decodedString.hasPrefix("evdid_") else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "ElvahDistinctId must start with 'evdid_' prefix"
                )
            )
        }
        
        // Validate length
        guard decodedString.count == 32 + 6 else { // "evdid_" (6 chars) + base62 code (32 chars)
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "ElvahDistinctId is too short, expected at least 8 characters"
                )
            )
        }
        
        rawValue = decodedString
    }
}
