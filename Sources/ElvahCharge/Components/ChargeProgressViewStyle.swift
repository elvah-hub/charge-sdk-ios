// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ProgressViewStyle where Self == ChargeProgressViewStyle {
  static var charge: Self {
    ChargeProgressViewStyle()
  }
}

@available(iOS 16.0, *)
struct ChargeProgressViewStyle: ProgressViewStyle {
  @State private var size: CGSize = .zero

  func makeBody(configuration: Self.Configuration) -> some View {
    ZStack {
      Capsule()
        .foregroundStyle(.decorativeStroke)
      Color.clear
        .sizeReader($size)
        .overlay(alignment: .leading) {
          innerCapsule(fractionCompleted: configuration.fractionCompleted ?? 0)
        }
    }
    .frame(height: 12)
    .animation(.default, value: configuration.fractionCompleted)
  }

  @ViewBuilder private func innerCapsule(fractionCompleted: Double) -> some View {
    let width = min(size.width, max(size.height, fractionCompleted * size.width))
    Capsule()
      .fill(.brand)
      .frame(width: width)
  }
}

@available(iOS 16.0, *)
#Preview {
  ProgressView(value: 0.4, total: 1)
    .progressViewStyle(.charge)
    .padding(.horizontal)
    .preferredColorScheme(.dark)
    .withFontRegistration()
}
