// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargePointIdentifierLabel: View {
  let evseId: String
  let physicalReference: String?

  init(point: ChargePoint) {
    self.init(
      evseId: point.evseId,
      physicalReference: point.physicalReference,
    )
  }

  init(evseId: String, physicalReference: String?) {
    self.evseId = evseId
    self.physicalReference = physicalReference
  }

  var body: some View {
    HStack(spacing: 4) {
      if let physicalReference, physicalReference.isEmpty == false {
        Text(physicalReference)
          .typography(.copy(size: .small))
          .foregroundStyle(.secondaryContent)
      } else {
        Text(evseId.dropLast(4))
          .foregroundStyle(.secondaryContent)
          .typography(.copy(size: .small))
        Text(evseId.suffix(4))
          .padding(.horizontal, 8)
          .typography(.copy(size: .small), weight: .bold)
          .padding(.vertical, 4)
          .background(.labelSDK, in: .rect(cornerRadius: 4))
      }
    }
    .foregroundStyle(.primaryContent)
    .truncationMode(.middle)
    .lineLimit(1)
  }
}

@available(iOS 16.0, *)
#Preview {
  ZStack {
    Color.canvas.ignoresSafeArea()
    VStack(spacing: 10) {
      ChargePointIdentifierLabel(
        evseId: "SOME*EVSE*ID*0001",
        physicalReference: nil,
      )
      ChargePointIdentifierLabel(
        evseId: "SOME*EVSE*ID*0001",
        physicalReference: nil,
      )
      ChargePointIdentifierLabel(
        evseId: "SOME*EVSE*ID*0001",
        physicalReference: "54",
      )
      ChargePointIdentifierLabel(
        evseId: "SOME*EVSE*ID*0001",
        physicalReference: "54",
      )
    }
  }
  .withFontRegistration()
}
