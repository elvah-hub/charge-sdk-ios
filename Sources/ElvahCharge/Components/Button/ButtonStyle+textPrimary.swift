// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension ButtonStyle where Self == TextPrimaryButtonStyle {
  static var textPrimary: Self {
    TextPrimaryButtonStyle()
  }
}

@available(iOS 16.0, *)
package struct TextPrimaryButtonStyle: ButtonStyle {
  @State private var variant = ButtonVariant.default

  package func makeBody(configuration: Configuration) -> some View {
    ButtonInternal.ButtonLabel(configuration: configuration, variant: $variant)
      .labelStyle(ButtonInternal.TextButtonLabelStyle())
      .modifier(ButtonInternal.TextButtonDecoration(variant: variant))
      .modifier(ButtonInternal.TextButtonSizeModifier(variant: variant))
      .modifier(ButtonInternal.TextButtonStylingModifier(
        kind: .primary,
        isPressed: configuration.isPressed,
      ))
  }
}

@available(iOS 16.0, *)
#Preview {
  ButtonInternal.PreviewTextButtons()
    .buttonStyle(.textPrimary)
    .withFontRegistration()
}
