// Copyright © elvah. All rights reserved.

import Foundation
import OSLog

package extension Logger {
	func parseError(for name: String, value: String?) {
		error("Unable to parse \(name): \(value ?? "[nil]")")
	}

	func parseError<K, V>(in object: K, for keyPath: KeyPath<K, V>) {
		error(
			"Unable to parse \(String(reflecting: keyPath)): \(String(reflecting: object[keyPath: keyPath]))"
		)
	}
}
