// Copyright © elvah. All rights reserved.

/// A list of charge offers.
///
/// This is a wrapper around an array of `ChargeOffer` objects that provides conformance to the
/// `Identifiable` protocol. You can access the offers and build your own UI or pass the
/// ``ChargeOfferList`` to the `chargeOfferDetailPresentation(for:)` view modifier.
public struct ChargeOfferList: Identifiable, Hashable {
	public private(set) var id: String
	public private(set) var offers: [ChargeOffer]

	init(offers: [ChargeOffer]) {
		id = offers.map(\.id).sorted().joined(separator: "-")
		self.offers = offers
	}
}
