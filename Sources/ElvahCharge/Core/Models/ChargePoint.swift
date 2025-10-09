// Copyright © elvah. All rights reserved.

import SwiftUI

/// A type describing a charge point.
public struct ChargePoint: Identifiable, Hashable, Codable, Sendable {
  /// The identifier of the charge point.
  public var id: String { evseId }

  /// The identifier of the charge point.
  public var evseId: String

  /// The charge point's physical reference, if available.
  public var physicalReference: String?

  /// The maximum power of the charge point in kW.
  public var maxPowerInKw: Double

  /// The charge point's availability.
  ///
  /// - Important: Availability data is currently not available.
  package var availability: Availability

  /// The date at which the charge point's availability was last updated.
  ///
  /// - Important: Availability data is currently not available.
  package var availabilityUpdatedAt: Date

  /// The charge point's connectors.
  ///
  /// - Important: Connectors are currently not available.
  package var connectors: Set<ConnectorType>

  /// The charge point's speed.
  ///
  /// - Important: Speed data is currently not available.
  package var speed: Speed

  /// The charge point's power type.
  public var powerType: PowerType?

  @_spi(Debug) public init(
    evseId: String,
    physicalReference: String? = nil,
    maxPowerInKw: Double,
    availability: Availability,
    availabilityUpdatedAt: Date,
    connectors: Set<ConnectorType>,
    speed: Speed,
    powerType: PowerType?,
  ) {
    self.evseId = evseId
    self.physicalReference = physicalReference
    self.maxPowerInKw = maxPowerInKw
    self.availability = availability
    self.availabilityUpdatedAt = availabilityUpdatedAt
    self.connectors = connectors
    self.speed = speed
    self.powerType = powerType
  }
}

public extension ChargePoint {
  /// The charge point's speed.
  enum Speed: String, Hashable, Codable, Sendable {
    case unknown = "UNKNOWN"
    case slow = "SLOW"
    case medium = "MEDIUM"
    case fast = "FAST"
    case hyper = "HYPER"

    private var comparisonValue: Int {
      switch self {
      case .unknown:
        0
      case .slow:
        1
      case .medium:
        2
      case .fast:
        3
      case .hyper:
        4
      }
    }

    public static func < (lhs: Speed, rhs: Speed) -> Bool {
      lhs.comparisonValue < rhs.comparisonValue
    }

    public static func <= (lhs: Speed, rhs: Speed) -> Bool {
      lhs.comparisonValue <= rhs.comparisonValue
    }

    public static func >= (lhs: Speed, rhs: Speed) -> Bool {
      lhs.comparisonValue >= rhs.comparisonValue
    }

    public static func > (lhs: Speed, rhs: Speed) -> Bool {
      lhs.comparisonValue > rhs.comparisonValue
    }
  }

  /// The charge point's availability.
  enum Availability: String, Hashable, Codable, Sendable {
    case available = "AVAILABLE"
    case unavailable = "UNAVAILABLE"
    case outOfService = "OUT_OF_SERVICE"
    case unknown = "UNKNOWN"
  }
}

// MARK: - Helpers

public extension ChargePoint {
  /// Returns `true` if the charge point is available for use.
  var isAvailable: Bool {
    availability == .available
  }

  /// Returns `true` if the charge point is not available for use.
  var isUnavailable: Bool {
    availability != .available
  }

  /// The maximum power formatted as a string with "kW" suffix.
  @available(iOS 16.0, *) var maxPowerInKWFormatted: String {
    maxPowerInKw.formatted(.number.precision(.fractionLength(0))) + " kW"
  }

  /// The last 4 characters of the EVSE identifier.
  var evseIdSuffix: String {
    String(evseId.suffix(4))
  }

  /// The maximum power of the charge point in kW, formatted to be used in a user-facing string.
  var maxPowerInKwFormatted: String {
    "\(Int(maxPowerInKw))"
  }

