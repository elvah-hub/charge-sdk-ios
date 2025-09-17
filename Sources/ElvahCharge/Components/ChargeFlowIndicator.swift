// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargeFlowIndicator<Content: View>: View {
	@ScaledMetric private var strokeWidth: CGFloat = 14
	@State private var rotation: Double = 0

	var showOther: Bool
	var content: Content

	init(showOther: Bool, @ViewBuilder content: () -> Content) {
		self.showOther = showOther
		self.content = content()
	}

	var body: some View {
		squareContentView
			.padding(indicatorPadding)
			.overlay(backgroundStroke)
			.overlay(animatedStroke)
//			.overlay(cover)
//			.overlay(backgroundStroke)
//			.overlay(staticStroke)
			.background(.canvas, in: .circle)
			.clipShape(.circle)
//			.transformEffect(.identity)
			.onAppear(perform: startRotationAnimation)
			.onChange(of: showOther) { showOther in
				var transaction = Transaction()
				transaction.disablesAnimations = true

				if showOther {
					rotation = -90
				} else {
					withTransaction(transaction) {
						rotation = -90
					}
					rotation = 270
				}

				// showOther = true: 360 -> 270
				// showOther = false: 270 -> 630
				// showOther = true:
			}
	}

	@ViewBuilder private var squareContentView: some View {
		SquareContentLayout {
			content
				.transition(.scale(scale: 0.5).combined(with: .opacity))
		}
	}

	private var indicatorPadding: CGFloat {
		Size.XXL.size
	}

	@ViewBuilder private var cover: some View {
		if showOther {
			Circle()
				.fill(.canvas)
				.transition(.scale)
		}
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
			.trim(from: 0, to: showOther ? 0.31 : 0.25)
			.stroke(.brand, style: strokeStyle)
			.padding(strokeWidth / 2)
			.rotationTracking(rotation: rotation)
			.animation(
				showOther ? .bouncy : .linear(duration: 1.6).repeatForever(autoreverses: false),
				value: rotation,
			)
	}

	@ViewBuilder private var staticStroke: some View {
		if showOther {
			Circle()
				.trim(from: 0, to: 0.37)
				.stroke(.brand, style: strokeStyle)
				.padding(strokeWidth / 2)
				.rotationEffect(.radians(-.pi / 2))
				.transition(.scale(scale: 0.8).combined(with: .opacity))
		}
	}

	private func startRotationAnimation() {
//		rotation = 0
//		withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
		rotation = 360
//		}
	}
}

@available(iOS 16.0, *)
private extension View {
	func rotationTracking(rotation: Double) -> some View {
		modifier(RotationTrackingModifier(rotation: rotation))
	}
}

@available(iOS 16.0, *)
private struct RotationTrackingModifier: ViewModifier, @MainActor Animatable {
	/// The rotation in degrees.
	var rotation: Double

	var animatableData: Double {
		get { rotation }
		set { rotation = newValue }
	}

	func body(content: Content) -> some View {
		content
			.rotationEffect(.degrees(rotation))
//			.onChange(of: rotation) { rotation in
//				print(rotation)
//			}
	}
}

@available(iOS 16.0, *)
private struct SquareContentLayout: Layout {
	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		guard let subview = subviews.first else {
			return .zero
		}
		let sideLength = resolvedSquareSideLength(for: proposal, subview: subview)
		_ = subview.sizeThatFits(ProposedViewSize(width: sideLength, height: sideLength))
		return CGSize(width: sideLength, height: sideLength)
	}

	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		guard let subview = subviews.first else {
			return
		}
		let sideLength = min(bounds.width, bounds.height)
		subview.place(
			at: CGPoint(x: bounds.midX, y: bounds.midY),
			anchor: .center,
			proposal: ProposedViewSize(width: sideLength, height: sideLength),
		)
	}

	private func resolvedSquareSideLength(for proposal: ProposedViewSize, subview: LayoutSubview) -> CGFloat {
		let intrinsicSize = subview.sizeThatFits(.unspecified)
		let desiredSideLength = max(intrinsicSize.width, intrinsicSize.height)
		let availableWidth = proposal.width ?? .infinity
		let availableHeight = proposal.height ?? .infinity

		let availableSideLength = min(availableWidth, availableHeight)
		let resolvedSideLength = min(desiredSideLength, availableSideLength)
		if resolvedSideLength.isFinite {
			return resolvedSideLength
		}

		return desiredSideLength
	}
}

@available(iOS 18.0, *)
#Preview {
	@Previewable @State var showOther = false
	ChargeFlowIndicator(showOther: showOther) {
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
	}
	.frame(maxWidth: .infinity, maxHeight: .infinity)
	.background(.canvas)
	.animation(.bouncy, value: showOther)
	.onTapGesture {
		showOther.toggle()
	}
	.preferredColorScheme(.dark)
	.withFontRegistration()
}
