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
		ZStack {
			if let image = image {
				Image(uiImage: image)
					.resizable()
					.aspectRatio(contentMode: .fit)
			} else if isLoading {
				ZStack {
					RoundedRectangle(cornerRadius: 10)
						.fill(.container)
						.aspectRatio(1, contentMode: .fit)
					ProgressView()
						.progressViewStyle(.inlineActivity)
				}
			} else {
				fallback
			}
		}
		.frame(height: 60)
		.padding(.M)
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
	CPOLogo(url: URL(string: "https://placehold.co/600x.png"))
		.preferredColorScheme(.dark)
}
