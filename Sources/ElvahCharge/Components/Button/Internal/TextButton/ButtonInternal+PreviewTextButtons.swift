// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ButtonInternal {
	struct PreviewTextButtons: View {
		var backgroundColor: Color = .canvas
		var body: some View {
			ScrollView {
				VStack {
					Text(verbatim: "Regular").foregroundStyle(.primaryContent)
					HStack(alignment: .top) {
						VStack {
							Button("Later", icon: .share) {}
							Button("Later", icon: .share) {}.loading(true)
							Button("Later", icon: .share) {}.disabled(true)
							Button("Later", icon: .share) {}.redacted(reason: .placeholder)
						}
						VStack {
							Button("Later", icon: .share) {}
							Button("Later", icon: .share) {}.loading(true)
							Button("Later", icon: .share) {}.disabled(true)
							Button("Later", icon: .share) {}.redacted(reason: .placeholder)
						}
						.compactControl()
					}
					Divider()
					Text(verbatim: "Small").foregroundStyle(.primaryContent)
					HStack(alignment: .top) {
						VStack {
							Button("Later", icon: .share) {}
							Button("Later", icon: .share) {}.loading(true)
							Button("Later", icon: .share) {}.disabled(true)
							Button("Later", icon: .share) {}.redacted(reason: .placeholder)
						}
						VStack {
							Button("Later", icon: .share) {}
							Button("Later", icon: .share) {}.loading(true)
							Button("Later", icon: .share) {}.disabled(true)
							Button("Later", icon: .share) {}.redacted(reason: .placeholder)
						}
						.compactControl()
					}
					.controlSize(.small)
					Divider()
					Text(verbatim: "No Icon").foregroundStyle(.primaryContent)
					HStack(alignment: .top) {
						VStack {
							Button("Later") {}
							Button("Later") {}.loading(true)
							Button("Later") {}.disabled(true)
							Button("Later") {}.redacted(reason: .placeholder)
						}
						VStack {
							Button("Later") {}
							Button("Later") {}.loading(true)
							Button("Later") {}.disabled(true)
							Button("Later") {}.redacted(reason: .placeholder)
						}
						.compactControl()
					}
					Divider()
					Text(verbatim: "No Icon - Small").foregroundStyle(.primaryContent)
					HStack(alignment: .top) {
						VStack {
							Button("Later") {}
							Button("Later") {}.loading(true)
							Button("Later") {}.disabled(true)
							Button("Later") {}.redacted(reason: .placeholder)
						}
						VStack {
							Button("Later") {}
							Button("Later") {}.loading(true)
							Button("Later") {}.disabled(true)
							Button("Later") {}.redacted(reason: .placeholder)
						}
						.compactControl()
					}
					.controlSize(.small)
					Divider()
					Text(verbatim: "Inverted").foregroundStyle(.primaryContent)
					HStack(alignment: .top) {
						VStack {
							Button("Later", icon: .share) {}
							Button("Later", icon: .share) {}.loading(true)
							Button("Later", icon: .share) {}.disabled(true)
							Button("Later", icon: .share) {}.redacted(reason: .placeholder)
						}
						VStack {
							Button("Later", icon: .share) {}
							Button("Later", icon: .share) {}.loading(true)
							Button("Later", icon: .share) {}.disabled(true)
							Button("Later", icon: .share) {}.redacted(reason: .placeholder)
						}
						.compactControl()
					}
					.invertedButtonLabel()
				}
				.padding(.horizontal)
				.frame(maxWidth: .infinity)
			}
			.background(backgroundColor)
		}
	}
}

@available(iOS 16.0, *)
#Preview {
	ButtonInternal.PreviewTextButtons()
		.buttonStyle(.textBrand)
		.withFontRegistration()
}
