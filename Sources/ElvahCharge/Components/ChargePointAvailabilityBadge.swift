// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargePointAvailabilityBadge: View {
  let chargePoints: [ChargePoint]
  let includeOutOfService: Bool

  var body: some View {
    Text(verbatim: availabilityTitle)
      .typography(.copy(size: .small), weight: .bold)
      .foregroundStyle(availabilityTitleColor)
      .padding(.horizontal, .XS)
      .padding(.vertical, .XXS)
      .background(
        Capsule()
          .fill(availabilityBackgroundColor),
      )
  }

  private var availabilityTitle: String {
    "\(availableNumberOfChargePoints)/\(totalNumberOfChargePoints)"
  }

  private var availabilityTitleColor: Color {
    if availableNumberOfChargePoints > 0 {
      .onSuccess
    } else {
      .red
    }
  }

  private var availabilityBackgroundColor: Color {
    if availableNumberOfChargePoints > 0 {
      .success
    } else {
      .red.opacity(0.1)
    }
  }

  private var availableNumberOfChargePoints: Int {
    chargePoints.count(where: { $0.isAvailable })
  }

  private var totalNumberOfChargePoints: Int {
    if includeOutOfService {
      chargePoints.count
    } else {
      chargePoints.count(where: { $0.isOutOfService == false })
    }
  }
}

@available(iOS 16.0, *)
#Preview {
  ZStack {
    Color.canvas.ignoresSafeArea()
    ChargePointAvailabilityBadge(
      chargePoints: [.mockAvailable, .mockUnavailable, .mockOutOfService],
      includeOutOfService: true,
    )
  }
  .withFontRegistration()
}
