// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension DailyPricingView {
  /// A compact badge indicating discount availability for the selected day.
  struct OfferBadge: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The visual and content state of the badge.
    package enum State: Hashable, Sendable {
      case active(DailyPriceChartData.DiscountSpan)
      case upcoming(DailyPriceChartData.DiscountSpan)
      case none
    }

    private var state: State
    private var showsTimeRange: Bool

    package init(state: State, showsTimeRange: Bool = true) {
      self.state = state
      self.showsTimeRange = showsTimeRange
    }

    package var body: some View {
      HStack(spacing: 6) {
        if shouldShowIcon {
          icon
        }
        label
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(backgroundShape.fill(background))
      .clipShape(backgroundShape)
      .foregroundStyle(foreground)
      .typography(.copy(size: .small), weight: .bold)
      .transformEffect(.identity)
    }

    private var backgroundShape: some Shape {
      if dynamicTypeSize < .accessibility1 {
        AnyShape(Capsule())
      } else {
        AnyShape(RoundedRectangle(cornerRadius: 12))
      }
    }

    @ViewBuilder private var label: some View {
      switch state {
      case let .active(span),
           let .upcoming(span):
        if showsTimeRange {
          adaptiveLabel(prefix: Text("Offer available:", bundle: .elvahCharge), span: span)
        } else {
          Text("Offer available", bundle: .elvahCharge)
        }
      case .none:
        Text("No offer available", bundle: .elvahCharge)
      }
    }

    @ViewBuilder private func adaptiveLabel(prefix: Text, span: DailyPriceChartData.DiscountSpan) -> some View {
      AdaptiveHStack(horizontalAlignment: .leading, spacing: 4) {
        prefix
        timeRangeText(span).foregroundStyle(.primaryContent)
      }
    }

    /// SF Symbol name depending on state.
    private var icon: Image {
      switch state {
      case .active,
           .upcoming:
        Image(.localOffer)
      case .none:
        Image(.localOfferUnavailable)
      }
    }

    private var shouldShowIcon: Bool {
      dynamicTypeSize < .accessibility1
    }

    /// Foreground color depending on state.
    private var foreground: Color {
      switch state {
      case .active,
           .upcoming:
        .brand
      case .none:
        .secondaryContent
      }
    }

    /// Background color depending on state.
    private var background: Color {
      switch state {
      case .active,
           .upcoming:
        Color.brand.opacity(0.1)
      case .none:
        Color.secondaryContent.opacity(0.15)
      }
    }

    /// Helper to format the time range.
    private func timeRangeText(_ span: DailyPriceChartData.DiscountSpan) -> Text {
      let start = Text(span.startTime, format: .dateTime.hour().minute())
      let end = Text(span.endTime, format: .dateTime.hour().minute())
      return Text("\(start) → \(end)")
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  // Build some sample spans for today
  let calendar = Calendar.current
  let day = calendar.startOfDay(for: Date())
  let start1 = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: day) ?? day
  let end1 = calendar.date(bySettingHour: 16, minute: 0, second: 0, of: day) ?? day
  let start2 = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: day) ?? day
  let end2 = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: day) ?? day

  let active = DailyPriceChartData.DiscountSpan(
    startTime: start1,
    endTime: end1,
    price: Currency(0.48)
  )
  let upcoming = DailyPriceChartData.DiscountSpan(
    startTime: start2,
    endTime: end2,
    price: Currency(0.52)
  )

  VStack(alignment: .leading, spacing: 12) {
    DailyPricingView.OfferBadge(state: .active(active))
    DailyPricingView.OfferBadge(state: .upcoming(upcoming))
    DailyPricingView.OfferBadge(state: .none)
  }
  .padding()
  .withFontRegistration()
}
