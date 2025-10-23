// Copyright © elvah. All rights reserved.

import SwiftUI

public extension View {
  /// Presents a modal view that shows the currently active charge session, if there is one.
  ///
  /// You can use this view modifier to control the presentation of an already active charge session
  /// in your app.
  ///
  /// - Note: You can open this view at any time. However, if there is no active charge session,
  /// it will show a "no active charge session" info.
  /// - Tip: Call ``ChargeSession/updates()`` to receive status updates about active charge
  /// sessions in your app. For example, you can use that information to offer a "Show active
  /// charge session" button in your app that triggers the presentation of the active charge
  /// session.
  /// - Important: This modifier requires iOS 16.0 or later. On earlier versions, it does nothing to
  /// the wrapped view.
  /// - Parameter isPresented: A binding to a Boolean value that determines whether to present the
  /// active charge session.
  /// - Returns: A view that presents a charge session view if the `isPresented` binding is set to
  /// `true`.
  @ViewBuilder func chargeSessionPresentation(isPresented: Binding<Bool>) -> some View {
    if #available(iOS 16.0, *) {
      modifier(PresentationViewModifier(isPresented: isPresented))
    } else {
      self
    }
  }
}

// MARK: - Modifiers

@available(iOS 16.0, *)
private struct PresentationViewModifier: ViewModifier {
  @Binding var isPresented: Bool

  func body(content: Content) -> some View {
    content
      .fullScreenCover(isPresented: $isPresented) {
        ChargeEntryFeature()
          .withEnvironmentObjects()
      }
  }
}
