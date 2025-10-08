// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct CPOLogo: View {
  @State private var image: UIImage?
  @State private var isLoading = true

  private var url: URL?

  init(url: URL?) {
    self.url = url
  }

  var body: some View {
    VStack {
      Text("Charging is provided in partnership with")
        .typography(.copy(size: .small))
        .foregroundStyle(.secondaryContent)
        .dynamicTypeSize(...(.xLarge))
      if let image {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: 50)
      } else if isLoading {
        ZStack {
          RoundedRectangle(cornerRadius: 10)
            .fill(.container)
            .aspectRatio(2, contentMode: .fit)
          ProgressView()
            .progressViewStyle(.inlineActivity)
        }
        .frame(height: 50)
      } else {
        fallback
          .frame(height: 50)
      }
    }
    .task {
      defer { isLoading = false }

      guard let url else {
        return
      }

      do {
        image = try await ImageLoader.shared.loadImage(from: url)
      } catch {
        Elvah.logger.error("Cannot load CPO logo: \(error.localizedDescription)")
        image = nil
      }
    }
  }

  @ViewBuilder private var fallback: some View {
    Text("CPO")
      .typography(.title(size: .xLarge))
      .dynamicTypeSize(...(.accessibility1))
      .redacted(reason: .placeholder)
  }
}

@available(iOS 16.0, *)
#Preview {
  CPOLogo(url: URL(string: "https://i.postimg.cc/50rbSVTY/probably-Connected-Logo.png"))
    .preferredColorScheme(.dark)
}
