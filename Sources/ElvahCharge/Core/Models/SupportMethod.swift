// Copyright © elvah. All rights reserved.

import Foundation

/// Represents different methods through which users can seek support.
///
/// This enum provides a flexible way to configure support options, allowing users
/// to reach support via different communication channels such as phone, WhatsApp,
/// website, or email.
///
/// - Note: Each case includes the necessary information for that support method,
///   such as a phone number, email address, or URL.
package enum SupportMethod: Identifiable, Hashable, Sendable, Codable, Comparable {
  /// Support via a phone number.
  /// - Parameter: A `String` containing the phone number.
  case phone(String)

  /// Support via a website.
  /// - Parameter: A `URL` representing the support webpage.
  case website(URL)

  /// Support via an email address.
  /// - Parameter: A `String` containing the email address.
  case email(String)

  /// Support via WhatsApp.
  /// - Parameter: A `String` containing the WhatsApp number.
  case whatsApp(String)

  /// A unique identifier for the support method.
  package var id: String {
    switch self {
    case let .phone(number):
      "phone:\(number)"
    case let .whatsApp(number):
      "whatsApp:\(number)"
    case let .website(url):
      "website:\(url.absoluteString)"
    case let .email(address):
      "email:\(address)"
    }
  }

  package var sortKey: Int {
    switch self {
    case .phone:
      0
    case .website:
      1
    case .email:
      2
    case .whatsApp:
      3
    }
  }

  package var isPhoneOrUrl: Bool {
    if case .phone = self {
      return true
    }
    if case .website = self {
      return true
    }
    return false
  }

  package var isEmailOrWhatsApp: Bool {
    if case .email = self {
      return true
    }
    if case .whatsApp = self {
      return true
    }
    return false
  }

  package static func < (lhs: SupportMethod, rhs: SupportMethod) -> Bool {
    lhs.sortKey < rhs.sortKey
  }
}
