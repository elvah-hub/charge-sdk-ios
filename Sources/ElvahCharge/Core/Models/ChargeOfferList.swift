// Copyright © elvah. All rights reserved.

import Foundation

/// A collection of charge offers with a unique identifier for presentation purposes.
public struct ChargeOfferList: Identifiable, Sendable, Collection, RandomAccessCollection, Equatable {
	/// A unique identifier for this list of charge offers.
	public var id = UUID()

	/// The charge offers contained in this list.
	public var offers: [ChargeOffer]

	/// Creates a new charge offer list with the given offers.
	/// - Parameter offers: The charge offers to include in the list.
	public init(offers: [ChargeOffer]) {
		self.offers = offers
	}

	// MARK: - Collection conformance

	public typealias Element = ChargeOffer
	public typealias Index = Array<ChargeOffer>.Index

	public var startIndex: Index {
		offers.startIndex
	}

	public var endIndex: Index {
		offers.endIndex
	}

	public subscript(position: Index) -> Element {
		offers[position]
	}

	public func index(after i: Index) -> Index {
		offers.index(after: i)
	}
}

package extension ChargeOfferList {
	/// Returns the site if all offers in the list have the same site, otherwise returns nil.
	var commonSite: Site? {
		guard !offers.isEmpty else {
			return nil
		}

		let firstSiteId = offers.first?.site.id
		let allOffersHaveSameSite = offers.allSatisfy { $0.site.id == firstSiteId }

		return allOffersHaveSameSite ? offers.first?.site : nil
	}
}
