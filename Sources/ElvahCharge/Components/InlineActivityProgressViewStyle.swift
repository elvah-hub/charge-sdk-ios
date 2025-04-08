// Copyright © elvah. All rights reserved.

import SwiftUI

package struct InlineActivityProgressViewStyle: ProgressViewStyle {
	@ScaledMetric private var radius = 16
	@State private var rotation: Double = 0

	package func makeBody(configuration: Configuration) -> some View {
		Color.clear.frame(width: radius, height: radius)
			.overlay(backgroundCircleStroke)
			.overlay(circleStroke)
			.onAppear(perform: startRotationAnimation)
	}

	private var strokeStyle: StrokeStyle {
		return StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
	}

	@ViewBuilder private var backgroundCircleStroke: some View {
		Circle()
			.stroke(.decorativeStroke, style: strokeStyle)
			.rotationEffect(.radians(rotation))
	}

	@ViewBuilder private var circleStroke: some View {
		Circle()
			.trim(from: 0, to: 0.4)
			.stroke(.brand, style: strokeStyle)
			.rotationEffect(.radians(rotation))
	}

	private func startRotationAnimation() {
		withAnimation(.linear(duration: 1.7).repeatForever(autoreverses: false)) {
			rotation = 2 * .pi
		}
	}
}

package extension ProgressViewStyle where Self == InlineActivityProgressViewStyle {
	static var inlineActivity: InlineActivityProgressViewStyle {
		InlineActivityProgressViewStyle()
	}
}

#Preview {
	ProgressView()
		.progressViewStyle(.inlineActivity)
		.preferredColorScheme(.dark)
}
