// Copyright © elvah. All rights reserved.

import SwiftUI

/// A type indicating size by defining a set of size classes.
package enum Size {
  /// 64
  case XXXXXL
  /// 56
  case XXXXL
  /// 48
  case XXXL
  /// 40
  case XXL
  /// 32
  case XL
  /// 24
  case L
  /// 16
  case M
  /// 12
  case S
  /// 8
  case XS
  /// 4
  case XXS
  /// 2
  case XXXS

  /// Zero size. This is useful for use in `VerticalSpacer` or `HorizontalSpacer`.
  case zero

  /// The size value of the given size classes.
  package var size: CGFloat {
    switch self {
    case .XXXXXL: 64
    case .XXXXL: 56
    case .XXXL: 48
    case .XXL: 40
    case .XL: 32
    case .L: 24
    case .M: 16
    case .S: 12
    case .XS: 8
    case .XXS: 4
    case .XXXS: 2
    case .zero: 0
    }
  }
}
