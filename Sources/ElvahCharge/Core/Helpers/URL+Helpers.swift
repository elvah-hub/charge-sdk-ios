// Copyright © elvah. All rights reserved.

import Foundation

package extension URL {
	/// Returns a copy of the url that properly encodes evse ids.
	/// - Returns: A percent encoded url that also works for evse ids.
	func properlyEncoded() -> URL? {
		guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
			return self
		}

		// Replace encoding (to fix evseIds that contain a "+")
		components.percentEncodedQuery = components
			.percentEncodedQuery?
			.replacingOccurrences(of: "+", with: "%2B")

		// Return the encoded url
		return components.url
	}
}
