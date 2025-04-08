// Copyright © elvah. All rights reserved.

import Foundation

package func logCommonNetworkError(_ error: any Error, name: String? = nil) {
	let prefix = if let name {
		"[\(name)] "
	} else {
		"[Network] "
	}

	switch error {
	case let error as NetworkError.Client:
		Elvah.logger.error("\(prefix)\(error.localizedDescription) ")
	default:
		Elvah.logger.error("\(prefix)An unknown error occurred: »\(error.localizedDescription)«")
	}
}
