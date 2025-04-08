// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct PowerTypeSelector: View {
	@State private var size = CGSize.zero
	@Binding var selection: PowerType

	var body: some View {
		VStack(spacing: 0) {
			HStack(spacing: 0) {
				Button {
					selection = .ac
				} label: {
					Text("AC", bundle: .elvahCharge)
				}
				.buttonStyle(.chargingSpeedSelector(isSelected: selection == .ac))
				Button {
					selection = .dc
				} label: {
					Text("DC", bundle: .elvahCharge)
				}
				.buttonStyle(.chargingSpeedSelector(isSelected: selection == .dc))
			}
			ZStack(alignment: .leading) {
				Rectangle()
					.foregroundStyle(.decorativeStroke)
					.frame(height: 3)
				Rectangle()
					.foregroundStyle(.brand)
					.frame(width: size.width / 2, height: 3)
					.offset(x: selection == .dc ? size.width / 2 : 0)
			}
		}
		.sizeReader($size)
	}
}

@available(iOS 16.0, *)
private struct ChargingSpeedSelectorButtonStyle: ButtonStyle {
	var isSelected: Bool

	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.typography(.copy(size: .xLarge), weight: .bold)
			.foregroundStyle(isSelected ? .primaryContent : .secondaryContent)
			.frame(maxWidth: .infinity)
			.padding(20)
			.contentShape(.rect)
			.opacity(configuration.isPressed ? 0.5 : 1)
			.background {
				if configuration.isPressed {
					Color.decorativeStroke
				} else {
					Color.container
				}
			}
	}
}

@available(iOS 16.0, *)
private extension ButtonStyle where Self == ChargingSpeedSelectorButtonStyle {
	static func chargingSpeedSelector(isSelected: Bool) -> Self {
		.init(isSelected: isSelected)
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @State var selectedPowerType: PowerType = .dc
	PowerTypeSelector(selection: $selectedPowerType)
		.withFontRegistration()
		.preferredColorScheme(.dark)
		.animation(.default, value: selectedPowerType)
}
