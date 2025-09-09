// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension PricingScheduleView {
	/// Header view summarizing the current pricing state for the selected day.
	struct Summary: View {
		/// Controls presentation of the "More Prices" sheet.
		@State private var showOtherPricesSheet: Bool = false

		/// The dataset that the drives the summary.
		private var dataset: DailyPriceChartData

		/// Selected moment binding to drive the summary instead of the current time.
		@Binding private var selectedMoment: Date?

		package init(dataset: DailyPriceChartData, selectedMoment: Binding<Date?>) {
			self.dataset = dataset
			_selectedMoment = selectedMoment
		}

		/// Convenience init for previews/tests.
		package init(dataset: DailyPriceChartData) {
			self.dataset = dataset
			_selectedMoment = .constant(nil)
		}

		package var body: some View {
			TimelineView(.periodic(from: .now, by: 60)) { context in
				let reference = displayReference(for: context.date)

				VStack(alignment: .leading, spacing: .size(.S)) {
					headerRow()
					priceRow(reference: reference)
					availabilityRow(reference: reference)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.animation(.default, value: context.date)
			}
			.sheet(isPresented: $showOtherPricesSheet) {
				MorePricesSheetContent()
			}
		}

		@ViewBuilder private func headerRow() -> some View {
			AdaptiveHStack(horizontalAlignment: .leading, verticalAlignment: .center, spacing: .size(.XXS)) { isHorizontal in
				HStack(spacing: .size(.XXS)) {
					Text("Live Pricing", bundle: .elvahCharge)
						.typography(.copy(size: .medium), weight: .bold)
						.foregroundStyle(.secondaryContent)
						.contentTransition(.interpolate)
				}
				if isHorizontal {
					Spacer()
				}
				Button {
					showOtherPricesSheet = true
				} label: {
					HStack(spacing: .size(.XXXS)) {
						Text("CCS, Very fast (350 kW)")
							.typography(.copy(size: .medium))
							.foregroundStyle(.primaryContent)
						Image(.chevronSmallDown)
					}
				}
				.buttonStyle(.plain)
				.foregroundStyle(.secondaryContent)
				.typography(.copy(size: .small), weight: .regular)
			}
		}

		@ViewBuilder private func priceRow(reference: Date) -> some View {
			let price = PricingComputation.currentPrice(at: reference, in: dataset)
			let discounted = PricingComputation.isDiscounted(at: reference, in: dataset)

			VStack(alignment: .leading, spacing: .size(.XXS)) {
				AdaptiveHStack(horizontalAlignment: .leading, verticalAlignment: .center, spacing: .size(.XXS)) {
					Text("\(Currency(price).formatted()) /kWh", bundle: .elvahCharge)
						.typography(.copy(size: .xLarge), weight: .bold)
						.monospacedDigit()
						.foregroundStyle(discounted ? .brand : .primaryContent)
						.contentTransition(.numericText())

					if discounted {
						Text("\(dataset.basePrice.formatted()) /kWh", bundle: .elvahCharge)
							.typography(.copy(size: .medium), weight: .regular)
							.monospacedDigit()
							.strikethrough(true, pattern: .solid)
							.foregroundStyle(.secondaryContent)
							.contentTransition(.numericText())
							.transition(.opacity.combined(with: .scale(scale: 1.2)))
					}
				}
			}
		}

		@ViewBuilder private func availabilityRow(reference: Date) -> some View {
			let dayText = Text(relativeDayLabel(for: dataset.day), bundle: .elvahCharge)
			let isYesterday = Calendar.current.isDateInYesterday(dataset.day)

			AdaptiveHStack(
				horizontalAlignment: .leading,
				verticalAlignment: .center,
				spacing: .size(.S),
				breakPoint: .xxLarge
			) {
				if let moment = selectedMoment,
				   let range = PricingComputation.segmentRange(containing: moment, in: dataset) {
					Text("\(dayText) \(timeRangeText(range))", bundle: .elvahCharge)
						.typography(.copy(size: .medium), weight: .bold)
						.foregroundStyle(.secondaryContent)
						.contentTransition(.numericText())
						.monospacedDigit()
						.transition(.opacity.combined(with: .scale(scale: 0.8)))
						.layoutPriority(1)
				} else {
					dayText
						.typography(.copy(size: .medium), weight: .bold)
						.foregroundStyle(.secondaryContent)
						.transition(.opacity.combined(with: .scale(scale: 0.8)))
						.layoutPriority(1)
				}
				OfferBadge(state: currentBadgeState(reference: reference), showsTimeRange: selectedMoment == nil)
					.lineLimit(1)
					.opacity(isYesterday && selectedMoment == nil ? 0 : 1)
			}
		}

		/// Determines the visual badge state.
		///
		/// When a selection exists within the day's domain, the badge reflects the selected
		/// block only (active if inside a discount, otherwise none). Without a selection,
		/// it reflects the current reference time (active / upcoming / none).
		private func currentBadgeState(reference: Date) -> OfferBadge.State {
			if let selected = selectedMoment, PricingComputation.fullDayDomain(for: dataset.day).contains(selected) {
				if let active = dataset.discounts.first(where: { selected >= $0.startTime && selected < $0.endTime }) {
					return .active(active)
				}
				return .none
			}

			if let active = dataset.discounts.first(where: { reference >= $0.startTime && reference < $0.endTime }) {
				return .active(active)
			}

			if let next = dataset.discounts.first(where: { $0.startTime > reference }) {
				return .upcoming(next)
			}
			return .none
		}

		// MARK: - Helpers

		/// Computes the effective moment used by the Summary for pricing and state at a given timeline tick.
		///
		/// Selection within the displayed day takes precedence. If there is no selection,
		/// the view behaves “live” for today (using `timelineNow`) and uses a stable noon
		/// fallback for non-today days to avoid misleading midnight values.
		private func displayReference(for timelineNow: Date) -> Date {
			let domain = PricingComputation.fullDayDomain(for: dataset.day)
			let isSelectionInDay = selectedMoment.flatMap { domain.contains($0) } ?? false
			let isToday = Calendar.current.isDateInToday(dataset.day)
			let fallback = isToday ? timelineNow : noon(of: dataset.day)
			return isSelectionInDay ? (selectedMoment ?? fallback) : fallback
		}

		/// Builds a time range label for the given date range, e.g. "08:00 → 10:00".
		private func timeRangeText(_ range: ClosedRange<Date>) -> Text {
			let start = Text(range.lowerBound, format: .dateTime.hour().minute())
			let end = Text(range.upperBound, format: .dateTime.hour().minute())
			return Text("\(start) → \(end)")
		}

		/// Returns a localized label for a given day relative to today.
		///
		/// When no specific moment is selected and the given day is today,
		/// the label reads "Now" to reflect the live state.
		private func relativeDayLabel(for day: Date) -> LocalizedStringKey {
			let calendar = Calendar.current
			if calendar.isDateInYesterday(day) {
				return "Yesterday"
			}
			if calendar.isDateInToday(day) {
				return selectedMoment == nil ? "Now" : "Today"
			}
			if calendar.isDateInTomorrow(day) {
				return "Tomorrow"
			}

			return "Today"
		}

		/// Noon fallback used for non-today reference time.
		private func noon(of day: Date) -> Date {
			Calendar.current.date(byAdding: .hour, value: 12, to: day) ?? day
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	let data = PricingSchedule.mock.chartData()[1]
	PricingScheduleView.Summary(dataset: data, selectedMoment: .constant(Date()))
		.padding()
		.withFontRegistration()
}
