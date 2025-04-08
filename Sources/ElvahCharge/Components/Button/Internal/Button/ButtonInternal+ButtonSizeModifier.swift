// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ButtonInternal {
	struct ButtonSizeModifier: ViewModifier {
		@Environment(\.dynamicTypeSize) private var dynamicTypeSize
		@Environment(\.controlSize) private var controlSize
		@Environment(\.isLoading) private var isLoading

		var variant: ButtonVariant

		func body(content: Content) -> some View {
			switch variant {
			case .text,
			     .label:
				content
					.padding(.horizontal, .M)
					.offset(x: offset)
					.frame(minWidth: isSmall ? 96 : nil, maxWidth: isSmall ? nil : 720)
					.frame(height: buttonHeight)
					.environment(\.buttonIconSize, buttonIconSize)
			case .iconOnly:
				content
					.frame(width: isSmall ? 32 : 48, height: isSmall ? 32 : 48)
					.environment(\.buttonIconSize, buttonIconSize)
			}
		}

		private var isSmall: Bool {
			controlSize.isSmall
		}

		private var buttonIconSize: Double {
			controlSize.isSmall && variant == .iconOnly ? 16 : 24
		}

		private var offset: Double {
			let signum = isSmall ? 1.0 : -1.0
			return variant == .label && isLoading == false ? signum * 4 : 0
		}

		private var buttonHeight: Double {
			let baseHeight = isSmall ? 40.0 : 52.0

			switch dynamicTypeSize {
			case .xLarge,
			     .xxLarge:
				return baseHeight + 4
			case .xxxLarge:
				return baseHeight + 8
			case .accessibility1:
				return baseHeight + 12
			case .accessibility2,
			     .accessibility3,
			     .accessibility4,
			     .accessibility5:
				return baseHeight + 18
			default:
				return baseHeight
			}
		}
	}
}
