// Copyright © elvah. All rights reserved.

import SwiftUI

// MARK: - Router

package protocol BaseRouter: ObservableObject {
	@MainActor func reset()
}
