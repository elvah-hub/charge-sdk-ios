// Copyright © elvah. All rights reserved.

import SwiftUI

/// Daily pricing composite view hosting a summary header and a three-day price chart pager.
@available(iOS 16.0, *)
package struct PricingScheduleView: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @ObservedObject private var router: LivePricingView.Router

  /// Currently selected day in the pager. Defaults to today if available.
  @State private var selectedDay: PricingSchedule.RelativeDay = .today

  /// Selected moment within the chart to reflect in the summary.
  @State private var selectedMoment: Date?

  /// Cached chart entries per relative day, computed when `schedule` changes.
  private var chartEntries: [PricingScheduleChartEntry] {
    schedule.chartEntries
  }

  /// The pricing schedule to visualize.
  private var schedule: ChargeSiteSchedule

  /// Whether to hide operator details in the header.
  private var isOperatorDetailsHidden: Bool

  /// Whether to hide the charge now button.
  private var isChargeButtonHidden: Bool

  /// Optional horizontal inset for the summary and primary action button.
  private var horizontalAreaPaddings: [LivePricingView.ComponentArea: CGFloat]

  /// Accent color for discount highlights throughout the schedule.
  private var discountHighlightColor: Color

  /// Create the component with precomputed chart entries.
  package init(
    schedule: ChargeSiteSchedule,
    router: LivePricingView.Router,
    isOperatorDetailsHidden: Bool = false,
    isChargeButtonHidden: Bool = false,
    horizontalAreaPaddings: [LivePricingView.ComponentArea: CGFloat] = [:],
    discountHighlightColor: Color,
  ) {
    self.schedule = schedule
    self.router = router
    self.isOperatorDetailsHidden = isOperatorDetailsHidden
    self.isChargeButtonHidden = isChargeButtonHidden
    self.horizontalAreaPaddings = horizontalAreaPaddings
    self.discountHighlightColor = discountHighlightColor
  }

  package var body: some View {
    VStack(spacing: .size(.L)) {
      // Header with operator name and address
      if isOperatorDetailsHidden == false,
         let operatorName = schedule.chargeSite.operatorName,
         let address = schedule.chargeSite.address {
        Header(title: operatorName, address: address)
          .padding(.horizontal, horizontalAreaPaddings[.header])
      }

      if let current = chartEntries.first(where: { $0.day == selectedDay })?.dataset {
        Summary(
          dataset: current,
          schedule: schedule,
          router: router,
          selectedMoment: $selectedMoment,
          discountHighlightColor: discountHighlightColor,
        )
        .padding(.horizontal, horizontalAreaPaddings[.header])
        .animation(.default, value: selectedDay)
        .animation(.default, value: selectedMoment)
      }

      VStack(spacing: .size(.M)) {
        TabView(selection: $selectedDay) {
          ForEach(chartEntries) { entry in
            PriceChart(
              dataset: entry.dataset,
              selectedMoment: $selectedMoment,
              discountHighlightColor: discountHighlightColor,
            )
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .tag(entry.day)
          }
        }
        .frame(height: dynamicTypeSize.isAccessibilitySize ? 200 : 140)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.default, value: selectedDay)
        .animation(.default, value: selectedMoment)

        if chartEntries.count >= 2 {
          dayPicker(chartEntries: chartEntries, selection: $selectedDay)
            .padding(.horizontal, horizontalAreaPaddings[.footer])
        }
      }

      if isChargeButtonHidden == false {
        Button("Charge now", icon: .bolt) {
          router.chargeOfferDetail = schedule
        }
        .buttonStyle(.primary)
        .padding(.horizontal, horizontalAreaPaddings[.footer])
      }
    }
    .accessibilityElement(children: .contain)
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
    .dynamicTypeSize(...(.accessibility1))
  }

  /// Segmented control to switch between available days.
  private func dayPicker(
    chartEntries: [PricingScheduleChartEntry],
    selection: Binding<PricingSchedule.RelativeDay>,
  ) -> some View {
    Picker(selection: selection) {
      ForEach(chartEntries) { entry in
        Text(relativeDayLabel(for: entry.day)).tag(entry.day)
      }
    } label: {
      EmptyView()
    }
    .labelsHidden()
    .pickerStyle(.segmented)
  }

  /// Returns a localized label for the given relative day.
  private func relativeDayLabel(for day: PricingSchedule.RelativeDay) -> LocalizedStringKey {
    switch day {
    case .yesterday:
      "Yesterday"
    case .today:
      "Today"
    case .tomorrow:
      "Tomorrow"
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  let schedule = ChargeSiteSchedule.mock
  LivePricingView(schedule: schedule)
    .withFontRegistration()
    .preferredColorScheme(.dark)
}
