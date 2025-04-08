// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct MissingChargeContextView: View {
	@Environment(\.navigationRoot) private var navigationRoot

	var body: some View {
		VStack(spacing: Size.M.size) {
			Image(systemName: "bolt.slash.fill")
				.font(.inter(size: 60))
				.symbolRenderingMode(.hierarchical)
				.foregroundStyle(.secondaryContent)
			Text("No Charge Session", bundle: .elvahCharge)
				.typography(.copy(size: .large), weight: .bold)
				.fixedSize(horizontal: false, vertical: true)
		}
		.foregroundStyle(.primaryContent)
		.padding(.horizontal, .M)
		.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				CloseButton {
					navigationRoot.dismiss()
				}
			}
		}
	}
}

@available(iOS 16.0, *)
#Preview {
	MissingChargeContextView()
		.withFontRegistration()
}
