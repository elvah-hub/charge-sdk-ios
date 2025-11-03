// Copyright © elvah. All rights reserved.

import Charts
import SwiftUI

@available(iOS 16.0, *)
package extension PricingScheduleView {
  /// Single-day price chart using Swift Charts. Migrated from `DailyPriceChart`.
  struct PriceChart: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var accessibilityDifferentiateWithoutColor

    /// Chart data representing the selected day.
    package var dataset: DailyPriceChartData

    /// Selected point in time within the chart, used to highlight a block.
    /// Routed from the parent so summary and chart stay in sync.
    @Binding package var selectedMoment: Date?

    /// Accent color for discount highlights.
    private var discountHighlightColor: Color

    package init(
      dataset: DailyPriceChartData,
      selectedMoment: Binding<Date?>,
      discountHighlightColor: Color,
    ) {
      self.dataset = dataset
      self.discountHighlightColor = discountHighlightColor
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
            currentTimeMarker(reference: context.date)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityChartLabelText)
        .accessibilityValue(accessibilityChartValueText)
      }
      .chartXAxis {
        if #available(iOS 17.0, *) {
          AxisMarks(preset: .aligned, values: hourlyTicks(for: dataset.day)) { _ in
            AxisValueLabel(format: .dateTime.hour(.twoDigits(amPM: .omitted)))
              .font(.caption.bold())
          }
        } else {
          AxisMarks(values: axisHourlyTicks(for: dataset.day)) { _ in
            AxisValueLabel(format: .dateTime.hour(.twoDigits(amPM: .omitted)))
              .font(.caption.bold())
          }
        }
      }
      .chartYAxis(.hidden)
      .chartXScale(domain: dataset.day.fullDayRange)
      .chartYScale(domain: yAxisDomain())
    }

    // MARK: - Chart content pieces

    /// Hour grid: solid at midnights, dotted every 4 hours otherwise.
    private var hourGrid: some ChartContent {
      ForEach(hourlyTicks(for: dataset.day), id: \.self) { tick in
        if isMidnight(tick) {
          RuleMark(x: .value(Text(verbatim: "Hour"), tick))
            .foregroundStyle(.gray.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 1))
        } else {
          RuleMark(x: .value(Text(verbatim: "Hour"), tick))
            .foregroundStyle(.gray.opacity(0.3))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
        }
      }
    }

    /// Baseline band across non-discount ranges only (interrupted by green).
    private var baselineBand: some ChartContent {
      ForEach(dataset.gaps) { segment in
        RectangleMark(
          xStart: .value(Text(verbatim: "Start"), segment.startTime),
          xEnd: .value(Text(verbatim: "End"), segment.endTime),
          yStart: .value(Text(verbatim: "Zero"), 0.0),
          yEnd: .value(Text(verbatim: "Base"), dataset.basePrice.amount),
        )
        .foregroundStyle(.gray.opacity(0.15))
        .lineStyle(StrokeStyle(lineWidth: 1))
        .opacity(opacityForMark(in: segment.startTime, to: segment.endTime))

        RuleMark(
          xStart: .value(Text(verbatim: "Start"), segment.startTime),
          xEnd: .value(Text(verbatim: "End"), segment.endTime),
          y: .value(Text(verbatim: "Base Line"), dataset.basePrice.amount),
        )
        .foregroundStyle(.gray)
        .lineStyle(StrokeStyle(lineWidth: 1))
        .opacity(opacityForMark(in: segment.startTime, to: segment.endTime))
      }
    }

    /// Discounted segments fill and price line overlay.
    private var discountedSegments: some ChartContent {
      ForEach(dataset.discounts) { segment in
        RectangleMark(
          xStart: .value(Text(verbatim: "Start"), segment.startTime),
          xEnd: .value(Text(verbatim: "End"), segment.endTime),
          yStart: .value(Text(verbatim: "Zero"), 0.0),
          yEnd: .value(Text(verbatim: "Price"), segment.price.amount),
        )
        .foregroundStyle(discountHighlightColor.opacity(0.25))
        .lineStyle(StrokeStyle(lineWidth: 1))
        .opacity(opacityForMark(in: segment.startTime, to: segment.endTime))
        .annotation(position: .overlay) {
          if accessibilityDifferentiateWithoutColor {
            Image(.discounting)
              .grayscale(1)
          }
        }

        RuleMark(
          xStart: .value(Text(verbatim: "Start"), segment.startTime),
          xEnd: .value(Text(verbatim: "End"), segment.endTime),
          y: .value(Text(verbatim: "Price Line"), segment.price.amount),
        )
        .foregroundStyle(discountHighlightColor)
        .lineStyle(StrokeStyle(lineWidth: 1))
        .opacity(opacityForMark(in: segment.startTime, to: segment.endTime))
      }
    }

    /// Solid vertical borders at discount edges from base down to discount price.
    private var discountBoundaries: some ChartContent {
      ForEach(dataset.discounts) { segment in
        RuleMark(
          x: .value(Text(verbatim: "Boundary Start"), segment.startTime),
          yStart: .value(Text(verbatim: "Base"), dataset.basePrice.amount),
          yEnd: .value(Text(verbatim: "Price"), segment.price.amount),
        )
        .foregroundStyle(.gray)
        .lineStyle(StrokeStyle(lineWidth: 1))
        .opacity(selectedMoment == nil ? 1 : 0.25)

        RuleMark(
          x: .value(Text(verbatim: "Boundary End"), segment.endTime),
          yStart: .value(Text(verbatim: "Base"), dataset.basePrice.amount),
          yEnd: .value(Text(verbatim: "Price"), segment.price.amount),
        )
        .foregroundStyle(.gray)
        .lineStyle(StrokeStyle(lineWidth: 1))
        .opacity(selectedMoment == nil ? 1 : 0.25)
      }
    }

    @ChartContentBuilder
    private func currentTimeMarker(reference: Date) -> some ChartContent {
      let price = dataset.price(at: reference)
      let isDiscount = dataset.hasDiscount(at: reference)
      let markerColor: Color = isDiscount ? discountHighlightColor : .gray

      RuleMark(
        x: .value(Text(verbatim: "Now"), reference),
        yStart: .value(Text(verbatim: "Zero"), 0.0),
        yEnd: .value(Text(verbatim: "Current Price"), price.amount),
      )
      .foregroundStyle(markerColor)
      .lineStyle(StrokeStyle(lineWidth: 2))

      PointMark(x: .value(Text(verbatim: "Now"), reference), y: .value(Text(verbatim: "Current Price"), price.amount))
        .symbol(.circle)
        .symbolSize(100)
        .foregroundStyle(markerColor)

      PointMark(x: .value(Text(verbatim: "Now"), reference), y: .value(Text(verbatim: "Current Price"), price.amount))
        .symbol(.circle)
        .symbolSize(30)
        .foregroundStyle(.white)
    }

    // MARK: - Helpers

    /// Updates the selection from a screen location by converting it to a chart x-value (Date).
    private func updateSelection(from location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
      let origin = geometry[proxy.plotAreaFrame].origin
      let plotLocation = CGPoint(x: location.x - origin.x, y: location.y - origin.y)
      if let tappedDate: Date = proxy.value(atX: plotLocation.x, as: Date.self) {
        if let currentMoment = selectedMoment,
           let currentRange = dataset.dateRangeOfSegment(containing: currentMoment),
           let tappedRange = dataset.dateRangeOfSegment(containing: tappedDate),
           currentRange == tappedRange {
          selectedMoment = nil
        } else {
          selectedMoment = tappedDate
        }
      }
    }

    /// Opacity for a mark representing a time range, based on the current selection.
    private func opacityForMark(in start: Date, to end: Date) -> Double {
      guard let selected = selectedMoment else {
        return 1.0
      }

      // Only dim if the selection is inside this day's domain.
      let domain = dataset.day.fullDayRange

      guard domain.contains(selected) else {
        return 1.0
      }
      return (selected >= start && selected < end) ? 1.0 : 0.25
    }

    /// Y-axis domain from zero up to base price plus a small headroom.
    private func yAxisDomain() -> ClosedRange<Double> {
      let upper = dataset.basePrice.amount + 0.1
      return 0 ... max(upper, 0.2)
    }

    /// True if the chart represents today's date (used to show the time marker).
    private var isToday: Bool { Calendar.current.isDate(Date(), inSameDayAs: dataset.day) }

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

    /// Accessibility label describing the chart.
    private var accessibilityChartLabelText: Text {
      Text(
        """
        Price chart, \(Text(relativeDayLabel)), \
        base price \(Text(dataset.basePrice.formatted())) per kilowatt-hour
        """,
        bundle: .elvahCharge,
      )
    }

    /// Accessibility value summarizing discount windows including price per offer.
    private var accessibilityChartValueText: Text {
      let discounts = dataset.discounts
      guard discounts.isEmpty == false else {
        return Text("No offer windows", bundle: .elvahCharge)
      }

      // Build fixed variations for better localization and reuse across platforms.
      let firstDiscount = discounts[0]
      let firstDiscountText = offerAccessibilityText(for: firstDiscount)

      if discounts.count == 1 {
        return Text("Offer windows: \(firstDiscountText)", bundle: .elvahCharge)
      }

      let secondDiscount = discounts[1]
      let secondDiscountText = offerAccessibilityText(for: secondDiscount)

      if discounts.count == 2 {
        return Text("Offer windows: \(firstDiscountText) and \(secondDiscountText)", bundle: .elvahCharge)
      }

      let remainingCount = discounts.count - 2
      return Text(
        "Offer windows: \(firstDiscountText), \(secondDiscountText), and \(remainingCount) more",
        bundle: .elvahCharge,
      )
    }

    private func offerAccessibilityText(for discount: DailyPriceChartData.DiscountSpan) -> Text {
      let priceText = Text("\(discount.price.formatted()) per kilowatt-hour", bundle: .elvahCharge)
      return Text(verbatim: "\(priceText), \(discount.timeRangeAccessibilityText)")
    }

    /// Relative day label for accessibility.
    private var relativeDayLabel: LocalizedStringKey {
      let calendar = Calendar.current

      if calendar.isDateInYesterday(dataset.day) {
        return "Yesterday"
      }
      if calendar.isDateInTomorrow(dataset.day) {
        return "Tomorrow"
      }

      return "Today"
    }
  }
}

@available(iOS 17.0, *)
#Preview("PriceChart (Today)") {
  PricingScheduleView.PriceChart(
    dataset: PricingSchedule.mock.chartData()[1],
    selectedMoment: .constant(nil),
    discountHighlightColor: Color("fixed_green", bundle: .core),
  )
  .frame(height: 140)
  .withFontRegistration()
}
