// Copyright © elvah. All rights reserved.

import SwiftUI

/// Convenience helpers to use ``Size`` with numeric spacing parameters
/// like `VStack(spacing:)` and `HStack(spacing:)`.
///
/// Example:
/// ```swift
/// HStack(spacing: .size(.XXS)) { /* ... */ }
/// VStack(spacing: .size(.M)) { /* ... */ }
/// ```
package extension CGFloat {
  /// Returns the concrete spacing value for the given ``Size``.
  /// - Parameter size: The abstract size value.
  /// - Returns: The concrete `CGFloat` spacing.
  static func size(_ size: Size) -> CGFloat { size.size }
}

package extension Double {
  /// Returns the concrete spacing value for the given ``Size``.
  /// - Parameter size: The abstract size value.
  /// - Returns: The concrete `Double` spacing.
  static func size(_ size: Size) -> Double { Double(size.size) }
}
