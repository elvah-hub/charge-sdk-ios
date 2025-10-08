// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension ButtonStyle where Self == _PrimaryButtonStyle {
  static var primary: Self {
    _PrimaryButtonStyle()
  }
}

@available(iOS 16.0, *)
package struct _PrimaryButtonStyle: ButtonStyle {
  @State private var variant = ButtonVariant.default

  package func makeBody(configuration: Configuration) -> some View {
    ButtonInternal.ButtonLabel(configuration: configuration, variant: $variant)
      .labelStyle(ButtonInternal.ButtonLabelStyle())
      .modifier(ButtonInternal.ButtonSizeModifier(variant: variant))
      .modifier(ButtonInternal.ButtonStylingModifier(
        kind: .primary,
        variant: variant,
        isPressed: configuration.isPressed,
      ))
  }
}

@available(iOS 16.0, *)
#Preview {
  ButtonInternal.PreviewButtons()
    .buttonStyle(.primary)
    .withFontRegistration()
}
