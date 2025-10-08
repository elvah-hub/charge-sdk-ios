// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargeSliderView: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @State private var dragState: DragState = .ready
  @State private var size: CGSize = .zero
  @State private var impactTrigger = false
  @Namespace private var namespace

  private let cornerRadius = 18.0
  private let inset = 5.0
  private let thresholdPercentage = 0.85

  private let title: LocalizedStringKey
  private var action: () async -> Void

  init(
    title: LocalizedStringKey,
    action: @escaping () async -> Void,
  ) {
    self.title = title
    self.action = action
  }

  var body: some View {
    if #available(iOS 17.0, *) {
      content
        .sensoryFeedback(.impact(weight: .heavy), trigger: impactTrigger)
    } else {
      content
    }
  }

  @ViewBuilder private var content: some View {
    GeometryReader { geo in
      ZStack(alignment: .leading) {
        sliderBackground
        textOnSliderBackground
        knob(in: geo)
      }
      .onTapGesture {
        onTap(geo: geo)
      }
      .background(Color.clear)
    }
    .dynamicTypeSize(...(.accessibility1))
    .sizeReader($size)
    .animation(.easeOut(duration: 0.3), value: dragState.isReady)
    .animation(.default, value: dragState.isSuccess)
    .allowsHitTesting(dragState.isSuccess == false)
  }

  @ViewBuilder private var sliderBackground: some View {
    Rectangle()
      .fill(.brand)
      .cornerRadius(cornerRadius)
  }

  @ViewBuilder private var textOnSliderBackground: some View {
    Text(title, bundle: .elvahCharge)
      .typography(.copy(size: .large), weight: .bold)
      .kerning(dragState.textKerning)
      .scaleEffect(dragState.textScale)
      .opacity(dragState.textOpacity)
      .blur(radius: dragState.textBlurRadius)
      .multilineTextAlignment(.center)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity)
      .foregroundStyle(.onBrand)
      .padding(.leading, 8)
      .allowsHitTesting(false)
  }

  private func knob(in geo: GeometryProxy) -> some View {
    ZStack(alignment: .leading) {
      ZStack {
        Color.onBrand
        Image(systemName: "chevron.right")
          .fontWeight(.medium)
          .font(.title)
          .foregroundStyle(.brand)
          .scaleEffect(dragState.knobIconScale)
      }
      .aspectRatio(1, contentMode: .fit)
      .cornerRadius(cornerRadius - inset)
      .scaleEffect(dragState.isSuccess ? 0.8 : 1)
      .opacity(dragState.isSuccess ? 0 : 1)
      .offset(x: dragState.offsetX)
    }
    .padding(inset)
    .gesture(
      DragGesture(minimumDistance: 0)
        .onChanged { drag in
          onDragChanged(value: drag.translation.width, geo: geo)
        }
        .onEnded { _ in
          onDragEnded()
        },
    )
  }

  private func onDragChanged(value: CGFloat, geo: GeometryProxy) {
    let size = geo.frame(in: .global).size
    let maxX = size.width - size.height

    let valueExceedsThreshold = value >= (thresholdPercentage * maxX)
    if case let .dragging(offsetX, _) = dragState {
      let previousValueExceedsthreshold = offsetX >= (thresholdPercentage * maxX)
      if valueExceedsThreshold != previousValueExceedsthreshold {
        impactTrigger.toggle()
      }
    }

    if value >= maxX {
      dragState = .dragging(offsetX: maxX, maxX: maxX)
    } else if value <= 0 {
      dragState = .dragging(offsetX: 0, maxX: maxX)
    } else {
      dragState = .dragging(offsetX: value, maxX: maxX)
    }
  }

  private func onDragEnded() {
    switch dragState {
    case let .dragging(offsetX, maxX):
      if offsetX >= (thresholdPercentage * maxX) || offsetX == maxX {
        dragState = .success(maxX: maxX)
        Task {
          await action()
          dragState = .ready
        }
      } else {
        dragState = .ready
      }

    case .ready:
      break

    case .success:
      break
    }
  }

  private func onTap(geo: GeometryProxy) {
    if dragState.isReady {
      withAnimation {
        dragState = .dragging(
          offsetX: geo.size.height / 2,
          maxX: geo.size.width - geo.size.height,
        )

        Task {
          try await Task.sleep(for: .seconds(0.01))
          dragState = .ready
        }
      }
    }
  }

  private enum DragState: Equatable {
    case ready
    case dragging(offsetX: CGFloat, maxX: CGFloat)
    case success(maxX: CGFloat)

    var isReady: Bool {
      switch self {
      case .ready:
        true
      default:
        false
      }
    }

    var isDragging: Bool {
      switch self {
      case .dragging:
        true
      default:
        false
      }
    }

    var isSuccess: Bool {
      switch self {
      case .success:
        true
      default:
        false
      }
    }

    var offsetX: CGFloat {
      switch self {
      case let .dragging(offsetX, _):
        offsetX
      case let .success(maxX):
        maxX
      default:
        0
      }
    }

    var textScale: Double {
      switch self {
      case let .dragging(offsetX, maxX):
        1 + Double(offsetX / maxX) * 0.1
      default:
        1
      }
    }

    var textKerning: Double {
      switch self {
      case let .dragging(offsetX, maxX):
        Double(offsetX / maxX) * 0.4
      default:
        0
      }
    }

    var textOpacity: Double {
      switch self {
      case .success:
        0
      default:
        1
      }
    }

    var knobIconScale: Double {
      switch self {
      case .dragging:
        1
      case .success:
        0
      default:
        1
      }
    }

    var textBlurRadius: Double {
      if case let .dragging(offsetX: offsetX, maxX: maxX) = self {
        return (offsetX / maxX) * 2.0
      }

      return 0
    }
  }
}

@available(iOS 16.0, *)
#Preview {
  List {}
    .safeAreaInset(edge: .bottom) {
      FooterView {
        VStack {
          ChargeSliderView(title: "Start charging process") {
            try? await Task.sleep(for: .seconds(2))
          }
          .frame(height: 55)
        }
        .padding(.horizontal)
      }
    }
    .preferredColorScheme(.dark)
    .withFontRegistration()
}
