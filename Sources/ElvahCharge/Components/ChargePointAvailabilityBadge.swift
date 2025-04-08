// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargePointAvailabilityBadge: View {
	let chargePoints: [ChargePointDetails]
	let includeOutOfService: Bool

	var body: some View {
		Text(verbatim: availabilityTitle)
			.typography(.copy(size: .small), weight: .bold)
			.foregroundStyle(availabilityTitleColor)
			.padding(.horizontal, .XS)
			.padding(.vertical, .XXS)
			.background(
				Capsule()
					.fill(availabilityBackgroundColor)
			)
	}

	private var availabilityTitle: String {
		"\(availableNumberOfChargePoints)/\(totalNumberOfChargePoints)"
	}

	private var availabilityTitleColor: Color {
		if availableNumberOfChargePoints > 0 {
			return .onSuccess
		} else {
			return .red
		}
	}

	private var availabilityBackgroundColor: Color {
		if availableNumberOfChargePoints > 0 {
			return .success
		} else {
			return .red.opacity(0.1)
		}
	}

	private var availableNumberOfChargePoints: Int {
		chargePoints.filter { $0.isAvailable }.count
	}

	private var totalNumberOfChargePoints: Int {
		if includeOutOfService {
			chargePoints.count
		} else {
			chargePoints.filter { $0.isOutOfService == false }.count
		}
	}
}

@available(iOS 16.0, *)
#Preview {
	ZStack {
		Color.canvas.ignoresSafeArea()
		ChargePointAvailabilityBadge(
			chargePoints: [.mockAvailable, .mockUnavailable, .mockOutOfService],
			includeOutOfService: true
		)
	}
	.withFontRegistration()
}
