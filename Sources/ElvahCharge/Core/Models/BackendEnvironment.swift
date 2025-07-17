// Copyright © elvah. All rights reserved.

import Foundation

/// Represents the different backend environments used by the SDK.
public enum BackendEnvironment: Sendable, Hashable {
	/// The integration environment.
	///
	/// - Note: This is only meant to be used for internal debugging and development purposes by the
	/// developers of this SDK.
	@_spi(Debug) case integration

	/// The simulation environment.
	@_spi(Debug) case simulation

	/// The production environment.
	case production

	/// Returns the base domain URL for the current environment.
	package var baseDomain: String {
		return switch self {
		case .integration,
		     .simulation:
			"integrate.int.elvah.de"
		case .production:
			// TODO: Replace with production url once available
			"integrate.int.elvah.de"
		}
	}

	/// Returns `true` if the current environment is `integration`.
	public var isIntegration: Bool {
		self == .integration
	}

	/// Returns `true` if the current environment is `simulation`.
	public var isSimulation: Bool {
		self == .simulation
	}

	/// Returns true if the current environment is `production`.
	public var isProduction: Bool {
		self == .production
	}

	/// Constructs a full URL for a given service name based on the current environment's base domain.
	///
	/// - Returns: A complete URL for the service.
	package func urlForService() -> URL {
		URL(string: "https://\(baseDomain)")!
	}
}
