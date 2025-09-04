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

	/// Current page (0: yesterday, 1: today, 2: tomorrow). Defaults to today if available.
	@State private var page: Int

	package init(schedule: PricingSchedule) {
		self.schedule = schedule
		let data = schedule.chartData()
		// Prefer today if available, otherwise fall back to 0
		let defaultIndex = min(1, max(0, data.count - 1))
		_page = State(initialValue: defaultIndex)
	}

	package var body: some View {
		let datasets = schedule.chartData()
		VStack(spacing: 12) {
			if page >= 0 && page < datasets.count {
				let current = datasets[page]
				Summary(dataset: current)
			}

			TabView(selection: $page) {
				ForEach(datasets.indices, id: \.self) { index in
					let data = datasets[index]
					PriceChart(data: data)
						.padding(.vertical, 4)
						.frame(maxWidth: .infinity)
						.tag(index)
				}
			}
			.frame(height: 180)
			.tabViewStyle(.page(indexDisplayMode: .never))

			if datasets.count >= 2 {
				dayPicker(datasets: datasets, selection: $page)
					.padding(.horizontal)
			}
		}
	}

	/// Segmented control to switch between available days.
	private func dayPicker(
		datasets: [DailyPriceChartData],
		selection: Binding<Int>
	) -> some View {
		Picker("Day", selection: selection) {
			ForEach(datasets.indices, id: \.self) { index in
				let data = datasets[index]
				Text(relativeDayLabel(for: data.day)).tag(index)
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
}

@available(iOS 17.0, *)
#Preview {
	DailyPricingView(schedule: .mock)
		.padding()
		.withFontRegistration()
}
