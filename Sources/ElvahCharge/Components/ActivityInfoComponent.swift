// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ActivityInfoComponent: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @State private var rotation: Double = 0

  var state: ActivityState
  var title: LocalizedStringKey?
  var message: LocalizedStringKey?

  init(state: ActivityState, title: LocalizedStringKey?, message: LocalizedStringKey?) {
    self.state = state
    self.title = title
    self.message = message
  }

  var body: some View {
    VStack(spacing: .size(.XL)) {
      Color.clear.frame(width: radius, height: radius)
        .overlay(stateIcon)
        .background(fillCircle)
        .overlay(backgroundCircleStroke)
        .overlay(circleStroke)
        .onAppear(perform: startRotationAnimation)
      VStack(spacing: .size(.XS)) {
        if let title {
          Text(title, bundle: .elvahCharge)
            .typography(.title(size: .small), weight: .bold)
            .foregroundStyle(.primaryContent)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
        }
        if let message {
          Text(message, bundle: .elvahCharge)
            .dynamicTypeSize(...(.accessibility1))
            .typography(.copy(size: .medium))
            .foregroundStyle(.secondaryContent)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .frame(maxWidth: .infinity)
      .isHidden(title == nil && message == nil, remove: true)
    }
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity)
    .transformEffect(.identity)
  }

  // MARK: - Circular Progress Indicator

  private var strokeStyle: StrokeStyle {
    let lineWidth = dynamicTypeSize.isAccessibilitySize ? 8.0 : 4
    return StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
  }

  @ViewBuilder private var backgroundCircleStroke: some View {
    Circle()
      .trim(from: 0, to: backgroundCircleTrimEnd)
      .stroke(
        state == .error
          ? AnyShapeStyle(.error)
          : AnyShapeStyle(.decorativeStroke),
        style: strokeStyle,
      )
      .rotationEffect(.radians(rotation))
      .opacity(backgroundCircleStrokeOpacity)
  }

  @ViewBuilder private var circleStroke: some View {
    Circle()
      .trim(from: 0, to: circleTrimEnd)
      .stroke(.brand, style: strokeStyle)
      .rotationEffect(.radians(rotation))
      .opacity(circleStrokeOpacity)
  }

  @ViewBuilder private var fillCircle: some View {
    Circle()
      .fill(fillCircleColor)
      .padding(isFilled ? 0 : -6)
      .overlay {
        if isFilled == false {
          Circle().fill(.brand)
        }
      }
      .transition(.opacity.combined(with: .scale(scale: 1.15)))
      .opacity(state == .success ? 1 : 0)
  }

  // MARK: - Other Views

  @ViewBuilder private var stateIcon: some View {
    switch state {
    case let .animating(icon),
         let .outlined(icon):
      if let icon {
        image(for: icon)
          .foregroundStyle(.brand)
      }
    case .error:
      image(for: "exclamationmark")
        .foregroundStyle(.error)
    case .success:
      image(for: "checkmark")
        .foregroundStyle(.onBrand)
    }
  }

  @ViewBuilder private func image(for systemName: String) -> some View {
    Image(systemName: systemName)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .bold()
      .frame(width: 25, height: 25)
      .id(systemName)
      .transition(.opacity.combined(with: .scale))
  }

  // MARK: - Helpers

  private var radius: Double {
    if dynamicTypeSize.isAccessibilitySize {
      return 40
    }
    return 80
  }

  private var backgroundCircleStrokeOpacity: Double {
    switch state {
    case .outlined: 1
    case .animating: 1
    case .error: 1
    case .success: 0
    }
  }

  private var circleStrokeOpacity: Double {
    switch state {
    case .outlined: 1
    case .animating: 1
    case .error: 0
    case .success: 0
    }
  }

  private var circleTrimEnd: Double {
    switch state {
    case .outlined: 1
    case .animating: 0.4
    case .error: 0
    case .success: 0
    }
  }

  private var backgroundCircleTrimEnd: Double {
    switch state {
    case .outlined: 1
    case .animating: 1
    case .error: 1
    case .success: 0
    }
  }

  private var isFilled: Bool {
    switch state {
    case .success: true
    default: false
    }
  }

  private var fillCircleColor: Color {
    switch state {
    case .animating,
         .outlined: .clear
    case .error: .clear
    case .success: .brand
    }
  }

  private func startRotationAnimation() {
    withAnimation(.linear(duration: 1.7).repeatForever(autoreverses: false)) {
      rotation = 2 * .pi
    }
  }
}

@available(iOS 16.0, *)
extension ActivityInfoComponent {
  enum ActivityState: Hashable {
    case animating(iconSystemName: String?)
    case outlined(iconSystemName: String?)
    case error
    case success

    static var animating: Self {
      .animating(iconSystemName: nil)
    }

    static var outlined: Self {
      .outlined(iconSystemName: nil)
    }
  }
}

@available(iOS 16.0, *)
struct ActivityInfoData {
  let state: ActivityInfoComponent.ActivityState
  let title: LocalizedStringKey?
  let message: LocalizedStringKey?
}
