// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
private struct SafeAreaReaderModifier: ViewModifier {
	@Binding var safeAreaInsets: EdgeInsets

	func body(content: Content) -> some View {
		content
			.background {
				GeometryReader { proxy in
					Color.clear
						.onAppear {
							safeAreaInsets = proxy.safeAreaInsets
						}
						.onChange(of: proxy.size.height) { value in
							safeAreaInsets = proxy.safeAreaInsets
						}
				}
			}
	}
}

@available(iOS 16.0, *)
package extension View {
	func safeAreaReader(_ insets: Binding<EdgeInsets>) -> some View {
		modifier(SafeAreaReaderModifier(safeAreaInsets: insets))
	}
}
