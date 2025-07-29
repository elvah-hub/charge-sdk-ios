// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
struct ChargeEntryActivityView: View {
	@Environment(\.navigationRoot) private var navigationRoot

	var state: ChargeEntryFeature.ViewState

	var body: some View {
		let data = activityInfoData
		ActivityInfoComponent(state: data.state, title: data.title, message: data.message)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.toolbar {
				if [
					.loading,
					.preparingChargeRequest,
					.preparedChargeRequest,
				].contains(state) == false {
					ToolbarItem(placement: .topBarLeading) {
						CloseButton {
							navigationRoot.dismiss()
						}
					}
				}
			}
	}

	// MARK: - Helpers

	private var activityInfoData: ActivityInfoData {
		switch state {
		case .loading:
			ActivityInfoData(
				state: .animating,
				title: nil,
				message: nil
			)
		case .missingChargeContext:
			ActivityInfoData(
				state: .outlined(iconSystemName: "xmark"),
				title: nil,
				message: nil
			)
		case .preparingChargeRequest:
			ActivityInfoData(
				state: .animating,
				title: "Loading charge point details",
				message: "Checking for current price.\nWe're almost there!"
			)
		case .preparedChargeRequest:
			ActivityInfoData(
				state: .outlined(iconSystemName: "checkmark"),
				title: "Loading charge point details",
				message: "Checking for current price.\nWe're almost there!"
			)
		case .failedToPrepareChargeRequest:
			ActivityInfoData(
				state: .error,
				title: "Oh, that didn't work out!",
				message: "An unexpected error has occurred. Please try again or contact our support."
			)
		}
	}
}

// MARK: - Helpers

@available(iOS 16.0, *)
private extension ChargeEntryActivityView {
	struct ActivityInfoData {
		var state: ActivityInfoComponent.ActivityState
		var title: LocalizedStringKey?
		var message: LocalizedStringKey?
	}
}

@available(iOS 17.0, *)
#Preview {
	ChargeEntryActivityView(state: .failedToPrepareChargeRequest)
		.preferredColorScheme(.dark)
		.withFontRegistration()
}
