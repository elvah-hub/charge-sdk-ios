// Copyright © elvah. All rights reserved.

import Charts
import SwiftUI

@available(iOS 16.0, *)
package extension PricingScheduleView {
	/// Single-day price chart using Swift Charts. Migrated from `DailyPriceChart`.
	struct PriceChart: View {
		/// Chart data representing the selected day.
		package var data: DailyPriceChartData

		/// Selected point in time within the chart, used to highlight a block.
		/// Routed from the parent so summary and chart stay in sync.
		@Binding package var selectedMoment: Date?

		package init(data: DailyPriceChartData, selectedMoment: Binding<Date?>) {
			self.data = data
			_selectedMoment = selectedMoment
		}

		package var body: some View {
			TimelineView(.periodic(from: .now, by: 60)) { context in
				Chart {
					hourGrid
					baselineBand
					discountedSegments
					discountBoundaries
					if isToday {
						currentTimeMarker(now: context.date)
					}
				}
				.animation(.default, value: context.date)
				.animation(.default, value: selectedMoment)
				.chartOverlay { proxy in
					GeometryReader { geometry in
						// Transparent interactive layer for tap selection only (does not block swipes).
						Rectangle()
							.fill(.clear)
							.contentShape(Rectangle())
							.gesture(
								SpatialTapGesture()
									.onEnded { event in
										updateSelection(from: event.location, proxy: proxy, geometry: geometry)
									},
							)
					}
				}
			}
			.chartXAxis {
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
			.chartXScale(domain: PricingComputation.fullDayDomain(for: data.day))
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
					yEnd: .value("Base", data.basePrice.amount),
				)
				.foregroundStyle(.gray.opacity(0.15))
				.lineStyle(StrokeStyle(lineWidth: 1))
				.opacity(opacityForMark(in: segment.startTime, to: segment.endTime))

				RuleMark(
					xStart: .value("Start", segment.startTime),
					xEnd: .value("End", segment.endTime),
					y: .value("Base Line", data.basePrice.amount),
				)
				.foregroundStyle(.gray)
				.lineStyle(StrokeStyle(lineWidth: 1))
				.opacity(opacityForMark(in: segment.startTime, to: segment.endTime))
			}
		}

		/// Discounted segments fill and price line overlay.
		private var discountedSegments: some ChartContent {
			ForEach(data.discounts) { segment in
				RectangleMark(
					xStart: .value("Start", segment.startTime),
					xEnd: .value("End", segment.endTime),
					yStart: .value("Zero", 0.0),
					yEnd: .value("Price", segment.price.amount),
				)
				.foregroundStyle(.green.opacity(0.25))
				.lineStyle(StrokeStyle(lineWidth: 1))
				.opacity(opacityForMark(in: segment.startTime, to: segment.endTime))

				RuleMark(
					xStart: .value("Start", segment.startTime),
					xEnd: .value("End", segment.endTime),
					y: .value("Price Line", segment.price.amount),
				)
				.foregroundStyle(.fixedGreen)
				.lineStyle(StrokeStyle(lineWidth: 1))
				.opacity(opacityForMark(in: segment.startTime, to: segment.endTime))
			}
		}

		/// Solid vertical borders at discount edges from base down to discount price.
		private var discountBoundaries: some ChartContent {
			ForEach(data.discounts) { segment in
				RuleMark(
					x: .value("Boundary Start", segment.startTime),
					yStart: .value("Base", data.basePrice.amount),
					yEnd: .value("Price", segment.price.amount),
				)
				.foregroundStyle(.gray)
				.lineStyle(StrokeStyle(lineWidth: 1))
				.opacity(selectedMoment == nil ? 1 : 0.25)

				RuleMark(
					x: .value("Boundary End", segment.endTime),
					yStart: .value("Base", data.basePrice.amount),
					yEnd: .value("Price", segment.price.amount),
				)
				.foregroundStyle(.gray)
				.lineStyle(StrokeStyle(lineWidth: 1))
				.opacity(selectedMoment == nil ? 1 : 0.25)
			}
		}

		@ChartContentBuilder
		private func currentTimeMarker(now: Date) -> some ChartContent {
			let price = PricingComputation.currentPrice(at: now, in: data)
			let isDiscount = PricingComputation.isDiscounted(at: now, in: data)
			let markerColor: Color = isDiscount ? .fixedGreen : .gray

			RuleMark(
				x: .value("Now", now),
				yStart: .value("Zero", 0.0),
				yEnd: .value("Current Price", price),
			)
			.foregroundStyle(markerColor)
			.lineStyle(StrokeStyle(lineWidth: 2))

			PointMark(x: .value("Now", now), y: .value("Current Price", price))
				.symbol(.circle)
				.symbolSize(100)
				.foregroundStyle(markerColor)

			PointMark(x: .value("Now", now), y: .value("Current Price", price))
				.symbol(.circle)
				.symbolSize(30)
				.foregroundStyle(.white)
		}

		// MARK: - Helpers

		/// Updates the selection from a screen location by converting it to a chart x-value (Date).
		private func updateSelection(from location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
			let origin = geometry[proxy.plotAreaFrame].origin
			let plotLocation = CGPoint(x: location.x - origin.x, y: location.y - origin.y)
			if let tapped: Date = proxy.value(atX: plotLocation.x, as: Date.self) {
				// Toggle: tapping same block clears selection; otherwise select tapped moment.
				if let current = selectedMoment,
				   let currentRange = PricingComputation.segmentRange(containing: current, in: data),
				   let tappedRange = PricingComputation.segmentRange(containing: tapped, in: data),
				   currentRange == tappedRange {
					selectedMoment = nil
				} else {
					selectedMoment = tapped
				}
			}
		}

		/// Opacity for a mark representing a time range, based on the current selection.
		private func opacityForMark(in start: Date, to end: Date) -> Double {
			guard let selected = selectedMoment else {
				return 1.0
			}
			// Only dim if the selection is inside this day's domain.
			let domain = PricingComputation.fullDayDomain(for: data.day)
			guard domain.contains(selected) else {
				return 1.0
			}
			return (selected >= start && selected < end) ? 1.0 : 0.25
		}

		/// Y-axis domain from zero up to base price plus a small headroom.
		private func yAxisDomain() -> ClosedRange<Double> {
			let upper = data.basePrice.amount + 0.1
			return 0 ... max(upper, 0.2)
		}

		/// True if the chart represents today's date (used to show the time marker).
		private var isToday: Bool { Calendar.current.isDate(Date(), inSameDayAs: data.day) }

		/// Returns true if the given `Date` is at the top of an hour equal to midnight.
		private func isMidnight(_ date: Date) -> Bool {
			Calendar.current.component(.hour, from: date) == 0
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
	}
}

@available(iOS 17.0, *)
#Preview("PriceChart (Today)") {
	PricingScheduleView.PriceChart(data: PricingSchedule.mock.chartData()[1], selectedMoment: .constant(nil))
		.frame(height: 180)
		.padding()
		.withFontRegistration()
}
