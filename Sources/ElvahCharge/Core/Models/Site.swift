// Copyright © elvah. All rights reserved.

import CoreLocation
import SwiftUI

/// Represents a place with charge points for electric cars.
public struct Site: Codable, Hashable, Identifiable, Sendable {
  /// Unique identification of the site.
  public var id: String

  /// The name of the site operator.
  public var operatorName: String?

  /// The geographic location of the site.
  public var location: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: locationLatitude, longitude: locationLongitude)
  }

  /// The latitude of the site's location.
  private var locationLatitude: Double

  /// The longitude of the site's location.
  private var locationLongitude: Double

  /// The postal address of the site, if available.
  public var address: Address?

  /// Current availability status of the site.
  ///
  /// - Important': Availability is currently not available.
  package var availability: Availability

  /// The most common power type at the site.
  public var prevalentPowerType: PowerType

  /// Opening hours information, if available.
  ///
  /// - Important': Opening hours are currently not available.
  package var openingHours: OpeningHours?

  @_spi(Debug) public init(
    id: String,
    location: CLLocationCoordinate2D,
    address: Address?,
    availability: Availability,
    prevalentPowerType: PowerType,
    openingHours: OpeningHours?,
    operatorName: String?,
  ) {
    self.id = id
    locationLatitude = location.latitude
    locationLongitude = location.longitude
    self.address = address
    self.availability = availability
    self.prevalentPowerType = prevalentPowerType
    self.openingHours = openingHours
    self.operatorName = operatorName
  }
}

public extension Site {
  /// Status values describing if a site is available, occupied, or malfunctioning.
  enum Availability: String, Codable, Hashable, CaseIterable, Sendable {
    /// Site has available charging points.
    case available = "AVAILABLE"

    /// At least one charge point at the site is malfunctioning.
    case malfunctioningStation = "MALFUNCTIONING_STATION"

    /// The site operator is experiencing a malfunction affecting the site.
    case malfunctioningOperator = "MALFUNCTIONING_OPERATOR"

    /// The site is completely nonfunctional and cannot be used.
    case nonfunctional = "NONFUNCTIONAL"

    /// All charge points at the site are currently in use.
    case occupied = "OCCUPIED"
  }

  /// Postal address details for a site.
  struct Address: Codable, Hashable, Sendable {
    /// City or locality name.
    public let locality: String?

    /// Postal or ZIP code.
    public let postalCode: String?

    /// Array of street address lines.
    public let streetAddress: [String]?

    @_spi(Debug) public init(
      locality: String? = nil,
      postalCode: String? = nil,
      streetAddress: [String]? = nil,
    ) {
      self.locality = locality
      self.postalCode = postalCode
      self.streetAddress = streetAddress
    }
  }

  /// Days of the week.
  enum Weekday: String, Codable, Hashable, CaseIterable, Sendable {
    case monday = "MONDAY"
    case tuesday = "TUESDAY"
    case wednesday = "WEDNESDAY"
    case thursday = "THURSDAY"
    case friday = "FRIDAY"
    case saturday = "SATURDAY"
    case sunday = "SUNDAY"

    /// Returns the localized name of the weekday.
    public var localizedName: String {
      let calendar = Calendar.current
      let weekdayIndex = switch self {
      case .sunday: 1
      case .monday: 2
      case .tuesday: 3
      case .wednesday: 4
      case .thursday: 5
      case .friday: 6
      case .saturday: 7
      }

      return calendar.weekdaySymbols[weekdayIndex - 1]
    }
  }

  /// Represents available open periods for a site.
  struct OpeningHours: Codable, Hashable, Sendable {
    /// Returns `true` if opening hours data is available.
    public var dataAvailable: Bool

    /// Array of open periods for each weekday.
    public var openPeriods: [OpenPeriod]

    @_spi(Debug) public init(dataAvailable: Bool, openPeriods: [Site.OpeningHours.OpenPeriod]) {
      self.dataAvailable = dataAvailable
      self.openPeriods = openPeriods
    }

    /// Represents a period in a day when the site is open.
    public struct OpenPeriod: Codable, Hashable, Sendable {
      /// The weekday for this open period.
      public let weekday: Weekday

