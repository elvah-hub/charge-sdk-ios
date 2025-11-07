// Copyright © elvah. All rights reserved.

extension ChargeSite {
  static func parse(_ response: SiteOfferSchema) throws(NetworkError.Client) -> ChargeSite {
    do {
      let site = try Site.parse(response)
      var offers = try response.evses.map { try ChargeOffer.parse($0, in: site) }

      // Set the physical reference for each of the site's charge points
      let chargePoints = offers.map(\.chargePoint)
      let uniqueEvseIdentifiers = Set(chargePoints.map(\.evseId))
      let largestCommonPrefix = chargePoints.largestCommonEvseIdPrefix
      if chargePoints.count > 1, largestCommonPrefix.isEmpty == false {
        for index in offers.indices {
          guard uniqueEvseIdentifiers.count > 1 else {
            offers[index].chargePoint.physicalReference = nil
            continue
          }

          let evseIdentifier = offers[index].chargePoint.evseId
          let trimmedIdentifier = String(evseIdentifier.dropFirst(largestCommonPrefix.count))
          offers[index].chargePoint.physicalReference = trimmedIdentifier.isEmpty ? nil : trimmedIdentifier
        }
      }
      return ChargeSite(
        site: site,
        offers: offers,
        hasFuturePromotion: response.hasFuturePromotion,
      )
    } catch {
      throw .parsing(.field("site"))
    }
  }
}

struct SiteOfferSchema: Decodable {
  var id: String
  var location: [Double]
  var operatorName: String
  var prevalentPowerType: String
  var address: AddressSchema
  var evses: [ChargeOfferSchema]
  var hasFuturePromotion: Bool

  struct AddressSchema: Decodable {
    var locality: String?
    var postalCode: String?
    var streetAddress: [String]?
  }
}
