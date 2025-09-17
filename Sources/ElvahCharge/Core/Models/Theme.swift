// Copyright © elvah. All rights reserved.

import SwiftUI

/// A structure representing a theme used in the SDK.
public struct Theme: Hashable, Sendable {
	/// The color scheme for the theme.
	public var color: Color

	/// The typography for the theme.
	public var typography: Typography

	/// Creates a new theme with the specified color scheme.
	///
	/// - Parameter color: The color scheme to use for the theme.
	/// - Parameter typography: The typography to use for the theme.
	public init(color: Color = .default, typography: Typography = .default) {
		self.color = color
		self.typography = typography
	}

	/// Creates a new theme with a custom font.
	///
	/// - Parameter color: The color scheme to use for the theme.
	/// - Parameter font: The custom font to use for the theme.
	/// - Parameter regularWeight: The regular font weight.
	/// - Parameter boldWeight: The bold font weight.
	public init(
		color: Color = .default,
		font: CoreFont = .default,
		regularWeight: Font.Weight = .regular,
		boldWeight: Font.Weight = .bold,
	) {
		self.color = color
		typography = Typography(
			font: font,
			regularWeight: regularWeight,
			boldWeight: boldWeight,
		)
	}

	/// The default theme.
	public static let `default` = Theme(color: .default, typography: .default)
}

// MARK: - Color

public extension Theme {
	/// A structure representing typography information for a theme.
	struct Typography: Hashable, Sendable {
		public var font: CoreFont
		public var regularWeight: Font.Weight
		public var boldWeight: Font.Weight

		public init(
			font: CoreFont = .default,
			regularWeight: Font.Weight = .regular,
			boldWeight: Font.Weight = .bold,
		) {
			self.regularWeight = regularWeight
			self.boldWeight = boldWeight
			self.font = font
		}

		public static let `default`: Typography = .neutral

		public static let elvah: Typography = .init(
			font: .default,
			regularWeight: .medium,
			boldWeight: .semibold,
		)

		public static let neutral: Typography = .init(
			font: .default,
			regularWeight: .regular,
			boldWeight: .bold,
		)
	}

	/// A structure representing color information for a theme.
	struct Color: Hashable, Sendable {
		public var brand: SwiftUI.Color
		public var success: SwiftUI.Color
		public var onSuccess: SwiftUI.Color
		public var canvas: SwiftUI.Color
		public var onBrand: SwiftUI.Color
		public var primaryContent: SwiftUI.Color
		public var secondaryContent: SwiftUI.Color
		public var decorativeStroke: SwiftUI.Color
		public var container: SwiftUI.Color
		public var labelSDK: SwiftUI.Color

		/// Creates a new color theme.
		///
		/// - Note: It is usually best to define the colors in an Asset catalog to proplerly add support
		/// for dark mode and accessibility features.
		/// - Important: The brand colors will be used in conjunction with the system's native `primary`
		/// and `secondary` text colors. Therefore, it is recommended to choose a brand color that's
		/// dark enough to allow white text to be readable on it.
		public init(
			brand: SwiftUI.Color,
			success: SwiftUI.Color,
			onSuccess: SwiftUI.Color,
			canvas: SwiftUI.Color,
			onBrand: SwiftUI.Color,
			primaryContent: SwiftUI.Color,
			secondaryContent: SwiftUI.Color,
			decorativeStroke: SwiftUI.Color,
			container: SwiftUI.Color,
			label: SwiftUI.Color,
		) {
			self.brand = brand
			self.success = success
			self.onSuccess = onSuccess
			self.canvas = canvas
			self.onBrand = onBrand
			self.primaryContent = primaryContent
			self.secondaryContent = secondaryContent
			self.decorativeStroke = decorativeStroke
			self.container = container
			self.labelSDK = label
		}

		public static let `default`: Color = .neutral

		@_spi(Debug) public static let elvah: Color = .init(
			brand: SwiftUI.Color("elvah_brand", bundle: .core),
			success: SwiftUI.Color("elvah_success", bundle: .core),
			onSuccess: SwiftUI.Color("elvah_onSuccess", bundle: .core),
			canvas: SwiftUI.Color("elvah_canvas", bundle: .core),
			onBrand: SwiftUI.Color("elvah_onBrand", bundle: .core),
			primaryContent: SwiftUI.Color("elvah_primaryContent", bundle: .core),
			secondaryContent: SwiftUI.Color("elvah_secondaryContent", bundle: .core),
			decorativeStroke: SwiftUI.Color("elvah_decorativeStroke", bundle: .core),
			container: SwiftUI.Color("elvah_container", bundle: .core),
			label: SwiftUI.Color("elvah_label", bundle: .core),
		)

		public static let neutral: Color = .init(
			brand: SwiftUI.Color("neutral_brand", bundle: .core),
			success: SwiftUI.Color("neutral_success", bundle: .core),
			onSuccess: SwiftUI.Color("neutral_onSuccess", bundle: .core),
			canvas: SwiftUI.Color("neutral_canvas", bundle: .core),
			onBrand: SwiftUI.Color("neutral_onBrand", bundle: .core),
			primaryContent: SwiftUI.Color("neutral_primaryContent", bundle: .core),
			secondaryContent: SwiftUI.Color("neutral_secondaryContent", bundle: .core),
			decorativeStroke: SwiftUI.Color("neutral_decorativeStroke", bundle: .core),
			container: SwiftUI.Color("neutral_container", bundle: .core),
			label: SwiftUI.Color("neutral_label", bundle: .core),
		)
	}
}

// MARK: - ShapeStyle Color Extensions

package extension ShapeStyle where Self == Color {

	static var fixedGreen: Color {
		Color("fixed_green", bundle: .core)
	}

	static var brand: Color {
		Elvah.configuration.theme.color.brand
	}

	static var success: Color {
		Elvah.configuration.theme.color.success
	}

	static var onSuccess: Color {
		Elvah.configuration.theme.color.onSuccess
	}

	static var canvas: Color {
		Elvah.configuration.theme.color.canvas
	}

	static var onBrand: Color {
		Elvah.configuration.theme.color.onBrand
	}

	static var primaryContent: Color {
		Elvah.configuration.theme.color.primaryContent
	}

	static var decorativeStroke: Color {
		Elvah.configuration.theme.color.decorativeStroke
	}

	static var secondaryContent: Color {
		Elvah.configuration.theme.color.secondaryContent
	}

	static var container: Color {
		Elvah.configuration.theme.color.container
	}

	static var labelSDK: Color {
		Elvah.configuration.theme.color.labelSDK
	}
}