      /// Opening time.
      public let opensAt: Time

      /// Closing time.
      public let closesAt: Time

      @_spi(Debug) public init(weekday: Weekday, opensAt: Time, closesAt: Time) {
        self.weekday = weekday
        self.opensAt = opensAt
        self.closesAt = closesAt
      }

      @_spi(Debug) public init?(dayOfWeek: String, opensAt: Time, closesAt: Time) {
        guard let weekday = Weekday(rawValue: dayOfWeek) else {
          return nil
        }

        self.weekday = weekday
        self.opensAt = opensAt
        self.closesAt = closesAt
      }

      /// The raw string value for the weekday.
      public var dayOfWeek: String {
        weekday.rawValue
      }

      /// A formatted string representing opening and closing hours.
      public var formattedHours: String {
        "\(opensAt.localizedTimeString) - \(closesAt.localizedTimeString)"
      }
    }
  }
}

public extension Site {
  /// Indicates if the site is open at the current time.
  var isCurrentlyOpen: Bool {
    isOpen(at: Date())
  }

  /// Returns `true` if the site is open at the given date and time.
  func isOpen(at date: Date) -> Bool {
    guard let openingHours, openingHours.dataAvailable else {
      return false
    }

    let calendar = Calendar.current
    let weekdayIndex = calendar.component(.weekday, from: date)
    let weekday = weekdayFromIndex(weekdayIndex)

    let todaysPeriods = openingHours.openPeriods.filter { period in
      period.weekday == weekday
    }

    guard !todaysPeriods.isEmpty else {
      return false
    }

    let currentTime = Time(date: date) ?? .zero

    return todaysPeriods.contains { period in
      currentTime >= period.opensAt && currentTime < period.closesAt
    }
  }

  /// The site's opening hours for today, if available.
  var todaysHours: OpeningHours.OpenPeriod? {
    hours(for: currentWeekday()).first
  }

  /// The site's opening periods for a specific weekday.
  func hours(for weekday: Weekday) -> [OpeningHours.OpenPeriod] {
    guard let openingHours, openingHours.dataAvailable else {
      return []
    }

    return openingHours.openPeriods.filter { period in
      period.weekday == weekday
    }
  }

  private func currentWeekday() -> Weekday {
    let calendar = Calendar.current
    let weekdayIndex = calendar.component(.weekday, from: Date())
    return weekdayFromIndex(weekdayIndex)
  }

  private func weekdayFromIndex(_ index: Int) -> Weekday {
    switch index {
    case 1: .sunday
    case 2: .monday
    case 3: .tuesday
    case 4: .wednesday
    case 5: .thursday
    case 6: .friday
    case 7: .saturday
    default: .monday
    }
  }
}

package extension Site {
  static var simulation: Site {
    Site(
      id: "Mock ID",
      location: CLLocationCoordinate2D(latitude: 51.03125, longitude: 4.41047),
      address: Site.Address(
        locality: "Berlin",
        postalCode: "12683",
        streetAddress: ["Köpenicker Straße 145"],
      ),
      availability: .available,
      prevalentPowerType: .dc,
      openingHours: OpeningHours(
        dataAvailable: true,
        openPeriods: [
          Site.OpeningHours.OpenPeriod(
            weekday: .monday,
            opensAt: Time(hour: 8, minute: 0)!,
            closesAt: Time(hour: 22, minute: 0)!,
          ),
        ],
      ),
      operatorName: "Lidl Köpenicker Straße",
    )
  }

  static var mock: Site {
    Site(
      id: "Mock ID",
      location: CLLocationCoordinate2D(latitude: 51.03125, longitude: 4.41047),
      address: Site.Address(
        locality: "Berlin",
        postalCode: "12683",
        streetAddress: ["Köpenicker Straße 145"],
      ),
      availability: .available,
      prevalentPowerType: .dc,
      openingHours: OpeningHours(
        dataAvailable: true,
        openPeriods: [
          Site.OpeningHours.OpenPeriod(
            weekday: .monday,
            opensAt: Time(hour: 8, minute: 0)!,
            closesAt: Time(hour: 22, minute: 0)!,
          ),
        ],
      ),
      operatorName: "Lidl Köpenicker Straße",
    )
  }
}
