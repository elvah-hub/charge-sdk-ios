// Copyright © elvah. All rights reserved.

import Foundation

package extension String {
  /// Returns true if `pattern` is a case-insensitive subsequence of this string.
  ///
  /// The check is performed by scanning the lowercase "haystack" for the characters of the
  /// lowercase `pattern` in order (not necessarily contiguously). An empty `pattern` returns `true`.
  func fuzzyMatches(_ pattern: String) -> Bool {
    let haystack = lowercased()
    let needle = pattern.lowercased()

    guard needle.isEmpty == false else {
      return true
    }

    var needleIndex = needle.startIndex
    for character in haystack where character == needle[needleIndex] {
      needleIndex = needle.index(after: needleIndex)
      if needleIndex == needle.endIndex {
        return true
      }
    }
    return false
  }
}
