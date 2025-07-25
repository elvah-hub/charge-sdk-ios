// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargePointIdentifierView: View {
	let evseId: String
	let physicalReference: String?
	let isAvailable: Bool

	init(point: ChargePoint) {
		self.init(
			evseId: point.evseId,
			physicalReference: point.physicalReference,
			isAvailable: point.isAvailable
		)
	}

	init(evseId: String, physicalReference: String?, isAvailable: Bool) {
		self.evseId = evseId
		self.physicalReference = physicalReference
		self.isAvailable = isAvailable
	}

	var body: some View {
		HStack(spacing: 4) {
			Image(.other)
				.foregroundStyle(.onBrand)
			if let physicalReference = physicalReference, physicalReference.isEmpty == false {
				Text(physicalReference)
					.foregroundStyle(.onBrand)
			} else {
				Text(evseId.dropLast(4))
					.foregroundStyle(.onBrand)
				Text(evseId.suffix(4))
					.foregroundStyle(.onBrand)
			}
		}
		.typography(.copy(size: .xLarge), weight: .bold)
		.dynamicTypeSize(...(.accessibility1))
		.truncationMode(.middle)
		.lineLimit(1)
		.padding(.XS)
		.background(.brand, in: .rect(cornerRadius: 8))
	}
}

@available(iOS 16.0, *)
#Preview {
	VStack {
		ChargePointIdentifierView(
			evseId: "SOME*EVSE*ID*0001",
			physicalReference: nil,
			isAvailable: true
		)
		ChargePointIdentifierView(
			evseId: "SOME*EVSE*ID*0001",
			physicalReference: nil,
			isAvailable: false
		)
		ChargePointIdentifierView(
			evseId: "SOME*EVSE*ID*0001",
			physicalReference: "54",
			isAvailable: true
		)
		ChargePointIdentifierView(
			evseId: "SOME*EVSE*ID*0001",
			physicalReference: "54",
			isAvailable: false
		)
	}
	.preferredColorScheme(.dark)
	.withFontRegistration()
}
