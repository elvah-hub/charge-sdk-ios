// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
package struct StyledNavigationTitle: View {
  private var title: Text

  package init(_ localizedTitle: LocalizedStringKey, bundle: Bundle? = nil) {
    title = Text(localizedTitle, bundle: bundle)
  }

  @_disfavoredOverload package init(_ title: String) {
    self.title = Text(title)
  }

  package var body: some View {
    title
      .dynamicTypeSize(...(.xxxLarge))
      .typography(.copy(size: .large), weight: .bold)
      .foregroundStyle(.primaryContent)
  }
}
