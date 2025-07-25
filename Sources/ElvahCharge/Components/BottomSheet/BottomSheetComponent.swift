// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct BottomSheetComponent<Content: View, Footer: View>: View {
	@Environment(\.dismiss) private var dismiss

	@State private var safeAreaInsets: EdgeInsets = .init()
	@State private var contentSize: CGSize = .zero
	@State private var footerSize: CGSize = .zero

	let title: LocalizedStringKey?
	let canBeDismissed: Bool
	let isExpandable: Bool
	let content: Content
	let footer: Footer

	init(
		title: LocalizedStringKey? = nil,
		canBeDismissed: Bool = true,
		isExpandable: Bool = false,
		@ViewBuilder content: () -> Content,
		@ViewBuilder footer: () -> Footer
	) {
		self.title = title
		self.canBeDismissed = canBeDismissed
		self.isExpandable = isExpandable
		self.content = content()
		self.footer = footer()
	}

	var body: some View {
		NavigationStack {
			if #available(iOS 16.4, *) {
				scrollableContent
					.scrollBounceBehavior(.basedOnSize)
					.safeAreaReader($safeAreaInsets)
			} else {
				scrollableContent
			}
		}
		.interactiveDismissDisabled(canBeDismissed == false)
		.presentationDetents(detents)
	}

	@ViewBuilder private var scrollableContent: some View {
		ScrollView {
			content
				.padding(.S)
				.frame(maxWidth: .infinity)
				.sizeReader($contentSize)
		}
		.typography(.copy(size: .large))
		.foregroundStyle(.primaryContent)
		.scrollContentBackground(.hidden)
		.background {
			Color.canvas.ignoresSafeArea()
		}
		.toolbarBackground(.container, for: .navigationBar)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .principal) {
				Text(title ?? "")
					.typography(.copy(size: .large), weight: .bold)
					.foregroundStyle(.primaryContent)
			}
			if canBeDismissed {
				ToolbarItem(placement: .topBarLeading) {
					CloseButton {
						dismiss()
					}
				}
			}
		}
		.safeAreaInset(edge: .bottom) {
			FooterView {
				ButtonStack {
					footer
				}
			}
			.sizeReader($footerSize)
		}
	}

	// MARK: - Helpers

	private var detents: Set<PresentationDetent> {
		// The 6 is from SwiftUI internal paddings for ScrollViews and stuff
		let height = contentSize.height + footerSize.height + safeAreaInsets.top + 6
		let heightDetent = PresentationDetent.height(height)
		if isExpandable {
			return [heightDetent, .large]
		}
		return [heightDetent]
	}
}
