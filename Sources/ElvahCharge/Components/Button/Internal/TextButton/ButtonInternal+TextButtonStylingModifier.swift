// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ButtonInternal {
	struct TextButtonStylingModifier: ViewModifier {
		@Environment(\.controlSize) private var controlSize
		@Environment(\.redactionReasons) private var redactionReasons
		@Environment(\.isEnabled) private var isEnabled
		@Environment(\.isLoading) private var isLoading
		@Environment(\.isCompact) private var isCompact

		let kind: TextButtonKind
		let isPressed: Bool

		func body(content: Content) -> some View {
			Group {
				if controlSize.isSmall {
					content
						.typography(.copy(size: .small), weight: .bold)
				} else {
					content
						.typography(.copy(size: .medium), weight: .bold)
				}
			}
			.tint(styling.foreground)
			.foregroundStyle(styling.foreground)
			.background(backgroundContent)
			.dynamicTypeSize(...(.accessibility1))
		}

		private var contentShape: some InsettableShape {
			var radius: Double {
				if controlSize.isSmall && isCompact {
					return 2
				}
				if controlSize.isSmall {
					return 4
				}
				return 8
			}
			return RoundedRectangle(cornerRadius: radius)
		}

		@ViewBuilder private var backgroundContent: some View {
			if redactionReasons.contains(.placeholder) {
				contentShape.fill(.brand.opacity(0.1))
			}
		}

		private var styling: Styling {
			if redactionReasons.contains(.placeholder) {
				return Styling(foreground: .clear.opacity(0))
			}

			if isLoading {
				return switch kind {
				case .brand:
					Styling(foreground: .brand)
				case .primary:
					Styling(foreground: .primaryContent)
				}
			}

			if isEnabled == false {
				return switch kind {
				case .brand:
					Styling(foreground: .brand.opacity(0.2))
				case .primary:
					Styling(foreground: .primaryContent.opacity(0.2))
				}
			}

			if isPressed {
				return switch kind {
				case .brand:
					Styling(foreground: .brand.opacity(0.6))
				case .primary:
					Styling(foreground: .primaryContent.opacity(0.6))
				}
			}

			return switch kind {
			case .brand:
				Styling(foreground: .brand)
			case .primary:
				Styling(foreground: .primaryContent)
			}
		}
	}
}

@available(iOS 16.0, *)
extension ButtonInternal.TextButtonStylingModifier {
	private struct Styling {
		var foreground: Color
	}
}

@available(iOS 16.0, *)
private typealias StylingModifier = ButtonInternal.TextButtonStylingModifier

@available(iOS 16.0, *)
#Preview {
	ScrollView {
		VStack(alignment: .leading) {
			Text(verbatim: "Default")
			iconButtons
			Text(verbatim: "Pressed")
			pressedIconButtons
			Text(verbatim: "Loading")
			loadingIconButtons.loading(true)
			Text(verbatim: "Disabled")
			iconButtons.disabled(true)
			Text(verbatim: "Redacted")
			iconButtons.frame(height: 52).redacted(reason: .placeholder)
		}
		.frame(maxWidth: .infinity)
		.padding(.horizontal)
	}
	.background(Color.canvas)
	.withFontRegistration()
}

@available(iOS 16.0, *) private var iconButtons: some View {
	HStack {
		Text(verbatim: "Ab")
			.padding()
			.modifier(StylingModifier(kind: .brand, isPressed: false))
		Text(verbatim: "Ab")
			.padding()
			.modifier(StylingModifier(kind: .primary, isPressed: false))
	}
}

@available(iOS 16.0, *) private var pressedIconButtons: some View {
	HStack {
		Text(verbatim: "Ab")
			.padding()
			.modifier(StylingModifier(kind: .brand, isPressed: true))
		Text(verbatim: "Ab")
			.padding()
			.modifier(StylingModifier(kind: .primary, isPressed: true))
	}
}

@available(iOS 16.0, *) private var loadingIconButtons: some View {
	HStack {
		Text(verbatim: "Ab").hidden().overlay(ProgressView())
			.padding()
			.modifier(StylingModifier(kind: .brand, isPressed: false))
		Text(verbatim: "Ab").hidden().overlay(ProgressView())
			.padding()
			.modifier(StylingModifier(kind: .primary, isPressed: false))
	}
}
