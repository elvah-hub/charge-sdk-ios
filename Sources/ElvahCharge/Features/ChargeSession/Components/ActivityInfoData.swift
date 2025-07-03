// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ChargeSessionFeature.Status {
	var activityInfoData: ActivityInfoData? {
		switch self {
		case .sessionLoading:
			return ActivityInfoData(
				state: .animating(iconSystemName: nil),
				title: "Restoring session",
				message: "Attempting to restore charge session."
			)

		case .unauthorized:
			return ActivityInfoData(
				state: .error,
				title: "Payment expired",
				message: "Unfortunately, the time between payment and session start was too long. We need you to authorize a new deposit on your payment method."
			)

		case .unknownError:
			return ActivityInfoData(
				state: .error,
				title: "Server error",
				message: "An unexpected error has occurred. Please try again or contact our support."
			)

		case .startRequested:
			return ActivityInfoData(
				state: .animating(iconSystemName: nil),
				title: "Preparing",
				message: "Reaching out to the charger.\nPlease bear with us for a moment."
			)

		case .startRejected:
			return ActivityInfoData(
				state: .error,
				title: "The charge point reported an error",
				message: "Unfortunately, the charging session could not be started at this charge point. Please try again later or use another charge point."
			)

		case .started:
			return ActivityInfoData(
				state: .animating(iconSystemName: nil),
				title: "Starting",
				message: "Charger is awake!\nStarting session with the charger."
			)

		case .charging:
			return ActivityInfoData(
				state: .animating(iconSystemName: nil),
				title: nil,
				message: nil
			)

		case .stopRequested:
			return ActivityInfoData(
				state: .animating(iconSystemName: nil),
				title: "Stopping",
				message: "We are connecting to the station to end the charging session."
			)

		case .stopRejected:
			return ActivityInfoData(
				state: .error,
				title: "Please end charging manually",
				message: "Please stop charging manually by removing the charging cable first from your car and then from the charging station.\n\nWe will analyze the problem and try to solve it together with the operator of the charging station."
			)

		case .stopped:
			return nil
		}
	}
}
