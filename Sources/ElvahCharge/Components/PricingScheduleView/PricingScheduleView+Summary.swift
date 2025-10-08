// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension PricingScheduleView {
  /// Header view summarizing the current pricing state for the selected day.
  struct Summary: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var accessibilityDifferentiateWithoutColor

    /// Access to router to trigger navigation and sheet presentation.
    @ObservedObject private var router: LivePricingView.Router

    /// The dataset that the drives the summary for a specific day.
    private var dataset: DailyPriceChartData

    /// Selected moment binding to drive the summary instead of the current time.
    @Binding private var selectedMoment: Date?

    package init(
      dataset: DailyPriceChartData,
      router: LivePricingView.Router,
      selectedMoment: Binding<Date?>,
    ) {
      self.dataset = dataset
      _router = ObservedObject(wrappedValue: router)
      _selectedMoment = selectedMoment
    }

    /// Convenience init for previews/tests.
    package init(dataset: DailyPriceChartData) {
      self.dataset = dataset
      _router = ObservedObject(wrappedValue: LivePricingView.Router())
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Live Pricing", bundle: .elvahCharge))
        .accessibilityValue(accessibilityPriceValueText(reference: reference))
        .accessibilityAction {
          router.isShowingOtherPricesSheet = true
        }
      }
    }

    @ViewBuilder private func headerRow() -> some View {
      AdaptiveHStack(horizontalAlignment: .leading, verticalAlignment: .center, spacing: .size(.XXS)) { isHorizontal in
        HStack(spacing: .size(.XXS)) {
          Text("Live Pricing", bundle: .elvahCharge)
            .typography(.copy(size: .medium), weight: .bold)
            .foregroundStyle(.secondaryContent)
            .contentTransition(.interpolate)
            .accessibilityAddTraits(.isHeader)
        }
        if isHorizontal {
          Spacer()
        }
        Button {
          router.isShowingOtherPricesSheet = true
        } label: {
          HStack(spacing: .size(.XXXS)) {
            Text("CCS, Very fast (350 kW)")
              .typography(.copy(size: .medium))
              .foregroundStyle(.primaryContent)
            Image(.chevronSmallDown)
              .accessibilityHidden(true)
          }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondaryContent)
        .typography(.copy(size: .small), weight: .regular)
      }
    }

    @ViewBuilder private func priceRow(reference: Date) -> some View {
      let price = dataset.price(at: reference)
      let discounted = dataset.hasDiscount(at: reference)

      VStack(alignment: .leading, spacing: .size(.XXS)) {
        AdaptiveHStack(horizontalAlignment: .leading, verticalAlignment: .center, spacing: .size(.XXS)) {
          HStack {
            if accessibilityDifferentiateWithoutColor {
              Image(.discounting)
                .grayscale(1)
            }
            Text("\(price.formatted())/kWh", bundle: .elvahCharge)
              .typography(.copy(size: .xLarge), weight: .bold)
              .monospacedDigit()
              .foregroundStyle(discounted ? .fixedGreen : .primaryContent)
              .contentTransition(.numericText())
          }

          if discounted {
            Text("\(dataset.basePrice.formatted())/kWh", bundle: .elvahCharge)
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
        breakPoint: .xxLarge,
      ) {
        if let moment = selectedMoment, let range = dataset.dateRangeOfSegment(containing: moment) {
          Text("\(dayText) \(range.textRepresentation)")
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
      let calendar = Calendar.current

      // Reflect explicit selection when it falls within the day's domain
      if let selected = selectedMoment, dataset.day.fullDayRange.contains(selected) {
        if let active = dataset.discounts.activeSpan(at: reference) {
          return .active(active)
        }
        return .none
      }

      // For future days (tomorrow), show the first available offer of the day
      if calendar.isDateInTomorrow(dataset.day) {
        if let firstOffer = dataset.discounts.first {
          return .upcoming(firstOffer)
        }
        return .none
      }

      // Live evaluation for today based on the provided reference moment
      if let active = dataset.discounts.activeSpan(at: reference) {
        return .active(active)
      }

      if let next = dataset.discounts.nextSpan(after: reference) {
        return .upcoming(next)
      }

      return .none
    }

    // MARK: - Accessibility

    private func accessibilityPriceValueText(reference: Date) -> Text {
      let price = dataset.price(at: reference)
      let discounted = dataset.hasDiscount(at: reference)

      let priceText = Text("\(price.formatted()) per kilowatt-hour", bundle: .elvahCharge)
      var basePriceText: Text?

      if discounted {
        basePriceText = Text("\(dataset.basePrice.formatted()) per kilowatt-hour", bundle: .elvahCharge)
      }

      if let basePriceText, let segmentRange = dataset.dateRangeOfSegment(containing: reference) {
        return Text(
          """
          \(priceText), discounted \(segmentRange.accessibilityTextRepresentation). Original Price: \(basePriceText)
          """,
          bundle: .elvahCharge,
        )
      }
      return priceText
    }

    // MARK: - Helpers

    /// Computes the effective moment used by the Summary for pricing and state at a given timeline tick.
    ///
    /// Selection within the displayed day takes precedence. If there is no selection,
    /// the view behaves “live” for today (using `timelineNow`) and uses a stable noon
    /// fallback for non-today days to avoid misleading midnight values.
    private func displayReference(for timelineNow: Date) -> Date {
      let domain = dataset.day.fullDayRange
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
  PricingScheduleView.Summary(
    dataset: data,
    router: LivePricingView.Router(),
    selectedMoment: .constant(Date()),
  )
  .padding()
  .withFontRegistration()
  .preferredColorScheme(.dark)
}
