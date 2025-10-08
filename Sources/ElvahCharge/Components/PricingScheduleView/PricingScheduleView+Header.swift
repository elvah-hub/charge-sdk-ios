// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package extension PricingScheduleView {
  /// Header displayed above the summary with operator name and address.
  struct Header: View {
    /// Site operator display name.
    private var title: String

    /// Postal address of the site.
    private var address: Site.Address

    package init(title: String, address: Site.Address) {
      self.title = title
      self.address = address
    }

    package var body: some View {
      VStack(alignment: .leading, spacing: .size(.XXS)) {
        Text(title)
          .typography(.title(size: .small), weight: .bold)
          .foregroundStyle(.primaryContent)
          .accessibilityAddTraits(.isHeader)
        Text(address.formatted())
          .typography(.copy(size: .medium))
          .foregroundStyle(.secondaryContent)
          .dynamicTypeSize(...(.accessibility2))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .multilineTextAlignment(.leading)
      .accessibilityElement(children: .combine)
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  PricingScheduleView.Header(title: "E-ON Drive", address: .init(locality: "Berlin", postalCode: "12683", streetAddress: ["Köpenicker Straße 145"]))
    .padding(.horizontal)
    .withFontRegistration()
}
