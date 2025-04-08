// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension View {
	func errorBottomSheet<Actions: View>(
		isPresented: Binding<Bool>,
		title: LocalizedStringKey,
		description: LocalizedStringKey,
		onDismiss: (() -> Void)? = nil,
		@ViewBuilder actions: @escaping (_ dismiss: DismissAction) -> Actions
	) -> some View {
		sheet(isPresented: isPresented, onDismiss: onDismiss) {
			ErrorBottomSheetContent(
				title: title,
				description: description,
				actions: actions
			)
		}
	}

	func genericErrorBottomSheet<Actions: View>(
		isPresented: Binding<Bool>,
		onDismiss: (() -> Void)? = nil,
		@ViewBuilder actions: @escaping (_ dismiss: DismissAction) -> Actions
	) -> some View {
		errorBottomSheet(
			isPresented: isPresented,
			title: "Oh, that didn't work out!",
			description: "An unexpected error has occurred. Please try again or contact our support.",
			onDismiss: onDismiss,
			actions: actions
		)
	}

	func genericErrorBottomSheet(
		isPresented: Binding<Bool>,
		onDismiss: (() -> Void)? = nil
	) -> some View {
		errorBottomSheet(
			isPresented: isPresented,
			title: "Oh, that didn't work out!",
			description: "An unexpected error has occurred. Please try again or contact our support.",
			onDismiss: onDismiss,
			actions: { dismiss in
				Button("Got it", bundle: .elvahCharge) {
					dismiss()
				}
				.buttonStyle(.primary)
			}
		)
	}
}

// MARK: - View Modifier

@available(iOS 16.0, *)
private struct ErrorBottomSheetContent<Actions: View>: View {
	@Environment(\.dismiss) private var dismiss

	let title: LocalizedStringKey
	let description: LocalizedStringKey
	@ViewBuilder let actions: (_ dismiss: DismissAction) -> Actions

	var body: some View {
		BottomSheetComponent(title: title, canBeDismissed: false, isExpandable: false) {
			Text(description, bundle: .elvahCharge)
		} footer: {
			actions(dismiss)
		}
	}
}
