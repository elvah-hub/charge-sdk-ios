// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ButtonInternal {
  struct ButtonStylingModifier: ViewModifier {
    @Environment(\.controlSize) private var controlSize
    @Environment(\.redactionReasons) private var redactionReasons
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isLoading) private var isLoading

    let kind: ButtonKind
    let variant: ButtonVariant
    let isPressed: Bool

    func body(content: Content) -> some View {
      content
        .typography(.copy(size: .large), weight: .bold)
        .tint(styling.foreground)
        .foregroundStyle(styling.foreground)
        .background(styling.background, in: contentShape)
        .overlay(styling.border, in: contentShape.inset(by: 1).stroke(lineWidth: 2))
        .contentShape(.rect)
    }

    private var contentShape: some InsettableShape {
      RoundedRectangle(cornerRadius: controlSize.isSmall && variant == .iconOnly ? 8 : 12)
    }

    private var styling: Styling {
      if redactionReasons.contains(.placeholder) {
        return Styling(
          foreground: .clear.opacity(0),
          background: .brand.opacity(0.1),
          border: .clear,
        )
      }

      if isLoading {
        return switch kind {
        case .primary:
          Styling(foreground: .onBrand, background: .brand, border: .clear)
        case .secondary:
          Styling(foreground: .brand, background: .clear, border: .brand)
        }
      }

      if isEnabled == false {
        return switch kind {
        case .primary:
          Styling(
            foreground: .onBrand.opacity(0.3),
            background: .brand,
            border: .clear,
          )
        case .secondary:
          Styling(foreground: .brand.opacity(0.3), background: .clear, border: .brand)
        }
      }

      if isPressed {
        return switch kind {
        case .primary:
          Styling(
            foreground: .onBrand.opacity(0.6),
            background: .brand.opacity(0.6),
            border: .clear,
          )
        case .secondary:
          Styling(
            foreground: .brand.opacity(0.6),
            background: .clear,
            border: .brand.opacity(0.6),
          )
        }
      }

      return switch kind {
      case .primary:
        Styling(foreground: .onBrand, background: .brand, border: .clear)
      case .secondary:
        Styling(foreground: .brand, background: .clear, border: .brand)
      }
    }
  }
}

@available(iOS 16.0, *)
extension ButtonInternal.ButtonStylingModifier {
  private struct Styling {
    var foreground: Color
    var background: Color
    var border: Color
  }
}

@available(iOS 16.0, *)
private typealias StylingModifier = ButtonInternal.ButtonStylingModifier

@available(iOS 16.0, *)
#Preview {
  ScrollView {
    VStack(alignment: .leading) {
      Text(verbatim: "Default")
      iconButtons
      Text(verbatim: "Pressed")
      pressedIconButtons
      Text(verbatim: "Loading")
      loadingIconButtons.loading(true)
      Text(verbatim: "Disabled")
      iconButtons.disabled(true)
      Text(verbatim: "Redacted")
      iconButtons.frame(height: 52).redacted(reason: .placeholder)
    }
    .padding(.horizontal)
  }
  .background(.canvas)
  .withFontRegistration()
}

@available(iOS 16.0, *) private var iconButtons: some View {
  HStack {
    Text(verbatim: "Ab")
      .padding()
      .modifier(StylingModifier(kind: .primary, variant: .text, isPressed: false))
    Text(verbatim: "Ab")
      .padding()
      .modifier(StylingModifier(kind: .secondary, variant: .text, isPressed: false))
  }
}

@available(iOS 16.0, *) private var pressedIconButtons: some View {
  HStack {
    Text(verbatim: "Ab")
      .padding()
      .modifier(StylingModifier(kind: .primary, variant: .text, isPressed: true))
    Text(verbatim: "Ab")
      .padding()
      .modifier(StylingModifier(kind: .secondary, variant: .text, isPressed: true))
  }
}

@available(iOS 16.0, *) private var loadingIconButtons: some View {
  HStack {
    Text(verbatim: "Ab").hidden().overlay(ProgressView())
      .padding()
      .modifier(StylingModifier(kind: .primary, variant: .text, isPressed: false))
    Text(verbatim: "Ab").hidden().overlay(ProgressView())
      .padding()
      .modifier(StylingModifier(kind: .secondary, variant: .text, isPressed: false))
  }
}
