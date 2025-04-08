// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct BottomSheetConfiguration: Equatable {
	var title: LocalizedStringKey?
	var subtitle: LocalizedStringKey?
}

@available(iOS 16.0, *)
struct BottomSheetConfigurationKey: PreferenceKey {
	nonisolated(unsafe) static let defaultValue: BottomSheetConfiguration? = nil

	static func reduce(
		value: inout BottomSheetConfiguration?,
		nextValue: () -> BottomSheetConfiguration?
	) {
		value = nextValue() ?? value
	}
}

@available(iOS 16.0, *)
extension View {
	func bottomSheetConfiguration(
		title: LocalizedStringKey,
		subtitle: LocalizedStringKey? = nil
	) -> some View {
		preference(
			key: BottomSheetConfigurationKey.self,
			value: .init(title: title, subtitle: subtitle)
		)
	}

	func bottomSheetConfiguration(title: LocalizedStringKey?) -> some View {
		preference(
			key: BottomSheetConfigurationKey.self,
			value: .init(title: title, subtitle: nil)
		)
	}
}
