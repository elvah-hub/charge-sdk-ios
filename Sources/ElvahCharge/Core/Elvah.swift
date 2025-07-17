// Copyright © elvah. All rights reserved.

import Combine
import Foundation
import OSLog

#if canImport(Defaults)
	import Defaults
#endif

/// A configuration object for the elvah Charge SDK.
public enum Elvah {
	/// A unique identifier that is used as prefix in shared storage like `UserDefaults`.
	package static let id = UUID(uuidString: "40686B65-A601-4F98-BA8E-A6714A58E5B1")!

	/// A logger instance for the SDK.
	package static let logger = Logger(subsystem: "de.elvah.sdk", category: "Elvah")

	/// An internal logger instance for the SDK.
	package private(set) nonisolated(unsafe) static var internalLogger = Logger(OSLog.disabled)

	/// A flag indicating if the SDK is in debug mode.
	package private(set) nonisolated(unsafe) static var isDebugMode = false

	/// A unique identifier for the SDK. It is generated the first time the SDK is initialized and
	/// helps with identifying users anonymously.
	///
	/// - Important: This identifier is a randomly generated base62 string and cannot be used to track
	/// users outside the use of this SDK.
	package static var distinctId: ElvahDistinctId {
		if Defaults[.distinctId] == nil {
			Defaults[.distinctId] = ElvahDistinctId.generate()
		}
		return Defaults[.distinctId]!
	}

	/// A debug session delegate.
	package private(set) nonisolated(unsafe)
	static var debugSessionDelegate: (any URLSessionDelegate)?

	/// The configuration for the elvah Charge SDK.
	///
	/// - Note: The configuration is marked `nonisolated(unsafe)` to allow convenient access across
	/// internal SDK methods. This is still thread safe because writing access is limited to the main
	/// actor and can only happen in exactly one place (see ``Elvah/initialize(with:)`` for more
	/// information).
	package private(set) nonisolated(unsafe) static var _configuration: Configuration?
	package nonisolated(unsafe) static var configuration: Configuration {
		if let _configuration {
			return _configuration
		}
		logger.warning(
			"Elvah SDK is not initialized. Please call `Elvah.initialize(with:)` before using it."
		)
		return .uninitialized
	}

	/// Initializes the elvah Charge SDK core with the provided configuration.
	///
	/// - Note: If the core has already been initialized, calling this method again will do nothing.
	/// To reset the core, call ``Elvah/destroy()``, and then you can call this method again.
	///
	/// - Parameter configuration: The configuration to use.
	@MainActor package static func initializeCore(with configuration: Configuration) {
		guard _configuration == nil else {
			return
		}

		// Store the configuration
		_configuration = configuration

		// Register the SDK's fonts
		FontRegistration.registerFonts()
	}

	/// Destroys the internal Elvah initialization setup.
	@MainActor @_spi(Debug) public static func destroy() {
		_configuration = nil
	}

	/// Enables an internal debug mode in the SDK.
	///
	/// - Note: This is only meant to be used for internal debugging and development purposes by the
	/// developers of this SDK.
	@MainActor @_spi(Debug) public static func enableDebugMode(
		debugSessionDelegate: (any URLSessionDelegate)? = nil
	) {
		isDebugMode = true
		Self.debugSessionDelegate = debugSessionDelegate
		internalLogger = Logger(subsystem: "de.elvah.sdk", category: "Internal")
	}
}

package extension Elvah {
	enum Constant {
		/// The default radius in meters.
		static let defaultRadius: Double = 20000
	}
}

public extension Elvah {
	/// A configuration object for the elvah SDK.
	struct Configuration: Hashable {
		/// The api key for the SDK.
		public let apiKey: String

		/// The `UserDefaults` instance that the SDK should use.
		///
		/// Defaults to `UserDefaults.standard`.
		public let store: UserDefaults

		/// An SDK internal flag indicating if the configuration is the fallback, empty configuration.
		///
		/// This will be true until the SDK is properly initialized by the client.
		package let isUninitialized: Bool

		/// The environment to use when loading data.
		package let environment: BackendEnvironment

		/// The theme to apply to the SDK's native components.
		package let theme: Theme

		/// A property that shortcuts to `theme.color`.
		package var color: Theme.Color {
			theme.color
		}

		/// A configuration object for the elvah SDK.
		/// - Parameters:
		///   - apiKey: The api key to use the SDK.
		///   - theme: The theme to apply to the SDK's native components.
		///   - store: The `UserDefaults` store. Defaults to `UserDefaults.standard`.`
		public init(
			apiKey: String,
			theme: Theme = .default,
			store: UserDefaults = .standard
		) {
			self.apiKey = apiKey
			environment = .production
			self.theme = theme
			self.store = store
			isUninitialized = false
		}

		/// A configuration object for the elvah SDK.
		/// - Parameters:
		///   - apiKey: The api key to use the SDK.
		///   - environment: The environment to use. Defaults to ``BackendEnvironment/production``.
		///   - theme: The theme to apply to the SDK's native components.
		///   - store: The `UserDefaults` store. Defaults to `UserDefaults.standard`.`
		///
		/// - Note: This is only meant to be used for internal debugging and development purposes by the
		/// developers of this SDK.
		@_spi(Debug) public init(
			apiKey: String,
			environment: BackendEnvironment,
			theme: Theme = .default,
			store: UserDefaults = .standard
		) {
			self.apiKey = apiKey
			self.environment = environment
			self.theme = theme
			self.store = store
			isUninitialized = false
		}

		/// A helper initializer to set the `isUninitialized` flag to `true`.
		private init(
			apiKey: String,
			environment: BackendEnvironment = .production,
			theme: Theme = .default,
			store: UserDefaults = .standard,
			isUninitialized: Bool
		) {
			self.apiKey = apiKey
			self.environment = environment
			self.theme = theme
			self.store = store
			self.isUninitialized = isUninitialized
		}

		/// Creates a simulation configuration for testing purposes.
		///
		/// - Parameters:
		///   - theme: The theme to apply to the SDK's native components.
		///   - store: The `UserDefaults` store. Defaults to `UserDefaults.standard`.
		/// - Returns: A Configuration instance configured for simulation mode.
		public static func simulation(
			theme: Theme = .default,
			store: UserDefaults = .standard
		) -> Configuration {
			return Configuration(
				apiKey: "",
				environment: .simulation,
				theme: theme,
				store: store,
				isUninitialized: true
			)
		}

		/// An empty configuration that is used when the client has not (yet) initialized the
		/// configuration.
		fileprivate static var uninitialized: Configuration {
			.init(
				apiKey: "",
				environment: .production,
				theme: .default,
				store: .standard,
				isUninitialized: true
			)
		}
	}
}
