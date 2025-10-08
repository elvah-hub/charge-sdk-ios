// Copyright © elvah. All rights reserved.

import Foundation

package extension Collection<String> {
  /// Largest common prefix across all strings (case-sensitive).
  func largestCommonPrefix() -> String {
    guard let first else {
      return ""
    }

    var prefix = first

    for string in dropFirst() {
      prefix = prefix.commonPrefix(with: string)
      if prefix.isEmpty {
        break
      }
    }
    return prefix
  }
}
