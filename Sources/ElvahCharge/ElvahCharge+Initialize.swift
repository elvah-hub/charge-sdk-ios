// Copyright © elvah. All rights reserved.

@preconcurrency import Stripe
import SwiftUI

public extension Elvah {
	@MainActor private static var stripeConfigurationFetchTask: Task<Void, Never>?

	/// Initializes the elvah Charge SDK with the provided configuration.
	///
	/// To see configurable options, see ``Elvah/Configuration-swift.struct``.
	///
	/// - Important: Initialize the elvah Charge SDK as soon as possible in your app's lifecycle.
	/// The app's `init()` is a good place to do this, but you can also use an `AppDelegate`.
	/// - Parameter configuration: The configuration to use.
	@MainActor static func initialize(with configuration: Configuration) {
		guard  Elvah.configuration.isUninitialized else {
			Elvah.logger.info("SDK already initialized. Ignoring duplicate initialization.")
			return
		}

		initializeCore(with: configuration)
		if #available(iOS 16.0, *) {
			fetchStripeConfiguration(configuration: configuration)
		} else {
			Elvah.logger.info("Cannot set up Stripe connection as iOS 15 is not supported.")
		}
	}

	// MARK: - Stripe Configuration

	@available(iOS 16.0, *)
	@MainActor private static func fetchStripeConfiguration(configuration: Configuration) {
		if configuration.environment == .simulation {
			// No Stripe configuration needed for simulation mode
			return
		}
		stripeConfigurationFetchTask?.cancel()
		stripeConfigurationFetchTask = Task {
			do {
				let provider = ChargeSettlementProvider.live
				let stripeConfiguration = try await provider.stripeConfiguration()
				try Task.checkCancellation()
				StripeAPI.defaultPublishableKey = stripeConfiguration.publishableKey
				internalLogger.info("Successfully loaded stripe configuration.")
			} catch is CancellationError {} catch {
				logger.critical("Failed to load stripe configuration. The SDK is unable to be initialized.")
			}
		}
	}
}
