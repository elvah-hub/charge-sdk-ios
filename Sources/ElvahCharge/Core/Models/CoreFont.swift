// Copyright © elvah. All rights reserved.

import SwiftUI

/// An enum containing the names of the fonts that this SDK uses.
package enum CoreFont: String, CaseIterable, Sendable {
	case inter = "Inter"

	var fileName: String {
		switch self {
		case .inter:
			"Inter.ttf"
		}
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
		font(.inter(size: style.size, relativeTo: style.sizeRelation))
	}

	/// Returns a view with a themed font and font weight.
	/// - Parameter style: The font style and weight to apply.
	/// - Returns: A view with a themed font and font weight.
	func typography(_ style: CoreFont.Style, weight: CoreFont.Weight) -> some View {
		font(.inter(size: style.size, relativeTo: style.sizeRelation))
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
	/// Returns the "Inter" font with the specified size and relative text style.
	static func inter(size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
		.custom(CoreFont.inter.rawValue, size: size, relativeTo: textStyle)
	}
}
