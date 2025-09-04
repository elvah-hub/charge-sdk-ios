// Copyright © elvah. All rights reserved.

import SwiftUI

/// Daily pricing composite view hosting a summary header and a three-day price chart pager.
///
/// This view also acts as a namespace for its subviews via extensions, e.g.
/// `DailyPricingView.Summary` and `DailyPricingView.PriceChart`.
@available(iOS 16.0, *)
package struct DailyPricingView: View {
	/// Pricing schedule providing yesterday/today/tomorrow data.
	package var schedule: PricingSchedule

	/// Currently selected day in the pager. Defaults to today if available.
	@State private var selectedDay: PricingSchedule.RelativeDay

	package init(schedule: PricingSchedule) {
		self.schedule = schedule
		// Determine available days and prefer today when possible.
		let availableDays = PricingSchedule.RelativeDay.allCases.filter { day in
			schedule.chartData(for: day) != nil
		}
		let initial = availableDays.contains(.today) ? .today : (availableDays.first ?? .today)
		_selectedDay = State(initialValue: initial)
	}

	package var body: some View {
		// Pair each available relative day with its corresponding dataset.
		let dayDatasets = PricingSchedule.RelativeDay.allCases
			.compactMap { day in schedule.chartData(for: day).map { (day, $0) } }

		VStack(spacing: 12) {
			if let current = dayDatasets.first(where: { $0.0 == selectedDay })?.1 {
				Summary(dataset: current).padding(.horizontal)
					.animation(.default, value: selectedDay)
			}

			TabView(selection: $selectedDay) {
				ForEach(dayDatasets, id: \.0) { day, data in
					PriceChart(data: data)
						.padding(.vertical, 4)
						.frame(maxWidth: .infinity)
						.tag(day)
				}
			}
			.frame(height: 150)
			.tabViewStyle(.page(indexDisplayMode: .never))
			.animation(.default, value: selectedDay)

			if dayDatasets.count >= 2 {
				dayPicker(dayDatasets: dayDatasets, selection: $selectedDay)
					.padding(.horizontal)
			}
		}
	}

	/// Segmented control to switch between available days.
	private func dayPicker(
		dayDatasets: [(PricingSchedule.RelativeDay, DailyPriceChartData)],
		selection: Binding<PricingSchedule.RelativeDay>
	) -> some View {
		Picker("Day", selection: selection) {
			ForEach(dayDatasets, id: \.0) { day, _ in
				Text(relativeDayLabel(for: day)).tag(day)
			}
		}
		.pickerStyle(.segmented)
	}

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
		return "Today" // Fallback
	}

	/// Returns a localized label for the given relative day.
	private func relativeDayLabel(for day: PricingSchedule.RelativeDay) -> LocalizedStringKey {
		switch day {
		case .yesterday:
			return "Yesterday"
		case .today:
			return "Today"
		case .tomorrow:
			return "Tomorrow"
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	DailyPricingView(schedule: .mock)
		.withFontRegistration()
}
