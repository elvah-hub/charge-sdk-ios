// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ButtonInternal {
	struct PreviewButtons: View {
		var body: some View {
			ScrollView {
				VStack {
					VStack {
						Button("Sign in", icon: .notificationBell) {}
						Button("Sign in", icon: .notificationBell) {}.loading(true)
						Button("Sign in", icon: .notificationBell) {}.disabled(true)
						Button("Sign in", icon: .notificationBell) {}.redacted(reason: .placeholder)
					}
					HStack(alignment: .top) {
						VStack {
							Button("Sign in", icon: .chevronSmallRight) {}
							Button("Sign in", icon: .chevronSmallRight) {}.loading(true)
							Button("Sign in", icon: .chevronSmallRight) {}.disabled(true)
							Button("Sign in", icon: .chevronSmallRight) {}.redacted(reason: .placeholder)
						}
						.controlSize(.small)
						VStack {
							Button("Sign in") {}
							Button("Sign in") {}.loading(true)
							Button("Sign in") {}.disabled(true)
							Button("Sign in") {}.redacted(reason: .placeholder)
						}
						.controlSize(.small)
						VStack {
							Button(icon: .share) {}
							Button(icon: .share) {}.loading(true)
							Button(icon: .share) {}.disabled(true)
							Button(icon: .share) {}.redacted(reason: .placeholder)
						}
						VStack {
							Button(icon: .share) {}
							Button(icon: .share) {}.loading(true)
							Button(icon: .share) {}.disabled(true)
							Button(icon: .share) {}.redacted(reason: .placeholder)
						}
						.controlSize(.small)
					}
				}
				.padding(.horizontal)
				.frame(maxWidth: .infinity)
			}
			.background(.canvas)
		}
	}
}

@available(iOS 16.0, *)
#Preview {
	ButtonInternal.PreviewButtons()
		.buttonStyle(.primary)
		.withFontRegistration()
}
