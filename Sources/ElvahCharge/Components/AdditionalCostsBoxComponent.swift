// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct AdditionalCostsBoxComponent: View {
  var offer: ChargeOffer

  var body: some View {
    VStack(spacing: .size(.M)) {
      CustomSection {
        LabeledContent {
          AdaptiveHStack(spacing: 4) {
            if let originalPrice = offer.originalPrice?.pricePerKWh {
              Text(originalPrice.formatted())
                .typography(.copy(size: .large), weight: .regular)
                .foregroundStyle(.secondaryContent)
                .strikethrough()
            }
            HStack(spacing: 0) {
              Text(verbatim: "\(offer.price.pricePerKWh.formatted())")
                .typography(.bold)
              Text(verbatim: "/kWh")
                .foregroundStyle(.secondaryContent)
            }
          }
        } label: {
          Text("Energy", bundle: .elvahCharge)
            .typography(.bold)
        }
        .labeledContentStyle(.adaptiveLayout)
        .typography(.copy(size: .large))
      }
      if offer.price.hasAdditionalCost {
        CustomBox {
          Text("Additional costs", bundle: .elvahCharge)
            .typography(.copy(size: .large), weight: .bold)
          if let baseFee = offer.price.baseFee {
            LabeledContent {
              Text(baseFee.formatted())
                .typography(.copy(size: .medium), weight: .bold)
            } label: {
              Text("Activation fee", bundle: .elvahCharge)
                .typography(.copy(size: .medium), weight: .bold)
            }
            .labeledContentStyle(.adaptiveLayout)
          }
          if showDivider {
            Divider()
          }
          if let blockingFee = offer.price.blockingFee {
            LabeledContent {
              if let maxAmount = blockingFee.maxAmount {
                Text(
                  "\(blockingFee.pricePerMinute.formatted())/min (max \(maxAmount.formatted()))",
                  bundle: .elvahCharge,
                )
                .typography(.copy(size: .medium), weight: .bold)
              } else {
                Text("\(blockingFee.pricePerMinute.formatted())/min", bundle: .elvahCharge)
                  .typography(.copy(size: .medium), weight: .bold)
              }
            } label: {
              Text("Blocking fee", bundle: .elvahCharge)
                .typography(.copy(size: .medium), weight: .bold)
            }
            .labeledContentStyle(.adaptiveLayout)
            .multilineTextAlignment(.trailing)
            blockingFeeConditions(for: blockingFee)
          }
        }
      }
    }
    .typography(.copy(size: .large))
    .foregroundStyle(.primaryContent)
  }

  @ViewBuilder private func blockingFeeConditions(for blockingFee: ChargePrice.BlockingFee) -> some View {
    VStack(alignment: .leading, spacing: .size(.S)) {
      if let startsAfterMinute = blockingFee.startsAfterMinute {
        Text("Starts after \(String(startsAfterMinute)) min of connection.", bundle: .elvahCharge)
      }
      if let timeSlots = blockingFee.timeSlots {
        ForEach(timeSlots) { timeSlot in
          HStack(spacing: 0) {
            Text(verbatim: "• ")
            Text(
              "between \(timeSlot.startsAt.localizedTimeString) and \(timeSlot.endsAt.localizedTimeString)",
              bundle: .elvahCharge,
            )
          }
        }
      }
    }
    .typography(.copy(size: .medium))
    .foregroundStyle(.secondaryContent)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var showDivider: Bool {
    offer.price.baseFee != nil && offer.price.blockingFee != nil
  }
}

@available(iOS 16.0, *)
#Preview {
  ScrollView {
    VStack(spacing: 10) {
      AdditionalCostsBoxComponent(offer: .mockAvailable)
    }
    .padding(.horizontal)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .background(.canvas)
  .preferredColorScheme(.dark)
  .withFontRegistration()
}
