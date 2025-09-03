// Copyright © elvah. All rights reserved.

import Charts
import SwiftUI

@available(iOS 16.0, *)
public struct DailyPriceChart: View {
	/// Chart data representing the selected day.
	public var data: DailyPriceChartData

	public init(data: DailyPriceChartData) {
		self.data = data
	}

	public var body: some View {
		Chart {
			hourGrid
			baselineBand
			discountedSegments
			discountBoundaries
			currentTimeMarker
		}
		.chartXAxis {
			// Show ticks/labels at fixed 4-hour points including 24:00 (next midnight)
			if #available(iOS 17.0, *) {
				AxisMarks(preset: .aligned, values: hourlyTicks(for: data.day)) { _ in
					AxisValueLabel(format: .dateTime.hour(.twoDigits(amPM: .omitted)))
						.font(.caption.bold())
				}
			} else {
				AxisMarks(values: axisHourlyTicks(for: data.day)) { _ in
					AxisValueLabel(format: .dateTime.hour(.twoDigits(amPM: .omitted)))
						.font(.caption.bold())
				}
			}
		}
		.chartYAxis(.hidden)
		.chartXScale(domain: fullDayDomain(for: data.day))
		.chartYScale(domain: yAxisDomain())
	}

	// MARK: - Chart content pieces

	/// Hour grid: solid at midnights, dotted every 4 hours otherwise.
	private var hourGrid: some ChartContent {
		ForEach(hourlyTicks(for: data.day), id: \.self) { tick in
			if isMidnight(tick) {
				RuleMark(x: .value("Hour", tick))
					.foregroundStyle(.gray.opacity(0.3))
					.lineStyle(StrokeStyle(lineWidth: 1))
			} else {
				RuleMark(x: .value("Hour", tick))
					.foregroundStyle(.gray.opacity(0.3))
					.lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
			}
		}
	}

	/// Baseline band across non-discount ranges only (interrupted by green).
	private var baselineBand: some ChartContent {
		ForEach(data.gaps) { segment in
			RectangleMark(
				xStart: .value("Start", segment.startTime),
				xEnd: .value("End", segment.endTime),
				yStart: .value("Zero", 0.0),
				yEnd: .value("Base", data.basePrice.amount)
			)
			.foregroundStyle(.gray.opacity(0.15))
			.lineStyle(StrokeStyle(lineWidth: 1))

			RuleMark(
				xStart: .value("Start", segment.startTime),
				xEnd: .value("End", segment.endTime),
				y: .value("Base Line", data.basePrice.amount)
			)
			.foregroundStyle(.gray)
			.lineStyle(StrokeStyle(lineWidth: 1))
		}
	}

	/// Discounted segments fill and price line overlay.
	private var discountedSegments: some ChartContent {
		ForEach(data.discounts) { segment in
			RectangleMark(
				xStart: .value("Start", segment.startTime),
				xEnd: .value("End", segment.endTime),
				yStart: .value("Zero", 0.0),
				yEnd: .value("Price", segment.price.amount)
			)
			.foregroundStyle(.green.opacity(0.25))
			.lineStyle(StrokeStyle(lineWidth: 1))

			RuleMark(
				xStart: .value("Start", segment.startTime),
				xEnd: .value("End", segment.endTime),
				y: .value("Price Line", segment.price.amount)
			)
			.foregroundStyle(.brand)
			.lineStyle(StrokeStyle(lineWidth: 1))
		}
	}

	/// Solid vertical borders at discount edges from base down to discount price.
	private var discountBoundaries: some ChartContent {
		ForEach(data.discounts) { segment in
			RuleMark(
				x: .value("Boundary Start", segment.startTime),
				yStart: .value("Base", data.basePrice.amount),
				yEnd: .value("Price", segment.price.amount)
			)
			.foregroundStyle(.gray)
			.lineStyle(StrokeStyle(lineWidth: 1))

			RuleMark(
				x: .value("Boundary End", segment.endTime),
				yStart: .value("Base", data.basePrice.amount),
				yEnd: .value("Price", segment.price.amount)
			)
			.foregroundStyle(.gray)
			.lineStyle(StrokeStyle(lineWidth: 1))
		}
	}

	@ChartContentBuilder
	private var currentTimeMarker: some ChartContent {
		let now = Date()
		let price = currentPrice(at: now)

		RuleMark(
			x: .value("Now", now),
			yStart: .value("Zero", 0.0),
			yEnd: .value("Current Price", price)
		)
		.foregroundStyle(.brand)
		.lineStyle(StrokeStyle(lineWidth: 2))

		// Outer green circle (ring)
		PointMark(
			x: .value("Now", now),
			y: .value("Current Price", price)
		)
		.symbol(.circle)
		.symbolSize(100)
		.foregroundStyle(.brand)

		// Inner white fill to create the ring effect
		PointMark(
			x: .value("Now", now),
			y: .value("Current Price", price)
		)
		.symbol(.circle)
		.symbolSize(30)
		.foregroundStyle(.white)
	}

	// MARK: - Helpers

	/// Full day domain from midnight to midnight + 24h for consistent x-axis.
	private func fullDayDomain(for day: Date) -> ClosedRange<Date> {
		let calendar = Calendar.current
		let start = calendar.startOfDay(for: day)
		let end = calendar.date(byAdding: .hour, value: 24, to: start) ?? start
		return start ... end
	}

	/// Y-axis domain from zero up to base price plus a small headroom.
	/// Adds 0.20 (20 cents) to ensure the baseline line has visual breathing room.
	private func yAxisDomain() -> ClosedRange<Double> {
		let upper = data.basePrice.amount + 0.1
		return 0 ... max(upper, 0.2)
	}

	/// True if the chart represents today's date (used to show the time marker).
	private var isToday: Bool {
		Calendar.current.isDate(Date(), inSameDayAs: data.day)
	}

	/// Returns true if the given `Date` is at the top of an hour equal to midnight.
	private func isMidnight(_ date: Date) -> Bool {
		let calendar = Calendar.current
		return calendar.component(.hour, from: date) == 0
	}

	/// Four-hour marks across a day used for vertical guide lines.
	private func hourlyTicks(for day: Date) -> [Date] {
		let calendar = Calendar.current
		let start = calendar.startOfDay(for: day)
		return Array(stride(from: 0, through: 24, by: 4)).compactMap { hour in
			calendar.date(byAdding: .hour, value: hour, to: start)
		}
	}

	/// Axis label ticks nudged inside the domain for iOS 16 rendering.
	private func axisHourlyTicks(for day: Date) -> [Date] {
		let calendar = Calendar.current
		let start = calendar.startOfDay(for: day)
		let end = calendar.date(byAdding: .hour, value: 24, to: start) ?? start
		let epsilon: TimeInterval = 1
		return hourlyTicks(for: day).map { tick in
			if tick == start {
				return tick.addingTimeInterval(epsilon)
			}
			if tick == end {
				return tick.addingTimeInterval(-epsilon)
			}
			return tick
		}
	}

	/// Price at a point in time for this day, considering discounts.
	private func currentPrice(at date: Date) -> Double {
		for seg in data.discounts {
			if date >= seg.startTime && date < seg.endTime {
				return seg.price.amount
			}
		}
		return data.basePrice.amount
	}
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview("Three-Day Scroll") {
	@Previewable @State var page = 1

	let schedule = PricingSchedule.mock
	let datasets = schedule.chartData()

	return VStack(spacing: 12) {
		DailyPriceChartPager(datasets: datasets, page: $page)
			.frame(height: 180)

		Picker("Day", selection: $page) {
			Text("Yesterday").tag(0)
			Text("Today").tag(1)
			Text("Tomorrow").tag(2)
		}
		.padding(.horizontal)
		.pickerStyle(.segmented)
	}
	.animation(.default, value: page)
}

// MARK: - Multi-day container

@available(iOS 16.0, *)
public struct DailyPriceChartPager: View {
	/// Datasets for each day, typically yesterday, today, and tomorrow.
	public var datasets: [DailyPriceChartData]

	/// Exposed currently selected page (0: yesterday, 1: today, 2: tomorrow)
	public var page: Binding<Int>

	public init(datasets: [DailyPriceChartData], page: Binding<Int>) {
		self.datasets = datasets
		self.page = page
	}

	/// Convenience init that defaults to the first page
	public init(datasets: [DailyPriceChartData]) {
		self.init(datasets: datasets, page: .constant(0))
	}

	public var body: some View {
		TabView(selection: page) {
			ForEach(Array(datasets.enumerated()), id: \.offset) { index, data in
				DailyPriceChart(data: data)
					.padding(.vertical, 4)
					.frame(maxWidth: .infinity)
					.tag(index)
			}
		}
		.tabViewStyle(.page(indexDisplayMode: .never))
	}
}
