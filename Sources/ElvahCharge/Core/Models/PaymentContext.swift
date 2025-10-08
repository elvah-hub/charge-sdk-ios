// Copyright © elvah. All rights reserved.

import Foundation

package struct PaymentContext: Hashable, Sendable, Codable {
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
    organisationDetails: OrganisationDetails,
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
      supportMethods: [SupportMethod],
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
  static var simulation: PaymentContext {
    PaymentContext(
      clientSecret: "simulated client secret",
      paymentId: UUID().uuidString,
      paymentIntentId: UUID().uuidString,
      accountId: "simulated account id",
      authorizationAmount: 0.42,
      organisationDetails: .simulation,
    )
  }

  static var mock: PaymentContext {
    PaymentContext(
      clientSecret: "",
      paymentId: "",
      paymentIntentId: "",
      accountId: "",
      authorizationAmount: 0.42,
      organisationDetails: .mock,
    )
  }
}

package extension PaymentContext.OrganisationDetails {
  static var simulation: PaymentContext.OrganisationDetails {
    PaymentContext.OrganisationDetails(
      companyName: "Beispiel GmbH",
      logoUrl: URL(string: "https://i.postimg.cc/50rbSVTY/probably-Connected-Logo.png"),
      privacyUrl: URL(string: "hhttps://policies.google.com/privacy?hl=en-DE&fg=1"),
      termsOfConditionUrl: URL(string: "https://policies.google.com/terms?hl=en-DE&fg=1"),
      supportMethods: [.email("tech-support@elvah.de")],
    )
  }

  static var mock: PaymentContext.OrganisationDetails {
    PaymentContext.OrganisationDetails(
      companyName: "Mock company",
      logoUrl: URL(string: "https://i.postimg.cc/50rbSVTY/probably-Connected-Logo.png"),
      privacyUrl: URL(string: "https://www.elvah.de/"),
      termsOfConditionUrl: URL(string: "https://www.elvah.de/"),
      supportMethods: [.email("tech-support@elvah.de")],
    )
  }
}
