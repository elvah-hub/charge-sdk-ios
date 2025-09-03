// Copyright © elvah. All rights reserved.

import Charts
import SwiftUI

@available(iOS 16.0, *)
public struct ChargeSitePricingChart: View {
	/// Chart data representing the selected day.
	public var data: ChargeSitePricingChartData

	public init(data: ChargeSitePricingChartData) {
		self.data = data
	}

	public var body: some View {
		Chart {
			// Hour grid: solid at midnights, dotted every 4 hours otherwise
			ForEach(hourlyTicks(for: data.day), id: \.self) { tick in
				if isMidnight(tick) {
					RuleMark(x: .value("Hour", tick))
						.foregroundStyle(.gray)
						.lineStyle(StrokeStyle(lineWidth: 1))
						.offset(y: 1)
				} else {
					RuleMark(x: .value("Hour", tick))
						.foregroundStyle(.gray.opacity(0.3))
						.lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
						.offset(y: 1)
				}
			}

			// Baseline band across non-discount ranges only (interrupted by green)
			ForEach(nonDiscountSegments()) { segment in
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
				.offset(y: 1)
			}

			// Discounted segments (green overlay)
			ForEach(discountSegments()) { segment in
				RectangleMark(
					xStart: .value("Start", segment.startTime),
					xEnd: .value("End", segment.endTime),
					yStart: .value("Zero", 0.0),
					yEnd: .value("Price", segment.price)
				)
				.foregroundStyle(.green.opacity(0.25))
				.lineStyle(StrokeStyle(lineWidth: 1))

				RuleMark(
					xStart: .value("Start", segment.startTime),
					xEnd: .value("End", segment.endTime),
					y: .value("Price Line", segment.price)
				)
				.foregroundStyle(.brand)
				.lineStyle(StrokeStyle(lineWidth: 1))
				.offset(y: 1)
			}

			// Solid vertical borders at discount edges from base down to discount price
			ForEach(discountSegments()) { segment in
				RuleMark(
					x: .value("Boundary Start", segment.startTime),
					yStart: .value("Base", data.basePrice.amount),
					yEnd: .value("Price", segment.price)
				)
				.foregroundStyle(.gray)
				.lineStyle(StrokeStyle(lineWidth: 1))
				.offset(y: 1)

				RuleMark(
					x: .value("Boundary End", segment.endTime),
					yStart: .value("Base", data.basePrice.amount),
					yEnd: .value("Price", segment.price)
				)
				.foregroundStyle(.gray)
				.lineStyle(StrokeStyle(lineWidth: 1))
				.offset(y: 1)
			}
		}
		.chartXAxis {
			// Show ticks/labels at fixed 4-hour points including 24:00 (next midnight)
				AxisMarks(values: hourlyTicks(for: data.day)) { _ in
					AxisValueLabel(
						format: .dateTime.hour(.twoDigits(amPM: .omitted)),
						centered: false,
						anchor: .top,
						offsetsMarks: false,
						orientation: .horizontal,
						horizontalSpacing: 0
					)
					.font(.caption.bold())
				}
		}
			// Hide all Y-axis elements (grid lines, ticks, labels)
			.chartYAxis(.hidden)
			.chartXScale(domain: fullDayDomain(for: data.day))
			.chartYScale(domain: yAxisDomain())
	}

	// MARK: - Helpers

	/// Full day domain from midnight to midnight + 24h for consistent x-axis.
	private func fullDayDomain(for day: Date) -> ClosedRange<Date> {
		let calendar = Calendar.current
		let start = calendar.startOfDay(for: day)
		let end = calendar.date(byAdding: .hour, value: 24, to: start) ?? start
		return start ... end.addingTimeInterval(1)
	}

