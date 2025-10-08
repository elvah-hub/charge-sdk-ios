// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
  import Defaults
#endif

@available(iOS 16.0, *)
extension ChargeOfferDetailFeature {
  struct ChargePointSection: View {
    typealias Action = (_ offers: ChargeOffer) -> Void

    @Default(.chargeSessionContext) private var chargeSessionContext
    @Binding private var offersSectionOrigin: CGPoint
    private var offers: LoadableState<[ChargeOffer]>
    private var processingOffer: ChargeOffer?
    private var isDiscountBannerHidden: Bool = false
    private var offerAction: Action
    private var chargeSessionAction: () -> Void

    init(
      offers: LoadableState<[ChargeOffer]>,
      offersSectionOrigin: Binding<CGPoint>,
      processingOffer: ChargeOffer?,
      isDiscountBannerHidden: Bool = false,
      offerAction: @escaping Action,
      chargeSessionAction: @escaping () -> Void,
    ) {
      self.offers = offers
      _offersSectionOrigin = offersSectionOrigin
      self.processingOffer = processingOffer
      self.isDiscountBannerHidden = isDiscountBannerHidden
      self.offerAction = offerAction
      self.chargeSessionAction = chargeSessionAction
    }

    var body: some View {
      VStack(alignment: .leading, spacing: .size(.M)) {
        // When this view has a height of 0, it message with the 2-part background and the toolbar
        Color.clear.frame(height: 1)
        switch offers {
        case .absent,
             .loading,
             .error:
          ChargePointActivityContentView(offers: offers)
            .padding(.horizontal, .M)
            .padding(.vertical, .M)
        case let .loaded(loadedOffers):
          ChargeOfferDetailOfferBanner(
            offers: loadedOffers,
            chargeSessionAction: chargeSessionAction,
            hideDiscountBanner: isDiscountBannerHidden,
          )
          .padding(.horizontal, .M)
          ChargePointListView(
            offers: loadedOffers,
            offersSectionOrigin: $offersSectionOrigin,
            processingOffer: processingOffer,
            offerAction: offerAction,
          )
        }
      }
      .animation(.default, value: offers)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

// MARK: - Extracted Subviews

@available(iOS 16.0, *)
private struct ChargeOfferDetailOfferBanner: View {
  /// The offers to inspect for discount state
  var offers: [ChargeOffer]

  /// Action to manage current charge session
  var chargeSessionAction: () -> Void

  /// Whether to hide the discount promo banner. The current-session banner remains visible.
  var hideDiscountBanner: Bool = false

  @Default(.chargeSessionContext) private var chargeSessionContext
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize

  var body: some View {
    if chargeSessionContext != nil {
      Button { chargeSessionAction() } label: {
        CustomSection {
          HStack {
            Image(.bolt)
              .foregroundStyle(.brand)
              .typography(.copy(size: .xLarge), weight: .bold)
            Text("Manage your current charge session", bundle: .elvahCharge)
              .frame(maxWidth: .infinity, alignment: .leading)
            Image(.chevronRight)
          }
        }
      }
      .typography(.copy(size: .medium), weight: .bold)
      .foregroundStyle(.primaryContent)
      .dynamicTypeSize(...(.accessibility1))
    }
  }
}

@available(iOS 16.0, *)
private struct ChargePointListView: View {
  /// List of offers to render in the section
  var offers: [ChargeOffer]

  /// Binding to capture the section origin for scroll syncing
  @Binding var offersSectionOrigin: CGPoint

  /// The offer currently being processed, if any
  var processingOffer: ChargeOffer?

  /// Action to trigger when a row is tapped
  var offerAction: (_ offer: ChargeOffer) -> Void

  @State private var searchText: String = ""
  @FocusState private var isSearchFieldFocused: Bool

  var body: some View {
    let filteredOffers = filtered(offers: offers, with: searchText)

    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
      Section {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
          VStack(spacing: 0) {
            if filteredOffers.isEmpty, isSearchActive(searchText) {
              ChargePointNoResultsView(searchText: $searchText)
            } else {
              ForEach(filteredOffers) { offer in
                ChargePointRowButton(
                  offer: offer,
                  offerAction: offerAction,
                )
                .overlay {
                  LoadingOverlayView(isShowing: processingOffer?.id == offer.id)
                }
                Divider().padding(.leading, .M)
              }
            }
          }
          .buttonStyle(ChargePointButtonStyle())
          .foregroundStyle(.primaryContent)
          .animation(.bouncy, value: processingOffer)
          .animation(.default, value: searchText)
        }
      } header: {
        if offers.count >= 5 {
          ChargePointSearchField(
            searchText: $searchText,
            isSearchFieldFocused: _isSearchFieldFocused,
          )
        }
      }
    }
    .overlay(alignment: .top) {
      Color.clear.frame(height: 0)
        .scrollPositionReader($offersSectionOrigin, in: "ScrollView")
    }
    .frame(maxWidth: .infinity)
  }

