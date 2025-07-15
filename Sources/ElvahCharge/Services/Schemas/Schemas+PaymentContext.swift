// Copyright © elvah. All rights reserved.

import Foundation

extension PaymentContext {
	static func parse(
		_ response: PaymentContextSchema
	) throws(NetworkError.Client) -> PaymentContext {
		var logoUrl: URL? {
			guard let logoUrlString = response.organisationDetails.logoUrl else {
				return nil
			}
			return URL(string: logoUrlString)
		}

		var privacyUrl: URL? {
			guard let privacyUrlString = response.organisationDetails.privacyUrl else {
				return nil
			}
			return URL(string: privacyUrlString)
		}

		var termsOfConditionUrl: URL? {
			guard let termsUrlString = response.organisationDetails.termsOfConditionUrl
			else {
				return nil
			}
			return URL(string: termsUrlString)
		}

		var supportMethods: [SupportMethod] {
			response.organisationDetails.supportContacts.compactMap { method in
				switch method.supportType {
				case "WHATSAPP":
					return .whatsApp(method.value)
				case "EMAIL":
					return .email(method.value)
				case "PHONE_NUMBER":
					return .phone(method.value)
				case "URL":
					guard let url = URL(string: method.value) else {
						Elvah.logger.parseError(in: response, for: \.organisationDetails.supportContacts)
						return nil
					}
					return .website(url)
				default:
					Elvah.logger.parseError(in: response, for: \.organisationDetails.supportContacts)
					return nil
				}
			}
		}

		return PaymentContext(
			clientSecret: response.clientSecret,
			paymentId: response.paymentId,
			paymentIntentId: response.paymentIntentId,
			accountId: response.accountId,
			authorizationAmount: Currency(
				response.authorisationAmount.value,
				identifier: response.authorisationAmount.currency
			),
			organisationDetails: PaymentContext.OrganisationDetails(
				companyName: response.organisationDetails.companyName,
				logoUrl: logoUrl,
				privacyUrl: privacyUrl,
				termsOfConditionUrl: termsOfConditionUrl,
				supportMethods: supportMethods
			)
		)
	}
}

struct PaymentContextSchema: Decodable {
	let paymentId: String
	let organisationDetails: OrganisationDetails
	let clientSecret: String
	let paymentIntentId: String
	let accountId: String
	let authorisationAmount: AuthorisationAmount

	struct OrganisationDetails: Decodable {
		let companyName: String?
		let logoUrl: String?
		let privacyUrl: String?
		let termsOfConditionUrl: String?
		let supportContacts: [SupportMethod]
	}

	struct AuthorisationAmount: Decodable {
		let value: Double
		let currency: String
	}

	struct SupportMethod: Hashable, Sendable, Codable {
		package var value: String
		package var supportType: String
	}
}