	/// Y-axis domain from zero up to base price plus a small headroom.
	/// Adds 0.20 (20 cents) to ensure the baseline line has visual breathing room.
	private func yAxisDomain() -> ClosedRange<Double> {
		let upper = data.basePrice.amount + 0.1
		return 0 ... max(upper, 0.2)
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

	/// Extracts discount pricing segments from the chart data points.
	///
	/// Each discount slot is represented by two consecutive points in the data:
	/// the start point (with pricing) and the end point (marking the end of that price).
	/// We pair these points to create segments showing when discounted pricing applies.
	private func discountSegments() -> [PricingSegment] {
		let sortedPoints = data.points.sorted { $0.time < $1.time }
		var segments: [PricingSegment] = []

		// Process points in pairs: (start, end), (start, end), etc.
		var index = 0
		while index + 1 < sortedPoints.count {
			let startPoint = sortedPoints[index]
			let endPoint = sortedPoints[index + 1]

			let segment = PricingSegment(startPoint: startPoint, endPoint: endPoint)
			segments.append(segment)

			// Skip to next pair (increment by 2)
			index += 2
		}

		return segments
	}

	/// Calculates time segments that are NOT covered by discount pricing.
	///
	/// This creates the gray baseline areas by finding gaps between discount segments
	/// across the full day domain (midnight to midnight).
	private func nonDiscountSegments() -> [TimeSegment] {
		let fullDayRange = fullDayDomain(for: data.day)

		// Get discount segments and clip them to the full day range
		let clippedDiscountSegments = discountSegments()
			.compactMap { segment -> (start: Date, end: Date)? in
				let clippedStart = max(segment.startTime, fullDayRange.lowerBound)
				let clippedEnd = min(segment.endTime, fullDayRange.upperBound)

				// Only include segments that have valid time ranges after clipping
				guard clippedStart < clippedEnd else {
					return nil
				}
				return (start: clippedStart, end: clippedEnd)
			}
			.sorted { $0.start < $1.start }

		var nonDiscountSegments: [TimeSegment] = []
		var currentTime = fullDayRange.lowerBound

		// Fill gaps between discount segments
		for discountSegment in clippedDiscountSegments {
			// Add segment before this discount (if there's a gap)
			if currentTime < discountSegment.start {
				let gapSegment = TimeSegment(start: currentTime, end: discountSegment.start)
				nonDiscountSegments.append(gapSegment)
			}

			// Move past this discount segment
			currentTime = max(currentTime, discountSegment.end)
		}

		// Add final segment after the last discount (if there's remaining time)
		if currentTime < fullDayRange.upperBound {
			let finalSegment = TimeSegment(start: currentTime, end: fullDayRange.upperBound)
			nonDiscountSegments.append(finalSegment)
		}

		return nonDiscountSegments
	}
}

@available(iOS 16.0, *)
private extension ChargeSitePricingChart {
	/// Represents a time segment with pricing information for discount visualization
	struct PricingSegment: Identifiable {
		let id = UUID()
		let startTime: Date
		let endTime: Date
		let price: Double

		/// Creates a pricing segment from two consecutive chart points
		init(startPoint: ChargeSitePricingChartData.Point, endPoint: ChargeSitePricingChartData.Point) {
			startTime = startPoint.time
			endTime = endPoint.time
			price = startPoint.priceValue
		}
	}

	/// Represents a time segment without specific pricing (uses base price)
	struct TimeSegment: Identifiable {
		let id = UUID()
		let startTime: Date
		let endTime: Date

		init(start: Date, end: Date) {
			startTime = start
			endTime = end
		}
	}
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview("Three-Day Scroll") {
	@Previewable @State var page = 1

	let schedule = ChargeSitePricingSchedule.mock
	let calendar = Calendar.current
	let today = calendar.startOfDay(for: Date())
	let days = [
		calendar.date(byAdding: .day, value: -1, to: today) ?? today,
		today,
		calendar.date(byAdding: .day, value: 1, to: today) ?? today,
	]
	let datasets = days.map { schedule.makeChart(for: $0) }

	return VStack(spacing: 12) {
		ChargeSitePricingChartThreeDays(datasets: datasets, page: $page)
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
public struct ChargeSitePricingChartThreeDays: View {
	/// Datasets for each day, typically yesterday, today, and tomorrow.
	public var datasets: [ChargeSitePricingChartData]

	/// Exposed currently selected page (0: yesterday, 1: today, 2: tomorrow)
	public var page: Binding<Int>

	public init(datasets: [ChargeSitePricingChartData], page: Binding<Int>) {
		self.datasets = datasets
		self.page = page
	}

	/// Convenience init that defaults to the first page
	public init(datasets: [ChargeSitePricingChartData]) {
		self.init(datasets: datasets, page: .constant(0))
	}

	public var body: some View {
		TabView(selection: page) {
			ForEach(Array(datasets.enumerated()), id: \.offset) { index, data in
				ChargeSitePricingChart(data: data)
					.frame(maxWidth: .infinity)
					.tag(index)
			}
		}
		.tabViewStyle(.page(indexDisplayMode: .never))
	}
}

// MARK: - Preview helpers
