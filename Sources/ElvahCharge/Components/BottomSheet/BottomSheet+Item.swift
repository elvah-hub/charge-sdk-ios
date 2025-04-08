// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension View {
	func bottomSheet<Content: View, Footer: View, Item: Identifiable>(
		item: Binding<Item?>,
		onDismiss: (() -> Void)? = nil,
		@ViewBuilder content: @escaping (_ item: Item) -> Content,
		@ViewBuilder footer: @escaping (_ item: Item) -> Content
	) -> some View {
		modifier(
			BottomSheet(
				item: item,
				onDismiss: onDismiss,
				sheetContent: content,
				footer: footer
			)
		)
	}
}

@available(iOS 16.0, *)
private struct BottomSheet<SheetContent: View, Footer: View, Item: Identifiable>: ViewModifier {
	@Binding var item: Item?
	let onDismiss: (() -> Void)?

	@ViewBuilder let sheetContent: (_ item: Item) -> SheetContent
	@ViewBuilder let footer: (_ item: Item) -> Footer

	func body(content: Content) -> some View {
		content
			.sheet(
				item: $item,
				onDismiss: onDismiss,
				content: { item in
					BottomSheetComponent(
						content: {
							sheetContent(item)
						},
						footer: {
							footer(item)
						}
					)
				}
			)
	}
}
