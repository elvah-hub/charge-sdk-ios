// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension Button {
	@MainActor init(
		_ titleKey: LocalizedStringKey,
		role: ButtonRole? = nil,
		bundle: Bundle? = nil,
		action: @escaping () -> Void
	) where Label == Text {
		self.init(role: role, action: action) {
			Text(titleKey, bundle: bundle)
		}
	}

	@MainActor init(
		_ title: LocalizedStringKey,
		icon: ImageResource,
		bundle: Bundle? = nil,
		action: @escaping () -> Void
	) where Label == ButtonFoundationLabel<Text> {
		self.init(action: action) {
			ButtonFoundationLabel(title: Text(title, bundle: bundle), icon: Image(icon))
		}
	}

	@MainActor init<Title: View>(
		icon: ImageResource,
		action: @escaping () -> Void,
		@ViewBuilder title: @escaping () -> Title
	) where Label == ButtonFoundationLabel<Title> {
		self.init(action: action) {
			ButtonFoundationLabel(title: title(), icon: Image(icon))
		}
	}

	@MainActor init(icon: ImageResource, bundle: Bundle? = nil, action: @escaping () -> Void)
		where Label == ButtonFoundationImage {
		self.init(action: action) {
			ButtonFoundationImage(Image(icon))
		}
	}
}
