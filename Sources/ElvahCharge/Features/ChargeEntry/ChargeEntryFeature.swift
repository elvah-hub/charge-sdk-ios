// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
  import Defaults
#endif

@available(iOS 16.0, *)
package struct ChargeEntryFeature: View {
  @Environment(\.dismiss) private var dismiss
  @Default(.chargeSessionContext) private var chargeSessionContext
  @Process private var process
  @EnvironmentObject private var chargeProvider: ChargeProvider
  @EnvironmentObject private var chargeSettlementProvider: ChargeSettlementProvider
  @EnvironmentObject private var discoveryProvider: DiscoveryProvider
  @StateObject private var router = Router()
  @State private var state: ViewState = .loading
  @State private var chargeRequest: ChargeRequest?
  @State private var showChargeSession = false

  /// A charge request that was passed into the view. The value is cached and will be used when a
  /// new charge session is allowed to start.
  private var passedChargeRequest: ChargeRequest?
  private var passedChargeOffer: ChargeOffer?

  /// Initializes the ``ChargeEntryFeature`` without a charge request. The view will attempt to restore
  /// an active session, if one exists.
  package init() {}

  /// Initializes the ``ChargeEntryFeature`` with a charge request.
  ///
  /// This will have the effect that this view does not need to fetch the tariffs for a given charge
  /// point. It will directly use the given request.
  ///
  /// - Note: Under certain conditions, e.g. when there already is an active charge session, the
  /// given charge request will be ignored by the view and overriden by its other logic.
  /// - Parameter chargeRequest: The charge request to use.
  package init(chargeRequest: ChargeRequest) {
    passedChargeRequest = chargeRequest
  }

  /// Initializes the ``ChargeEntryFeature`` with a charge offer.
  ///
  /// The offer will be signed and resolved into a charge request before presenting the payment flow.
  /// - Parameter chargeOffer: The charge offer to use.
  package init(chargeOffer: ChargeOffer) {
    passedChargeOffer = chargeOffer
  }

  package var body: some View {
    NavigationStack(path: $router.path) {
      ZStack {
        Color.canvas.ignoresSafeArea()
        if showChargeSession {
          ChargeSessionFeature(router: router.chargeSessionRouter)
            .zIndex(3)
            .transition(.scale(scale: 1.1).combined(with: .opacity))
        } else if let chargeRequest {
          ChargePaymentFeature(request: chargeRequest, router: router.paymentRouter)
            .zIndex(2)
            .transition(.scale(scale: 1.1).combined(with: .opacity))
        } else {
          ChargeEntryActivityView(state: state)
            .zIndex(1)
            .transition(.asymmetric(insertion: .identity, removal: .scale(scale: 0.5)))
        }
      }
    }
    .navigationRoot(path: $router.path)
    .withSafeAreaInsets()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .animation(.default, value: chargeRequest)
    .animation(.default, value: showChargeSession)
    .animation(.bouncy(extraBounce: 0.1), value: state)
    .task(id: passedChargeRequest?.id ?? passedChargeOffer?.id) {
      await prepareData()
    }
  }

  private func abortChargeAttempt() {
    chargeSessionContext = nil
    showChargeSession = false
    chargeRequest = nil
    state = .missingChargeContext
  }

  // MARK: - Data Loading

  private func prepareData() async {
    await $process.run {
      state = .loading

      if showChargeSession == false, chargeSessionContext != nil {
        // Restore existing charge session
        showChargeSession = true
        return
      }

      guard canHandleNewChargeRequest else {
        showChargeSession = true
        return
      }

      do {
        if let passedChargeRequest {
          // Use the charge request that was passed in
          showChargeSession = false
          chargeRequest = passedChargeRequest
        } else if let passedChargeOffer {
          // Resolve the charge offer into a charge request
          showChargeSession = false
          let resolvedChargeRequest = try await resolveChargeOffer(passedChargeOffer)
          guard canHandleNewChargeRequest else {
            showChargeSession = true
            return
          }
          chargeRequest = resolvedChargeRequest
        } else {
          // No active charge session and no charge request that can be handled
          try await Task.sleep(for: .milliseconds(800))
          state = .missingChargeContext
        }
      } catch {
        chargeRequest = nil
        showChargeSession = false
        state = .error
      }
    }
  }

  private var canHandleNewChargeRequest: Bool {
    chargeSessionContext == nil
  }

  private func resolveChargeOffer(_ chargeOffer: ChargeOffer) async throws -> ChargeRequest {
    let signedOffer = try await discoveryProvider.signOffer(chargeOffer)
    let context = try await chargeSettlementProvider.initiate(with: signedOffer.token)
    try Task.checkCancellation()

    return ChargeRequest(
      site: chargeOffer.site,
      signedOffer: signedOffer,
      paymentContext: context
    )
  }
}

@available(iOS 16.0, *)
extension ChargeEntryFeature {
  enum ViewState {
    case loading
    case missingChargeContext
    case error
  }
}

@available(iOS 16.0, *)
extension ChargeEntryFeature {
  final class Router: BaseRouter {
    @Published var path = NavigationPath()

    init() {}

    let paymentRouter = ChargePaymentFeature.Router()
    let chargeSessionRouter = ChargeSessionFeature.Router()

    func reset() {
      paymentRouter.reset()
      chargeSessionRouter.reset()
      dismissPresentation()
    }

    func dismissPresentation() {}
  }
}

@available(iOS 16.0, *)
#Preview {
  ChargeEntryFeature(chargeRequest: .mock)
    .withMockEnvironmentObjects()
    .withFontRegistration()
}
