// Copyright © elvah. All rights reserved.

import Foundation

/// A type-safe wrapper around energy values measured in kilowatt-hours.
package struct KilowattHours: Hashable, Sendable, Codable, AdditiveArithmetic,
  ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
  /// The underlying Measurement value using the `UnitEnergy.kilowattHours` unit.
  package var measurement: Measurement<UnitEnergy>

  /// The raw value in kilowatt-hours.
  package var value: Double {
    get { measurement.value }
    set { measurement.value = newValue }
  }

  /// Creates a `KilowattHours` instance from a `Double` value.
  package init(_ value: Double) {
    measurement = .init(value: value, unit: .kilowattHours)
  }

  /// Creates a `KilowattHours` instance from an `Int` value.
  package init(_ value: Int) {
    measurement = .init(value: Double(value), unit: .kilowattHours)
  }

  /// Creates a `KilowattHours` instance from an `integer` literal.
  package init(integerLiteral value: IntegerLiteralType) {
    self.init(Double(value))
  }

  /// Creates a `KilowattHours` instance from a `float` literal.
  package init(floatLiteral value: FloatLiteralType) {
    self.init(value)
  }

  /// Returns the value formatted with two decimal places and unit.
  package var formattedWithFraction: String {
    measurement.formatted(.withFraction)
  }

  /// Returns the value formatted with no decimal places and unit.
  package var formattedWithoutFraction: String {
    measurement.formatted(.withoutFraction)
  }

  /// Returns the value formatted with two decimal places, optionally including the unit.
  /// - Parameter includeUnit: A flag to indicate if the formatted string should contain the unit.
  /// - Returns: A formatted string.
  package func formattedWithFraction(includeUnit: Bool) -> String {
    if includeUnit {
      return formattedWithFraction
    }
    return value.formatted(.number.precision(.fractionLength(2)))
  }

  /// Returns the value formatted with no decimal places, optionally including the unit.
  /// - Parameter includeUnit: A flag to indicate if the formatted string should contain the unit.
  /// - Returns: A formatted string.
  package func formattedWithoutFraction(includeUnit: Bool) -> String {
    if includeUnit {
      return formattedWithoutFraction
    }
    return value.formatted(.number.precision(.fractionLength(0)))
  }

  package static func + (lhs: KilowattHours, rhs: KilowattHours) -> KilowattHours {
    let sum = lhs.measurement + rhs.measurement
    return KilowattHours(sum.value)
  }

  package static func - (lhs: KilowattHours, rhs: KilowattHours) -> KilowattHours {
    let difference = lhs.measurement - rhs.measurement
    return KilowattHours(difference.value)
  }

  package static func * (lhs: KilowattHours, rhs: Double) -> KilowattHours {
    let product = lhs.measurement * rhs
    return KilowattHours(product.value)
  }
}

private extension FormatStyle where Self == Measurement<UnitEnergy>.FormatStyle {
  static var withFraction: Self {
    .measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(2)))
  }

  static var withoutFraction: Self {
    .measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(0)))
  }
}

package extension KilowattHours {
  /// A KilowattHours instance representing zero energy.
  static var zero: Self {
    .init(0)
  }
}
