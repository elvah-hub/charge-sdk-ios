// Copyright © elvah. All rights reserved.

import Foundation

package struct PaymentContext: Hashable, Sendable {
	package var clientSecret: String
	package var paymentId: String
	package var paymentIntentId: String
	package var accountId: String
	package var authorizationAmount: Currency
	package var organisationDetails: OrganisationDetails

	package init(
		clientSecret: String,
		paymentId: String,
		paymentIntentId: String,
		accountId: String,
		authorizationAmount: Currency,
		organisationDetails: OrganisationDetails
	) {
		self.clientSecret = clientSecret
		self.paymentId = paymentId
		self.paymentIntentId = paymentIntentId
		self.accountId = accountId
		self.authorizationAmount = authorizationAmount
		self.organisationDetails = organisationDetails
	}
}

package extension PaymentContext {
	struct OrganisationDetails: Hashable, Sendable, Codable {
		package var companyName: String?
		package var logoUrl: URL?
		package var privacyUrl: URL?
		package var termsOfConditionUrl: URL?
		package var supportMethods: [SupportMethod]

		package init(
			companyName: String?,
			logoUrl: URL?,
			privacyUrl: URL?,
			termsOfConditionUrl: URL?,
			supportMethods: [SupportMethod]
		) {
			self.companyName = companyName
			self.logoUrl = logoUrl
			self.privacyUrl = privacyUrl
			self.termsOfConditionUrl = termsOfConditionUrl
			self.supportMethods = supportMethods
		}

		package var hasLegalUrls: Bool {
			privacyUrl != nil && termsOfConditionUrl != nil
		}
	}
}

package extension PaymentContext {
	static var mock: PaymentContext {
		PaymentContext(
			clientSecret: "",
			paymentId: "",
			paymentIntentId: "",
			accountId: "",
			authorizationAmount: 0.42,
			organisationDetails: .mock
		)
	}
}

package extension PaymentContext.OrganisationDetails {
	static var mock: PaymentContext.OrganisationDetails {
		PaymentContext.OrganisationDetails(
			companyName: "Mock company",
			logoUrl: URL(string: "https://placehold.co/600x"),
			privacyUrl: URL(string: "https://www.elvah.de/"),
			termsOfConditionUrl: URL(string: "https://www.elvah.de/"),
			supportMethods: [.email("help@elvah.de")]
		)
	}
}
