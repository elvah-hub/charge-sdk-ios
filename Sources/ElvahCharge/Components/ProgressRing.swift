// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ProgressRing: ViewModifier {
	@ScaledMetric private var strokeWidth: CGFloat = 14
	@State private var rotation: Double = 0

	private var mode: ProgressRing.Mode

	init(mode: ProgressRing.Mode) {
		self.mode = mode
	}

	func body(content: Content) -> some View {
		squareContentView(content: content)
			.padding(indicatorPadding)
			.overlay(backgroundStroke)
			.overlay(animatedStroke)
			.background(.canvas, in: .circle)
			.clipShape(.circle)
			.onAppear {
				switch mode {
				case .indeterminate:
					rotation = 360
				case .determinate:
					setRotationImmediately(to: -90)
				}
			}
			.onChange(of: mode) { mode in
				switch mode {
				case .indeterminate:
					setRotationImmediately(to: -90)
					rotation = 270
				case .determinate:
					rotation = -90
				}
			}
	}

	@ViewBuilder private func squareContentView(content: Content) -> some View {
		SquareContentLayout {
			content
		}
	}

	private var indicatorPadding: CGFloat {
		Size.XXL.size
	}

	private var strokeStyle: StrokeStyle {
		StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)
	}

	@ViewBuilder private var backgroundStroke: some View {
		Circle()
			.stroke(.brand.opacity(0.25), style: strokeStyle)
			.padding(strokeWidth / 2)
	}

	@ViewBuilder private var animatedStroke: some View {
		Circle()
			.trim(from: 0, to: mode.strokeTrimEnd)
			.stroke(.brand, style: strokeStyle)
			.padding(strokeWidth / 2)
			.rotationEffect(.degrees(rotation))
			.animation(mode.animation, value: rotation)
	}

	// MARK: - Helpers

	private func setRotationImmediately(to newValue: Double) {
		var transaction = Transaction()
		transaction.disablesAnimations = true
		withTransaction(transaction) {
			rotation = newValue
		}
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

		var animation: Animation {
			switch self {
			case .indeterminate:
				.linear(duration: 1.5).repeatForever(autoreverses: false)
			case .determinate:
				.snappy
			}
		}

		var strokeTrimEnd: Double {
			switch self {
			case .indeterminate:
				0.25
			case let .determinate(fraction):
				fraction
			}
		}
	}
}

@available(iOS 18.0, *)
#Preview {
	@Previewable @State var showOther = false
	VStack {
		Image(.bolt)
			.resizable()
			.aspectRatio(contentMode: .fit)
			.foregroundStyle(.brand)
			.frame(width: showOther ? 20 : 35, height: showOther ? 20 : 35)
			.transformEffect(.identity)
		if showOther {
			VStack {
				Text("22.53 kWh")
					.typography(.title(size: .medium))
				Text("00:23:25")
					.typography(.copy(size: .medium))
			}
			.transition(.scale.combined(with: .opacity))
		}
	}
	.progressRing(showOther ? .determinate(fraction: 0.7) : .indeterminate)
	.frame(maxWidth: .infinity, maxHeight: .infinity)
	.background(.canvas)
	.animation(.bouncy, value: showOther)
	.onTapGesture {
		showOther.toggle()
	}
	.preferredColorScheme(.dark)
	.withFontRegistration()
}