  /// Returns `true` if the search text is not empty (after trimming whitespace)
  private func isSearchActive(_ value: String) -> Bool {
    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
  }

  /// Filters offers by EVSE id, physical reference or fuzzy match
  private func filtered(offers: [ChargeOffer], with query: String) -> [ChargeOffer] {
    let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard needle.isEmpty == false else {
      return offers
    }

    func matches(_ value: String?) -> Bool {
      guard let value, value.isEmpty == false else {
        return false
      }
      return value.localizedCaseInsensitiveContains(needle)
    }

    return offers.filter { offer in
      let chargePoint = offer.chargePoint
      return matches(chargePoint.evseId)
        || matches(chargePoint.physicalReference)
        || chargePoint.evseId.fuzzyMatches(needle)
        || matches(String(chargePoint.evseId.filter { $0 != "*" }))
    }
  }
}

@available(iOS 16.0, *)
private struct ChargePointSearchField: View {
  @Binding var searchText: String
  @FocusState var isSearchFieldFocused: Bool

  var body: some View {
    HStack(spacing: .size(.S)) {
      Image(systemName: "magnifyingglass")
        .accessibilityHidden(true)
      TextField(
        "Type charge point ID",
        text: $searchText,
        prompt: Text("Type charge point ID", bundle: .elvahCharge),
      )
      .focused($isSearchFieldFocused)
      .typography(.copy(size: .medium))
      .frame(maxWidth: .infinity, alignment: .leading)
      Spacer(minLength: 0)
      if searchText.isEmpty == false {
        Button { searchText = "" } label: {
          Image(systemName: "xmark")
            .foregroundStyle(.primaryContent)
        }
        .accessibilityHidden(true)
      }
    }
    .padding(.M)
    .background(.container, in: .rect(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .strokeBorder(Color.decorativeStroke, lineWidth: 1)
    }
    .padding(.horizontal, .M)
    .padding(.bottom, .M)
    .dynamicTypeSize(...(.accessibility2))
    .accessibilityElement(children: .combine)
    .accessibilityAction(named: Text("Clear input", bundle: .elvahCharge)) {
      searchText = ""
    }
    .contentShape(.rect)
    .onTapGesture { isSearchFieldFocused = true }
    .background(Color.canvas)
  }
}

@available(iOS 16.0, *)
private struct LoadingOverlayView: View {
  var isShowing: Bool

  var body: some View {
    ZStack(alignment: .trailing) {
      if isShowing {
        LinearGradient(
          stops: [
            Gradient.Stop(color: .container, location: 0),
            Gradient.Stop(color: .clear, location: 1),
          ],
          startPoint: .trailing,
          endPoint: .leading,
        )
        .transition(.opacity)
      }
      if isShowing {
        ProgressView()
          .progressViewStyle(.inlineActivity)
          .padding(.trailing, .L)
          .transition(.opacity.combined(with: .move(edge: .trailing)))
      }
    }
  }
}

@available(iOS 16.0, *)
private struct ChargePointRowButton: View {
  @Default(.chargeSessionContext) private var chargeSessionContext

  var offer: ChargeOffer
  var offerAction: (_ offer: ChargeOffer) -> Void

