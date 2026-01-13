// Copyright © elvah. All rights reserved.

@testable import ElvahCharge
import Foundation
import Testing

@Suite("Payment WebView Config Request Encoding Tests")
struct PaymentWebViewConfigRequestBodyTests {
  @Test("Payment config request encodes expected keys")
  func paymentConfigRequestEncodesExpectedKeys() throws {
    var request = ChargeRequest.mock
    request.signedOffer.token = "signed_offer_token"

    let body = PaymentWebViewService.PaymentConfigRequestBody(
      request: request,
      publishableKey: "pk_test_xxx",
      brandColor: "#4F46E5",
    )

    let data = try JSONEncoder().encode(body)
    let jsonObject = try JSONSerialization.jsonObject(with: data)

    guard let json = jsonObject as? [String: Any] else {
      Issue.record("Expected top-level JSON object dictionary.")
      return
    }

    #expect(json["brandColor"] as? String == "#4F46E5")
    #expect(json["evseId"] as? String == request.signedOffer.offer.evseId)
    #expect(
      json["normalizedEvseId"] as? String
        == request.signedOffer.offer.evseId.filter { $0.isLetter || $0.isNumber },
    )

    #expect(json["publishableKey"] as? String == "pk_test_xxx")
    #expect(json["clientSecret"] as? String == request.paymentContext.clientSecret)
    #expect(json["accountId"] as? String == request.paymentContext.accountId)

    let authorisationAmount = json["authorisationAmount"] as? [String: Any]
    #expect(number(authorisationAmount?["value"]) == request.paymentContext.authorizationAmount.amount)
    #expect(authorisationAmount?["currency"] as? String == request.paymentContext.authorizationAmount.identifier)

    let organisationDetails = json["organisationDetails"] as? [String: Any]
    let supportContacts = organisationDetails?["supportContacts"] as? [[String: Any]]
    #expect(supportContacts?.contains(where: { $0["supportType"] as? String == "EMAIL" }) == true)

    let offer = json["offer"] as? [String: Any]
    #expect(offer?["signedOffer"] as? String == "signed_offer_token")

    let price = offer?["price"] as? [String: Any]
    #expect(number(price?["energyPricePerKWh"]) == request.signedOffer.offer.price.pricePerKWh.amount)
    #expect(price?["currency"] as? String == request.signedOffer.offer.price.pricePerKWh.identifier)

    let blockingFee = price?["blockingFee"] as? [String: Any]
    #expect(number(blockingFee?["pricePerMinute"]) == request.signedOffer.offer.price.blockingFee?.pricePerMinute.amount)
    #expect(int(blockingFee?["startsAfterMinutes"]) == request.signedOffer.offer.price.blockingFee?.startsAfterMinute)

    let timeSlots = blockingFee?["timeSlots"] as? [[String: Any]]
    if let firstTimeSlot = timeSlots?.first {
      #expect(firstTimeSlot["startTime"] as? String == "08:00")
      #expect(firstTimeSlot["endTime"] as? String == "12:00")
    }

    #expect(offer?["originalPrice"] != nil)
  }

  private func number(_ value: Any?) -> Double? {
    (value as? NSNumber)?.doubleValue
  }

  private func int(_ value: Any?) -> Int? {
    (value as? NSNumber)?.intValue
  }
}
