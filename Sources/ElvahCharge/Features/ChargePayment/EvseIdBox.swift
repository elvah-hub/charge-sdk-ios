// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Core)
	import Core
#endif

@available(iOS 16.0, *)
struct EvseIdBox: View {
	private var signedOffer: SignedChargeOffer

	init(for signedOffer: SignedChargeOffer) {
		self.signedOffer = signedOffer
	}

	var body: some View {
		VStack(spacing: 8) {
			Text(signedOffer.chargePoint.physicalReference ?? signedOffer.chargePoint.evseId)
				.typography(.title(size: .medium), weight: .bold)
				.padding(.horizontal, .M)
				.padding(.vertical, .S)
				.background {
					RoundedRectangle(cornerRadius: 8)
						.foregroundStyle(.brand)
						.opacity(0.2)
						.overlay(alignment: .leading) {
							Image(.plugBackground)
								.foregroundStyle(.brand)
								.opacity(0.1)
						}
						.overlay {
							RoundedRectangle(cornerRadius: 8)
								.stroke(.decorativeStroke, lineWidth: 1)
						}
						.clipShape(RoundedRectangle(cornerRadius: 8))
				}
				.dynamicTypeSize(...(.accessibility1))
		}
	}
}

@available(iOS 16.0, *)
#Preview {
	EvseIdBox(for: .mockAvailable)
		.padding()
		.withFontRegistration()
}