  var body: some View {
    let chargePoint = offer.chargePoint
    Button { offerAction(offer) } label: {
      let evseDisplayText: String = displayText(for: chargePoint)

      let evseIdLabel = Text(verbatim: evseDisplayText)
        .typography(.copy(size: .medium), weight: .bold)
        .foregroundStyle(.onBrand)
        .padding(.horizontal, .XS)
        .padding(.vertical, .XXS)
        .background(.brand, in: .rect(cornerRadius: 4))

      let priceLabel = Text(offer.price.pricePerKWh.formatted())

      let originalPriceLabel: Text? = {
        if let originalPrice = offer.originalPrice?.pricePerKWh {
          return Text(originalPrice.formatted())
        }
        return nil
      }()

      let connectorTitle: String? = connectorTitle(for: chargePoint)

      VStack(alignment: .leading, spacing: .size(.XXS)) {
        HStack(alignment: .firstTextBaseline) {
          evseIdLabel
          Spacer()
          if offer.isDiscounted, let original = originalPriceLabel {
            HStack(spacing: .size(.XS)) {
              priceLabel
                .typography(.copy(size: .medium), weight: .bold)
                .foregroundStyle(.primaryContent)
              original
                .typography(.copy(size: .small), weight: .regular)
                .foregroundStyle(.secondaryContent)
                .strikethrough()
            }
          } else {
            priceLabel
              .typography(.copy(size: .medium), weight: .bold)
              .foregroundStyle(.primaryContent)
          }
        }

        HStack(alignment: .firstTextBaseline) {
          Text(chargePoint.availability.localizedTitle)
            .foregroundStyle(chargePoint.availability.color)
          Spacer()
          if let connectorTitle {
            Text("\(connectorTitle) • \(chargePoint.maxPowerInKWFormatted)")
          } else {
            Text(chargePoint.maxPowerInKWFormatted)
          }
        }
        .typography(.copy(size: .small))
        .foregroundStyle(.secondaryContent)
      }
      .withChevron()
      .padding(.M)
    }
  }

  /// Builds the display text for the EVSE id or physical reference.
  private func displayText(for chargePoint: ChargePoint) -> String {
    if let physicalReference = chargePoint.physicalReference, physicalReference.isEmpty == false {
      return physicalReference
    }
    return chargePoint.evseId
  }

  /// Returns a title for the connector or power type if present.
  private func connectorTitle(for chargePoint: ChargePoint) -> String? {
    if let connector = chargePoint.connectors.sorted().first {
      if connector == .type2 {
        return "Type 2"
      }
      return connector.localizedTitle
    } else if let powerType = chargePoint.powerType {
      return powerType.localizedTitle
    } else {
      return nil
    }
  }
}

@available(iOS 16.0, *)
private struct ChargePointNoResultsView: View {
  @Binding var searchText: String

  var body: some View {
    VStack(alignment: .center, spacing: .size(.S)) {
      Text("No results for \(Text(verbatim: searchText))", bundle: .elvahCharge)
        .typography(.copy(size: .xLarge), weight: .bold)
        .foregroundStyle(.primaryContent)
      Text("Check your search input and try again", bundle: .elvahCharge)
        .typography(.copy(size: .small))
        .foregroundStyle(.secondaryContent)
      Button("Clear filters", bundle: .elvahCharge) { searchText = "" }
        .buttonStyle(.textPrimary)
    }
    .padding(.vertical, .M)
    .padding(.vertical, .L)
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity)
    .animation(nil, value: searchText)
  }
}

@available(iOS 16.0, *)
private struct ChargePointActivityContentView: View {
  var offers: LoadableState<[ChargeOffer]>

  var body: some View {
    ActivityInfoComponent(state: state, title: title, message: message)
  }

  private var title: LocalizedStringKey? {
    if offers.isError {
      return "An error occurred"
    }
    return nil
  }

  private var message: LocalizedStringKey? {
    if offers.isError {
      return "The charge offers could not be loaded. Please try again later."
    }
    return nil
  }

  private var state: ActivityInfoComponent.ActivityState {
    if offers.isError {
      return .error
    }
    return .animating
  }
}

@available(iOS 16.0, *)
private struct AvailabilityPill: View {
  var chargePoint: ChargePoint

  var body: some View {
    Text(chargePoint.localizedAvailability)
      .typography(.copy(size: .small), weight: .bold)
      .foregroundStyle(chargePoint.availabilityForegroundColor)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(chargePoint.availabilityBackgroundColor, in: .capsule)
  }
}

@available(iOS 16.0, *)
private struct ChargePointButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .contentShape(.rect)
      .background {
        if configuration.isPressed {
          Color.decorativeStroke
        }
      }
  }
}

@available(iOS 16.0, *)
#Preview {
  NavigationStack {
    ZStack {
      Color.canvas.ignoresSafeArea()
      ScrollView {
        VStack(spacing: 20) {
          RoundedRectangle(cornerRadius: 8)
            .foregroundStyle(.decorativeStroke)
            .frame(height: 100)
            .padding(.horizontal, 16)
            .opacity(0.2)
          ChargeOfferDetailFeature.ChargePointSection(
            offers: .loaded([.mockAvailable, .mockUnavailable, .mockOutOfService]),
            offersSectionOrigin: .constant(.zero),
            processingOffer: .mockAvailable,
          ) { _ in } chargeSessionAction: {}
        }
      }
    }
  }
  .withFontRegistration()
  .withMockEnvironmentObjects()
  .preferredColorScheme(.dark)
}
