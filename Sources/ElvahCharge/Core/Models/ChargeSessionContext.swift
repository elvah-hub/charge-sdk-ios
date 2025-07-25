// Copyright © elvah. All rights reserved.

import Foundation

/// A context for a charge session, which is stored in UserDefaults.
package struct ChargeSessionContext: Codable, Hashable, Sendable {
	/// The site where the charge point is located.
	package var site: Site

	/// The details of the deal associated with this charge session.
	package var signedOffer: SignedChargeOffer

	/// The details of the CPO that owns the charge point.
	package var organisationDetails: PaymentContext.OrganisationDetails

	/// The authentication details for the charge session.
	package var authentication: ChargeAuthentication

	/// The value identifying the purchase that started this charge session.
	package var paymentId: String

	/// The time when this charge session started.
	package var startedAt: Date

	package init(
		site: Site,
		signedOffer: SignedChargeOffer,
		organisationDetails: PaymentContext.OrganisationDetails,
		authentication: ChargeAuthentication,
		paymentId: String,
		startedAt: Date
	) {
		self.site = site
		self.signedOffer = signedOffer
		self.organisationDetails = organisationDetails
		self.authentication = authentication
		self.paymentId = paymentId
		self.startedAt = startedAt
	}

	package static func from(request: AuthenticatedChargeRequest) -> ChargeSessionContext {
		ChargeSessionContext(
			site: request.site,
			signedOffer: request.signedOffer,
			organisationDetails: request.paymentContext.organisationDetails,
			authentication: request.authentication,
			paymentId: request.paymentContext.paymentId,
			startedAt: Date() // TODO: Replace with date from backend, once available
		)
	}

	package func matches(_ chargePoint: ChargePoint) -> Bool {
		signedOffer.chargePoint.evseId == chargePoint.evseId
	}
}
