// Copyright © elvah. All rights reserved.

import SwiftUI

/// Daily pricing composite view hosting a summary header and a three-day price chart pager.
@available(iOS 16.0, *)
package struct PricingScheduleViewComponent: View {
	/// Precomputed chart entries to avoid recomputation on redraw.
	package var chartEntries: [PricingScheduleChartEntry]

	/// Currently selected day in the pager. Defaults to today if available.
	@State private var selectedDay: PricingSchedule.RelativeDay

	/// Selected moment within the chart to reflect in the summary.
	@State private var selectedMoment: Date?

	/// Create the component with precomputed chart entries.
	package init(chartEntries: [PricingScheduleChartEntry]) {
		self.chartEntries = chartEntries
		let availableDays = chartEntries.map(\.day)
		let initial = availableDays.contains(.today) ? .today : (availableDays.first ?? .today)
		_selectedDay = State(initialValue: initial)
	}

	package var body: some View {
		VStack(spacing: 12) {
			if let current = chartEntries.first(where: { $0.day == selectedDay })?.dataset {
				Summary(dataset: current, selectedMoment: $selectedMoment).padding(.horizontal)
					.animation(.default, value: selectedDay)
					.animation(.default, value: selectedMoment)
			}

			TabView(selection: $selectedDay) {
				ForEach(chartEntries) { entry in
					PriceChart(data: entry.dataset, selectedMoment: $selectedMoment)
						.padding(.vertical, 4)
						.frame(maxWidth: .infinity)
						.tag(entry.day)
				}
			}
			.frame(height: 150)
			.tabViewStyle(.page(indexDisplayMode: .never))
			.animation(.default, value: selectedDay)
			.animation(.default, value: selectedMoment)

			if chartEntries.count >= 2 {
				dayPicker(chartEntries: chartEntries, selection: $selectedDay)
					.padding(.horizontal)
			}
		}
		.onChange(of: selectedDay) { _ in
			// Reset any specific time selection when switching days
			selectedMoment = nil
		}
		.onChange(of: chartEntries.map(\.day)) { available in
			// Adjust selected day when available pairs change (e.g., after async computation)
			let preferred = available.contains(.today) ? .today : (available.first ?? .today)
			if preferred != selectedDay {
				selectedDay = preferred
				selectedMoment = nil
			}
		}
	}

	/// Segmented control to switch between available days.
	private func dayPicker(
		chartEntries: [PricingScheduleChartEntry],
		selection: Binding<PricingSchedule.RelativeDay>
	) -> some View {
		Picker(selection: selection) {
			ForEach(chartEntries) { entry in
				Text(relativeDayLabel(for: entry.day)).tag(entry.day)
			}
		} label: {
			Text("Day", bundle: .elvahCharge)
		}
		.pickerStyle(.segmented)
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
	let schedule = PricingSchedule.mock
	let entries = schedule.chartEntries()
	PricingScheduleViewComponent(chartEntries: entries)
		.withFontRegistration()
}
