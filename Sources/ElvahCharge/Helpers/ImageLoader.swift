// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
actor ImageLoader {
	private static let cache = NSCache<NSURL, UIImage>()
	static let shared = ImageLoader()

	private init() {}

	func loadImage(from url: URL) async throws -> UIImage {
		if let cachedImage = ImageLoader.cache.object(forKey: url as NSURL) {
			return cachedImage
		}

		let (data, _) = try await URLSession.shared.data(from: url)
		guard let image = UIImage(data: data) else {
			throw URLError(.badServerResponse)
		}

		ImageLoader.cache.setObject(image, forKey: url as NSURL)
		return image
	}
}
