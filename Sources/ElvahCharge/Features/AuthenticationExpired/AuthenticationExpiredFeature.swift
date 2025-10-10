// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct AuthenticationExpiredFeature: View {
  @Environment(\.navigationRoot) private var navigationRoot
  @ObservedObject var router: Router
  var organisationDetails: PaymentContext.OrganisationDetails

  var body: some View {
    VStack {
      Spacer()
      VStack(spacing: .size(.M)) {
        Image(systemName: "exclamationmark")
          .foregroundStyle(.red)
          .font(.themed(size: 40))
          .progressRing(.failed)
        VStack(spacing: .size(.XS)) {
          Text("Payment expired", bundle: .elvahCharge)
            .typography(.title(size: .medium), weight: .bold)
            .foregroundStyle(.primaryContent)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
          Text(
            """
            Unfortunately, the time between payment and session start was too long. \
            We need you to authorize a new deposit on your payment method.
            """,
            bundle: .elvahCharge,
          )
          .dynamicTypeSize(...(.accessibility1))
          .typography(.copy(size: .medium))
          .foregroundStyle(.secondaryContent)
          .frame(maxWidth: .infinity)
          .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
      }
      Spacer()
      ButtonStack {
        VStack(spacing: .size(.M)) {
          Button("Understood", bundle: .elvahCharge) {
            navigationRoot.path = .init()
          }
          .buttonStyle(.primary)
          Button("Support", bundle: .elvahCharge) {
            router.showSupport = true
          }
          .compactControl()
          .buttonStyle(.textPrimary)
        }
      }
      .padding(.horizontal, .M)
    }
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .navigationBarBackButtonHidden()
    .background(Color.canvas)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        CloseButton {
          navigationRoot.dismiss()
        }
      }
    }
    .sheet(isPresented: $router.showSupport) {
      SupportFeature(
        router: router.supportRouter,
        organisationDetails: organisationDetails,
      )
    }
  }
}

@available(iOS 16.0, *)
extension AuthenticationExpiredFeature {
  final class Router: BaseRouter {
    @Published var showSupport = false

    let supportRouter: SupportFeature.Router = .init()

    func dismissPresentation() {
      showSupport = false
    }

    func reset() {
      dismissPresentation()
      supportRouter.reset()
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  @Previewable @StateObject var router = AuthenticationExpiredFeature.Router()
  AuthenticationExpiredFeature(router: router, organisationDetails: .mock)
    .withMockEnvironmentObjects()
    .withFontRegistration()
    .preferredColorScheme(.dark)
}
