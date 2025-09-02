// Copyright © elvah. All rights reserved.

import Charts
import SwiftUI

/// A simple SwiftUI chart that visualizes discounted pricing slots across a day.
///
/// - Note: Requires iOS 16 since it uses the Charts framework.
@available(iOS 16.0, *)
public struct ChargeSitePricingChart: View {
	/// Chart data representing the selected day.
	public var data: ChargeSitePricingChartData

	public init(data: ChargeSitePricingChartData) {
		self.data = data
	}

	public var body: some View {
		Chart {
			// Baseline band across non-discount ranges only (interrupted by green)
			ForEach(nonDiscountSegments(), id: \.start) { segment in
				RectangleMark(
					xStart: .value("Start", segment.start),
					xEnd: .value("End", segment.end),
					yStart: .value("Zero", 0.0),
					yEnd: .value("Base", data.basePrice.amount)
				)
				.foregroundStyle(.gray.opacity(0.15))

				RuleMark(
					xStart: .value("Start", segment.start),
					xEnd: .value("End", segment.end),
					y: .value("Base Line", data.basePrice.amount)
				)
				.foregroundStyle(.gray)
			}

			// Discounted segments (green overlay)
			ForEach(discountSegments(), id: \.start) { segment in
				RectangleMark(
					xStart: .value("Start", segment.start),
					xEnd: .value("End", segment.end),
					yStart: .value("Zero", 0.0),
					yEnd: .value("Price", segment.price)
				)
				.foregroundStyle(.green.opacity(0.25))

				RuleMark(
					xStart: .value("Start", segment.start),
					xEnd: .value("End", segment.end),
					y: .value("Price Line", segment.price)
				)
				.foregroundStyle(.green)
			}
		}
		.chartXAxis {
			// Show ticks at 4-hour intervals across the day.
			AxisMarks(values: .stride(by: .hour, count: 4)) { value in
				AxisGridLine()
				AxisTick()
				AxisValueLabel(format: .dateTime.hour(.twoDigits(amPM: .omitted)))
			}
		}
		.chartXScale(domain: fullDayDomain(for: data.day))
	}

	// MARK: - Helpers

	/// Full day domain from midnight to midnight + 24h for consistent x-axis.
	private func fullDayDomain(for day: Date) -> ClosedRange<Date> {
		let calendar = Calendar.current
		let start = calendar.startOfDay(for: day)
		let end = calendar.date(byAdding: .hour, value: 24, to: start) ?? start
		return start ... end
	}

	/// Build non-overlapping discount segments from the step points in the data.
	private func discountSegments() -> [(start: Date, end: Date, price: Double)] {
		let points = data.points.sorted(by: { $0.time < $1.time })
		var result: [(Date, Date, Double)] = []
		var index = 0
		while index + 1 < points.count {
			let start = points[index]
			let end = points[index + 1]
			result.append((start.time, end.time, start.priceValue))
			index += 2
		}
		return result
	}

	/// Non-discount segments = full-day domain minus discount segments.
	private func nonDiscountSegments() -> [(start: Date, end: Date)] {
		let domain = fullDayDomain(for: data.day)
		// Clip discount segments to the domain first
		let clipped = discountSegments()
			.compactMap { segment -> (Date, Date) in
				let startTime = max(segment.start, domain.lowerBound)
				let endTime = min(segment.end, domain.upperBound)
				return (startTime, endTime)
			}
			.filter { startTime, endTime in startTime < endTime }
			.sorted { $0.0 < $1.0 }

		var result: [(Date, Date)] = []
		var cursor = domain.lowerBound
		for (startTime, endTime) in clipped {
			if cursor < startTime {
				result.append((cursor, startTime))
			}
			cursor = max(cursor, endTime)
		}
		if cursor < domain.upperBound {
			result.append((cursor, domain.upperBound))
		}
		return result
	}
}

// MARK: - Preview

@available(iOS 16.0, *)
#Preview("Pricing Chart") {
	let schedule = ChargeSitePricingSchedule.mock
	let chartData = schedule.makeChart(for: Date())
	return ChargeSitePricingChart(data: chartData)
		.frame(height: 180)
		.padding()
}