  /// Returns a flag determining if the chargePoint's availability is set to `unavailable`.
  var isOccupied: Bool {
    availability == .unavailable
  }

  /// Returns a flag determining if the chargePoint's availability is set to `outOfService`.
  var isOutOfService: Bool {
    availability == .outOfService
  }

  var availabilityForegroundColor: Color {
    if isOccupied {
      return .yellow
    }

    if isOutOfService {
      return .red
    }

    return .onSuccess
  }

  var availabilityBackgroundColor: Color {
    if isOccupied {
      return .yellow.opacity(0.1)
    }

    if isOutOfService {
      return .red.opacity(0.1)
    }

    return .success
  }
}

// MARK: - Mock Data

package extension ChargePoint {
  static func mockLoading(evseId: String) -> ChargePoint {
    ChargePoint(
      evseId: evseId,
      physicalReference: nil,
      maxPowerInKw: 150,
      availability: .available,
      availabilityUpdatedAt: Date().addingTimeInterval(-100_000),
      connectors: [.chademo],
      speed: .hyper,
      powerType: .ac,
    )
  }

  /// Creates a simulated charge point with the specified evseId and randomized properties.
  /// - Parameter evseId: The evse id for the charge point
  /// - Returns: A charge point with realistic but varied specifications
  static func simulation(evseId: String, largestCommonPrefix: String? = nil) -> ChargePoint {
    let powers = [22.0, 50.0, 75.0, 150.0, 250.0, 350.0]
    let maxPower = powers.randomElement()!

    let speed: Speed = switch maxPower {
    case 0 ..< 25: .slow
    case 25 ..< 75: .medium
    case 75 ..< 150: .fast
    default: .hyper
    }

    let powerType: PowerType = maxPower > 22 ? .dc : .ac

    var physicalReference: String? {
      if let largestCommonPrefix, largestCommonPrefix.isEmpty == false {
        return String(evseId.dropFirst(largestCommonPrefix.count))
      }
      return nil
    }

    return ChargePoint(
      evseId: evseId,
      physicalReference: physicalReference,
      maxPowerInKw: maxPower,
      availability: .available,
      availabilityUpdatedAt: Date().addingTimeInterval(-Double.random(in: 0 ... 86400)),
      connectors: [.combo],
      speed: speed,
      powerType: powerType,
    )
  }

  static let mockAvailable = ChargePoint(
    evseId: "DE*SIM*1234",
    physicalReference: "1234",
    maxPowerInKw: 150,
    availability: .available,
    availabilityUpdatedAt: Date().addingTimeInterval(-100_000),
    connectors: [.chademo],
    speed: .hyper,
    powerType: .dc,
  )

  static let mockUnavailable = ChargePoint(
    evseId: "DE*SIM*1235",
    physicalReference: "1235",
    maxPowerInKw: 20,
    availability: .unavailable,
    availabilityUpdatedAt: Date().addingTimeInterval(-200_000),
    connectors: [.combo],
    speed: .hyper,
    powerType: .dc,
  )

  static let mockOutOfService = ChargePoint(
    evseId: "DE*SIM*1236",
    physicalReference: "1236",
    maxPowerInKw: 350,
    availability: .outOfService,
    availabilityUpdatedAt: Date().addingTimeInterval(-300_000),
    connectors: [.chademo],
    speed: .hyper,
    powerType: .dc,
  )
}

// MARK: - Collection Helpers

package extension [ChargePoint] {
  /// The largest common prefix across all EVSE identifiers in the collection.
  var largestCommonEvseIdPrefix: String {
    let evseIdentifiers = map(\.evseId)
    let uniqueEvseIdentifiers = evseIdentifiers.unique()
    guard uniqueEvseIdentifiers.count > 1 else {
      // Only one unique EVSE id present; do not strip anything in the UI
      return ""
    }
    return evseIdentifiers.largestCommonPrefix()
  }
}
