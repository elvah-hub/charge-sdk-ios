// Copyright © elvah. All rights reserved.

import ElvahCharge
import SwiftUI

struct ChargeOfferListDemo: View {
  @State private var chargeOffers: ChargeOfferList?
  @State private var isLoading = false
  @State private var error: Error?
  @State private var selectedOffer: ChargeOffer?

  var body: some View {
    DemoContent {
      VStack(spacing: 15) {
        Button("Load Charge Offers") {
          Task {
            await performLoadChargeOffers()
          }
        }
        .disabled(isLoading)

        if isLoading {
          ProgressView("Loading offers...")
            .padding()
        } else if let error {
          ErrorView(error: error)
        } else if let chargeOffers {
          ChargeOfferListView(
            offers: chargeOffers,
            onOfferSelected: { offer in
              selectedOffer = offer
            },
          )
        }
      }
      .animation(.default, value: isLoading)
      .animation(.default, value: chargeOffers)
    }
    .navigationTitle("Charge Offers")
    .navigationBarTitleDisplayMode(.inline)
    .chargePresentation(offer: $selectedOffer)
  }

  private func performLoadChargeOffers() async {
    isLoading = true
    error = nil

    do {
      // Using mock EVSE IDs - in simulation mode these will return mock data
      let evseIds = [
        "DE*SIM*1234",
        "DE*SIM*1235",
        "DE*SIM*1236",
        "DE*SIM*1237",
      ]

      let offers = try await ChargeOffer.offers(forEvseIds: evseIds)

      chargeOffers = offers
      isLoading = false
    } catch {
      self.error = error
      isLoading = false
    }
  }
}

struct ChargeOfferListView: View {
  var offers: ChargeOfferList
  var onOfferSelected: (ChargeOffer) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Available Charge Offers")
        .font(.headline)
        .padding(.horizontal, 15)

      LazyVStack(spacing: 8) {
        ForEach(offers) { offer in
          ChargeOfferRowView(offer: offer) {
            onOfferSelected(offer)
          }
        }
      }
      .padding(.horizontal, 15)
    }
  }
}

struct ChargeOfferRowView: View {
  var offer: ChargeOffer
  var onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text(offer.evseId)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)

          Text("\(offer.chargePoint.maxPowerInKwFormatted) kW")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 4) {
          HStack(spacing: 4) {
            Text(offer.price.pricePerKWh.formatted())
              .font(.callout)
              .fontWeight(.semibold)
              .foregroundStyle(.green)

            if let originalPrice = offer.originalPrice {
              Text(originalPrice.pricePerKWh.formatted())
                .font(.caption)
                .strikethrough()
                .foregroundStyle(.secondary)
            }
          }

          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(.background.secondary)
      .cornerRadius(8)
    }
    .buttonStyle(.plain)
  }
}

struct ErrorView: View {
  var error: Error

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle")
        .font(.title2)
        .foregroundStyle(.orange)

      Text("Error loading offers")
        .font(.headline)

      Text(error.localizedDescription)
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .background(.background.secondary)
    .cornerRadius(10)
    .padding(.horizontal, 15)
  }
}

#Preview {
  NavigationStack {
    ChargeOfferListDemo()
      .preferredColorScheme(.dark)
  }
}
