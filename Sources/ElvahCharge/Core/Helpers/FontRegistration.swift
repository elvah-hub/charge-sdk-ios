// Copyright © elvah. All rights reserved.

import OSLog
import SwiftUI

package enum FontRegistration {
	/// Registers all fonts that this module uses.
	package static func registerFonts() {
		for item in CoreFont.registrableCases {
			registerFont(fileName: item.fileName)
		}
	}

	/// Registers an individual font.
	/// - Parameter fileName: The file name of the font in the bundle.
	private static func registerFont(fileName: String) {
		if isFontRegistered(fileName: fileName) {
			// Host application has already registered the font.
			return
		}

		guard let pathForResourceString = Bundle.core.path(forResource: fileName, ofType: nil)
		else {
			Elvah.logger.error("Could not register font »\(fileName)«: File not found.")
			return
		}

		let url = NSURL(fileURLWithPath: pathForResourceString as String)
		var errorRef: Unmanaged<CFError>?
		CTFontManagerRegisterFontsForURL(url, .process, &errorRef)

		if errorRef != nil {
			Elvah.logger.error("Could not register font »\(fileName)«: \(errorRef.debugDescription)")
		}
	}

	private static func isFontRegistered(fileName: String) -> Bool {
		!UIFont.fontNames(forFamilyName: "Inter").isEmpty
	}
}
