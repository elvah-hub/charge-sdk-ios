// Copyright © elvah. All rights reserved.

import SwiftUI

/// An enum containing the names of the fonts that this SDK uses.
public enum CoreFont: Hashable, Sendable {
	/// The default font of the SDK.
	case `default`
	
	/// A custom font family that can be passed to the SDK.
	///
	/// Use this case to provide your own custom font to be used throughout the SDK's UI components.
	/// The font family name should match exactly what you've registered with the system.
	///
	/// Example usage:
	/// ```swift
	/// let theme = Theme(
	///   color: .default,
	///   font: .custom(family: "MyCustomFont")
	/// )
	/// let configuration = Elvah.Configuration(
	///   apiKey: "your-api-key",
	///   theme: theme
	/// )
	/// ```
	///
	/// - Important: The custom font must already be registered with the system before initializing
	/// the SDK. This typically means adding the font files to your app bundle and declaring them
	/// in your app's Info.plist under the "Fonts provided by application" key.
	///
	/// - Important: The font must support different font weights (Font.Weight values used by SwiftUI)
	/// to ensure proper display across all SDK components. The SDK uses various weights including
	/// regular, medium, semibold, and bold depending on your theme configuration.
	///
	/// - Parameter family: The name of the custom font family as registered with the system.
	case custom(family: String)

	package var rawValue: String {
		switch self {
		case .default:
			"Inter"
		case .custom(let family):
			family
		}
	}

	package var fileName: String {
		switch self {
		case .default:
			"Inter.ttf"
		case .custom:
			// Custom fonts are assumed to be already registered by the host app
			""
		}
	}

	/// Returns the cases that need font registration by the SDK.
	package static var registrableCases: [CoreFont] {
		[.default]
	}

	package enum Weight: Hashable, Sendable {
		case regular
		case bold

		var swiftUIWeight: Font.Weight {
			switch self {
			case .regular:
				Elvah.configuration.theme.typography.regularWeight
			case .bold:
				Elvah.configuration.theme.typography.boldWeight
			}
		}
	}

	package enum Style: Hashable, Sendable {
		case title(size: TitleSize)
		case copy(size: CopySize)

		var size: Double {
			switch self {
			case .title(size: .xLarge):
				60
			case .title(size: .medium):
				28
			case .title(size: .small):
				20
			case .copy(size: .xLarge):
				18
			case .copy(size: .large):
				16
			case .copy(size: .medium):
				14
			case .copy(size: .small):
				12
			}
		}

		var sizeRelation: Font.TextStyle {
			switch self {
			case .title(size: .xLarge):
				.title
			case .title(size: .medium):
				.title2
			case .title(size: .small):
				.title3
			case .copy(size: .xLarge):
				.body
			case .copy(size: .large):
				.body
			case .copy(size: .medium):
				.caption
			case .copy(size: .small):
				.caption
			}
		}

		package enum TitleSize {
			case xLarge
			case medium
			case small
		}

		package enum CopySize {
			case xLarge
			case large
			case medium
			case small
		}
	}
}

@available(iOS 16.0, *)
package extension View {
	/// Returns a view with a themed font.
	/// - Parameter style: The font style to apply.
	/// - Returns: A view with a themed font and font weight.
	func typography(_ style: CoreFont.Style) -> some View {
		font(.themed(size: style.size, relativeTo: style.sizeRelation))
	}

	/// Returns a view with a themed font and font weight.
	/// - Parameter style: The font style and weight to apply.
	/// - Returns: A view with a themed font and font weight.
	func typography(_ style: CoreFont.Style, weight: CoreFont.Weight) -> some View {
		font(.themed(size: style.size, relativeTo: style.sizeRelation))
			.fontWeight(weight.swiftUIWeight)
	}

	/// Returns a view with a themed font weight.
	/// - Parameter style: The themed font weight to apply.
	/// - Returns: A view with a themed font weight.
	func typography(_ weight: CoreFont.Weight) -> some View {
		fontWeight(weight.swiftUIWeight)
	}
}

package extension Font {
	/// Returns the themed font with the specified size and relative text style.
	static func themed(size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
		.custom(Elvah.configuration.theme.typography.font.rawValue, size: size, relativeTo: textStyle)
	}
}
