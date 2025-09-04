// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension DailyPricingView {
	/// Header view summarizing the current pricing state for the selected day.
	struct Summary: View {
		package var dataset: DailyPriceChartData

		package init(dataset: DailyPriceChartData) {
			self.dataset = dataset
		}

		package var body: some View {
			VStack(alignment: .leading, spacing: Size.M.size) {
				headerRow
				priceRow
				availabilityRow
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}

		/// Top row: "Live pricing" on the left, connector description on the right.
		private var headerRow: some View {
			AdaptiveHStack(horizontalAlignment: .leading, verticalAlignment: .center, spacing: Size.XS.size) { isHorizontal in
				Text("Live pricing", bundle: .elvahCharge)
					.typography(.copy(size: .medium), weight: .bold)
					.foregroundStyle(.secondaryContent)
				if isHorizontal {
					Spacer()
				}
				HStack(spacing: Size.XXS.size) {
					Text("CCS, Very fast (350 kW)", bundle: .elvahCharge)
					Image(systemName: "chevron.down")
				}
				.foregroundStyle(.primaryContent)
				.typography(.copy(size: .small), weight: .regular)
			}
		}

		/// Middle row: prominent current price with optional struck-through base price.
		@ViewBuilder private var priceRow: some View {
			let now = Date()
			let isToday = Calendar.current.isDateInToday(dataset.day)
			let reference = isToday ? now : Calendar.current.date(byAdding: .hour, value: 12, to: dataset.day) ?? dataset.day
			let price = currentPrice(at: reference)
			let discounted = isDiscounted(at: reference)

			AdaptiveHStack(horizontalAlignment: .leading, verticalAlignment: .center, spacing: Size.S.size) {
				Text("\(Currency(price).formatted()) /kWh", bundle: .elvahCharge)
					.typography(.copy(size: .xLarge), weight: .bold)
					.foregroundStyle(discounted ? .brand : .primaryContent)

				if discounted {
					Text("\(dataset.basePrice.formatted()) /kWh", bundle: .elvahCharge)
						.typography(.copy(size: .medium), weight: .regular)
						.strikethrough(true, pattern: .solid)
						.foregroundStyle(.secondaryContent)
				}
			}
		}

		/// Bottom row: relative day + time on the left and a tag-like availability badge.
		@ViewBuilder private var availabilityRow: some View {
			let now = Date()
			let label = Text(relativeDayLabel(for: dataset.day), bundle: .elvahCharge)
			let timeText = Text(now, format: .dateTime.hour().minute())

			AdaptiveHStack(horizontalAlignment: .leading, verticalAlignment: .center, spacing: Size.S.size) {
				Text("\(label) \(timeText)")
					.typography(.copy(size: .medium), weight: .bold)
					.foregroundStyle(.primaryContent)
				OfferBadge(state: currentBadgeState(reference: now))
			}
		}

		/// Determines the visual badge state for the given reference time.
		private func currentBadgeState(reference: Date) -> OfferBadge.State {
			if let active = dataset.discounts.first(where: { reference >= $0.startTime &&
					reference < $0.endTime
			}) {
				return .active(active)
			}
			if let next = dataset.discounts.first(where: { $0.startTime > reference }) {
				return .upcoming(next)
			}
			return .none
		}

		// MARK: - Helpers

		/// Returns a localized label for a given day relative to today.
		private func relativeDayLabel(for day: Date) -> LocalizedStringKey {
			let cal = Calendar.current
			if cal.isDateInYesterday(day) {
				return "Yesterday"
			}
			if cal.isDateInToday(day) {
				return "Today"
			}
			if cal.isDateInTomorrow(day) {
				return "Tomorrow"
			}
			return "Today"
		}

		private func currentPrice(at date: Date) -> Double {
			for seg in dataset.discounts where date >= seg.startTime && date < seg.endTime {
				return seg.price.amount
			}
			return dataset.basePrice.amount
		}

		private func isDiscounted(at date: Date) -> Bool {
			for seg in dataset.discounts where date >= seg.startTime && date < seg.endTime {
				return true
			}
			return false
		}

		/// Currently active discount, or the next upcoming one for the day.
		private func currentOrNextDiscount(reference: Date) -> DailyPriceChartData.DiscountSpan? {
			if let active = dataset.discounts.first(where: { reference >= $0.startTime &&
					reference < $0.endTime
			}) {
				return active
			}
			return dataset.discounts.first(where: { $0.startTime > reference })
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	let data = PricingSchedule.mock.chartData()[1]
	DailyPricingView.Summary(dataset: data)
		.padding()
		.withFontRegistration()
}
