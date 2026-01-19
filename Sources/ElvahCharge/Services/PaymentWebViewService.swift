// Copyright © elvah. All rights reserved.

import Foundation

#if canImport(Get)
  import Get
#endif

final class PaymentWebViewService: Sendable {
  private let client: NetworkClient
  private let apiKey: String
  private let environment: BackendEnvironment

  init(apiKey: String, environment: BackendEnvironment) {
    self.apiKey = apiKey
    self.environment = environment
    
    client = .init(
      name: "PaymentWebView",
      baseURL: environment.paymentWebViewAPIBaseURL,
      environment: environment,
    )
  }

  func createPaymentConfigToken(
    for request: ChargeRequest,
    publishableKey: String,
  ) async throws(NetworkError) -> String {
    do {
      let request = Request<PaymentConfigTokenResponseBody>(
        path: "/api/payment-config",
        method: .post,
        body: PaymentConfigRequestBody(
          request: request,
          publishableKey: publishableKey,
          brandColor: Elvah.Constant.paymentWebViewBrandColorHex,
        ),
      )

      let response = try await client.send(request) { [apiKey] request in
        request.setDistinctId(Elvah.distinctId.rawValue)
        request.setAPIKey(apiKey)
      }

      return response.value.token
    } catch {
      throw error.externalError
    }
  }
}

extension PaymentWebViewService {
  struct PaymentConfigTokenResponseBody: Decodable, Sendable {
    let token: String
  }

  package struct PaymentConfigRequestBody: Encodable, Sendable {
    var brandColor: String
    var evseId: String
    var normalizedEvseId: String
    var offer: Offer

    var publishableKey: String
    var clientSecret: String
    var accountId: String
    var authorisationAmount: Amount
    var organisationDetails: OrganisationDetails

    init(
      request: ChargeRequest,
      publishableKey: String,
      brandColor: String,
    ) {
      let offer = request.signedOffer.offer
      let paymentContext = request.paymentContext

      self.brandColor = brandColor
      evseId = offer.evseId
      normalizedEvseId = Self.normalizedEvseId(from: offer.evseId)
      self.offer = .init(offer: request.signedOffer)

      self.publishableKey = publishableKey
      clientSecret = paymentContext.clientSecret
      accountId = paymentContext.accountId
      authorisationAmount = .init(amount: paymentContext.authorizationAmount)
      organisationDetails = .init(details: paymentContext.organisationDetails)
    }

    private static func normalizedEvseId(from evseId: String) -> String {
      evseId.filter { $0.isLetter || $0.isNumber }
    }

    struct Offer: Encodable, Sendable {
      var price: Price
      var originalPrice: Price?
      var signedOffer: String

      init(offer: SignedChargeOffer) {
        price = .init(price: offer.offer.price)
        originalPrice = offer.offer.originalPrice.map { Price(price: $0) }
        signedOffer = offer.token
      }
    }

    struct Price: Encodable, Sendable {
      var energyPricePerKWh: Double
      var baseFee: Double?
      var blockingFee: BlockingFee?
      var currency: String

      init(price: ChargePrice) {
        energyPricePerKWh = price.pricePerKWh.amount
        baseFee = price.baseFee?.amount
        blockingFee = price.blockingFee.map { BlockingFee(blockingFee: $0) }
        currency = price.pricePerKWh.identifier
      }
    }

    struct BlockingFee: Encodable, Sendable {
      var pricePerMinute: Double
      var startsAfterMinutes: Int?
      var maxAmount: Double?
      var timeSlots: [TimeSlot]?

      init(blockingFee: ChargePrice.BlockingFee) {
        pricePerMinute = blockingFee.pricePerMinute.amount
        startsAfterMinutes = blockingFee.startsAfterMinute
        maxAmount = blockingFee.maxAmount?.amount
        timeSlots = blockingFee.timeSlots?.map { TimeSlot(timeSlot: $0) }
      }
    }

    struct TimeSlot: Encodable, Sendable {
      var startTime: String
      var endTime: String

      init(timeSlot: ChargePrice.BlockingFee.TimeSlot) {
        startTime = Self.format(time: timeSlot.startsAt)
        endTime = Self.format(time: timeSlot.endsAt)
      }

      private static func format(time: Time) -> String {
        String(format: "%02d:%02d", time.hour, time.minute)
      }
    }

    struct Amount: Encodable, Sendable {
      var value: Double
      var currency: String

      init(amount: Currency) {
        value = amount.amount
        currency = amount.identifier
      }
    }

    struct OrganisationDetails: Encodable, Sendable {
      var termsOfConditionUrl: String?
      var privacyUrl: String?
      var companyName: String?
      var logoUrl: String?
      var supportContacts: [SupportContact]

      init(details: PaymentContext.OrganisationDetails) {
        termsOfConditionUrl = details.termsOfConditionUrl?.absoluteString
        privacyUrl = details.privacyUrl?.absoluteString
        companyName = details.companyName
        logoUrl = details.logoUrl?.absoluteString
        supportContacts = details.supportMethods.map { SupportContact(method: $0) }
      }
    }

    struct SupportContact: Encodable, Sendable {
      var supportType: SupportType
      var value: String

      init(method: SupportMethod) {
        switch method {
        case let .phone(number):
          supportType = .phoneNumber
          value = number
        case let .website(url):
          supportType = .url
          value = url.absoluteString
        case let .email(address):
          supportType = .email
          value = address
        case let .whatsApp(number):
          supportType = .whatsApp
          value = number
        }
      }
    }

    enum SupportType: String, Encodable, Sendable {
      case whatsApp = "WHATSAPP"
      case email = "EMAIL"
      case phoneNumber = "PHONE_NUMBER"
      case url = "URL"
    }
  }
}
