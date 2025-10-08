// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ProgressRing: ViewModifier {
  @Environment(\.progressRingTint) private var progressRingTint
  @State private var rotation: Double = 0

  private var mode: ProgressRing.Mode

  init(mode: ProgressRing.Mode) {
    self.mode = mode
  }

  func body(content: Content) -> some View {
    squareContentView(content: content)
      .tint(progressRingTint)
      .padding(indicatorPadding)
      .background(overlayContent)
  }

  @ViewBuilder private func squareContentView(content: Content) -> some View {
    SquareContentLayout {
      content
    }
  }

  private var indicatorPadding: CGFloat {
    mode.showsAnimatedStroke ? 36 : 18
  }

  private var strokeWidth: CGFloat {
    mode.showsAnimatedStroke ? 14 : 0
  }

  private var strokeStyle: StrokeStyle {
    StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
  }

  @ViewBuilder private var overlayContent: some View {
    ZStack {
      backgroundStroke
      animatedStroke
    }
  }

  @ViewBuilder private var backgroundStroke: some View {
    Circle()
      .fill(progressRingTint ?? mode.trackColor)
      .opacity(0.25)
      .mask {
        Circle()
          .overlay {
            Circle()
              .padding(strokeWidth)
              .frame(width: mode.showsAnimatedStroke ? nil : 0, height: mode.showsAnimatedStroke ? nil : 0)
              .blendMode(.destinationOut)
          }
      }
  }

  @ViewBuilder private var animatedStroke: some View {
    TimelineView(.animation) { context in
      Circle()
        .trim(from: 0, to: mode.strokeTrimEnd)
        .stroke(progressRingTint ?? mode.foregroundColor, style: strokeStyle)
        .padding(mode.showsAnimatedStroke ? strokeWidth / 2 : 0)
        .rotationEffect(.degrees(rotationAngle(at: context.date)))
        .opacity(mode.showsAnimatedStroke ? 1 : 0)
    }
  }

  // MARK: - Helpers

  private func rotationAngle(at date: Date) -> Double {
    switch mode {
    case .indeterminate,
         .completed,
         .failed:
      let period: TimeInterval = 1.5 // seconds per revolution
      let time = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)
      return -90 + (time / period) * 360
    case .determinate:
      return -90
    }
  }

  private func setRotationImmediately(to newValue: Double) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction) {
      rotation = newValue
    }
  }

  private func startSpin() {
    setRotationImmediately(to: -90)
    rotation = 270
  }

  private func stopSpin() {
    setRotationImmediately(to: -90)
  }
}

@available(iOS 16.0, *)
extension View {
  func progressRing(_ mode: ProgressRing.Mode = .indeterminate) -> some View {
    modifier(ProgressRing(mode: mode))
  }
}

@available(iOS 16.0, *)
extension ProgressRing {
  /// Represents the mode of progress indication.
  enum Mode: Hashable, Sendable {
    /// Continuous animation without specific progress value.
    case indeterminate

    /// Progress with a specific completion fraction between 0.0 and 1.0.
    case determinate(fraction: Double)

    /// Progress completed successfully.
    case completed

    /// Progress failed with an error.
    case failed

    var showsAnimatedStroke: Bool {
      switch self {
      case .indeterminate,
           .determinate:
        true
      case .completed,
           .failed:
        false
      }
    }

    var strokeTrimEnd: Double {
      switch self {
      case .indeterminate:
        0.25
      case let .determinate(fraction):
        max(0.0, min(1.0, fraction))
      case .completed,
           .failed:
        0.25
      }
    }

    var foregroundColor: Color {
      switch self {
      case .indeterminate,
           .determinate:
        .brand
      case .completed:
        .success
      case .failed:
        .red
      }
    }

    var trackColor: Color {
      switch self {
      case .indeterminate,
           .determinate:
        .brand
      case .completed:
        .brand
      case .failed:
        .red
      }
    }
  }
}

@available(iOS 18.0, *)
#Preview {
  @Previewable @State var selectedMode: ProgressRing.Mode = .indeterminate
  @Previewable @State var progress = 0.7

  VStack(spacing: 40) {
    Spacer()

    VStack {
      var iconSize: Double {
        if case .determinate = selectedMode {
          return 25
        }
        return 30
      }

      Image(.bolt)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .foregroundStyle(selectedMode == .failed ? .red : .brand)
        .frame(width: iconSize, height: iconSize)

      if case .determinate = selectedMode {
        VStack {
          Text(verbatim: "22.53 kWh")
            .typography(.title(size: .medium))
          Text(verbatim: "00:23:25")
            .typography(.copy(size: .medium))
        }
        .transition(.opacity.combined(with: .scale))
      }
    }
    .progressRing(selectedMode)

    Spacer()

    // Controls
    VStack(spacing: 20) {
      // Progress Slider (only visible for determinate mode)
      if case .determinate = selectedMode {
        VStack {
          Text(verbatim: "Progress: \(Int(progress * 100))%")
            .typography(.copy(size: .medium))

          Slider(value: $progress, in: 0 ... 1, step: 0.05)
            .onChange(of: progress) { newValue in
              selectedMode = .determinate(fraction: newValue)
            }
        }
        .transition(.opacity.combined(with: .scale))
        .frame(maxWidth: 250)
      }

      // Mode Selector
      Picker(selection: $selectedMode) {
        Text(verbatim: "Loading").tag(ProgressRing.Mode.indeterminate)
        Text(verbatim: "Progress").tag(ProgressRing.Mode.determinate(fraction: progress))
        Text(verbatim: "Done").tag(ProgressRing.Mode.completed)
        Text(verbatim: "Error").tag(ProgressRing.Mode.failed)
      } label: {
        Text(verbatim: "Progress Mode")
      }
      .pickerStyle(.segmented)
    }
    .padding()
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
  .animation(.smooth, value: selectedMode)
  .animation(.smooth, value: progress)
  .preferredColorScheme(.dark)
  .withFontRegistration()
}
