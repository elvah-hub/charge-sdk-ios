// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ChargeSessionFeature.Status {
	var activityInfoData: ActivityInfoData {
		switch self {
		case .loading:
			return ActivityInfoData(
				state: .animating(iconSystemName: nil),
				title: "Restoring session",
				message: "Attempting to restore charge session"
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
				title: "Server Error",
				message: "An unexpected error occurred."
			)

		case let .activation(progress: progress):
			switch progress {
			case .loading:
				return ActivityInfoData(
					state: .animating(iconSystemName: nil),
					title: "Preparing",
					message: "Reaching out to the charger.\nPlease bear with us for a moment."
				)

			case .success:
				return ActivityInfoData(
					state: .outlined(iconSystemName: "checkmark"),
					title: "Preparing",
					message: "Reaching out to the charger.\nPlease bear with us for a moment."
				)

			case .error:
				return ActivityInfoData(
					state: .error,
					title: "The charge point reported an error",
					message: "Unfortunatly, the charging session could not be started at this charge point. Please try again later or use another charge point."
				)
			}

		case let .connection(progress: progress):
			switch progress {
			case .initial,
			     .success:
				return ActivityInfoData(
					state: .animating(iconSystemName: nil),
					title: "Starting",
					message: "Charger is awake!\nStarting session with the charger."
				)

			case .delayInformation:
				return ActivityInfoData(
					state: .animating(iconSystemName: nil),
					title: "Starting",
					message: "The charger takes longer than usual to start.\nPlease bear with us for a moment."
				)
			}

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

		case .stopFailed:
			return ActivityInfoData(
				state: .error,
				title: "Please end charging manually",
				message: "Please stop charging manually by removing the charging cable first from your car and then from the charging station.\n\nWe will analyze the problem and try to solve it together with the operator of the charging station."
			)

		case .stopped:
			return ActivityInfoData(
				state: .outlined(iconSystemName: "checkmark"),
				title: "Thanks for charging\nwith E.ON",
				message: nil
			)
		}
	}
}
