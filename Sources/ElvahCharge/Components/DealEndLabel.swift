// Copyright © elvah. All rights reserved.

import SwiftUI

/// A view displaying the time left until a deal ends.
@available(iOS 16.0, *)
struct DealEndLabel: View {
	var deal: Deal
	var referenceDate: Date
	var prefix: LocalizedStringKey?
	var primaryColor: Color
	var highlightColor: Color?

	/// Initializes a `DealEndLabel`.
	///
	/// - Parameters:
	///   - deal: The deal to display the end time for.
	///   - prefix: An optional prefix to display before the time left.
	///   - referenceDate: A reference date.
	///   - primaryColor: The primary label color used for the prefix and "Ended" state.
	///   - highlightColor: The color that the countdown label should have. If set to `nil`, the
	/// environment foreground color will be used.
	init(
		deal: Deal,
		referenceDate: Date,
		prefix: LocalizedStringKey? = nil,
		primaryColor: Color,
		highlightColor: Color? = nil
	) {
		self.deal = deal
		self.referenceDate = referenceDate
		self.prefix = prefix
		self.primaryColor = primaryColor
		self.highlightColor = highlightColor
	}

	var body: some View {
		let timeLeft = max(
			Duration.seconds(0),
			Duration.seconds(deal.campaignEndDate.timeIntervalSince(referenceDate))
		)

		let suffixColor = timeLeft > .zero ? (highlightColor ?? primaryColor) : primaryColor
		let suffixText = timeLeft > .zero
			? formatTimeLeft(timeLeft)
			: String(localized: "Ended", bundle: .elvahCharge)

		if timeLeft > .zero, let prefix = prefix {
			(Text(prefix).foregroundColor(primaryColor) + Text(suffixText).foregroundColor(suffixColor))
				.fixedSize(horizontal: false, vertical: true)
		} else {
			Text(suffixText).foregroundColor(suffixColor).fixedSize(horizontal: false, vertical: true)
		}
	}

	private func formatTimeLeft(_ duration: Duration) -> String {
		// If less than 1 minute remaining, show seconds
		if duration.components.seconds < 60 {
			return duration.formatted(.units(
				allowed: [.seconds],
				maximumUnitCount: 1
			))
		}

		// Otherwise show larger units
		return duration.formatted(.units(
			allowed: [.days, .hours, .minutes],
			maximumUnitCount: 2
		))
	}
}

@available(iOS 16.0, *)
#Preview {
	VStack(spacing: 20) {
		// Preview default style
		DealEndLabel(deal: .mockAvailable, referenceDate: Date(), primaryColor: .primaryContent)

		// Preview with custom prefix
		DealEndLabel(
			deal: .mockAvailable,
			referenceDate: Date(),
			prefix: "Offer ends in ",
			primaryColor: .primaryContent
		)

		// Preview ended state
		DealEndLabel(deal: .mockUnavailable, referenceDate: Date(), primaryColor: .primaryContent)

		// Preview with custom color
		DealEndLabel(deal: .mockAvailable, referenceDate: Date(), primaryColor: .primaryContent)
	}
	.padding()
	.background(.canvas)
	.withFontRegistration()
	.preferredColorScheme(.dark)
}
