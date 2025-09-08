// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
extension ChargeOfferDetailFeature {
	struct ChargePointSection: View {
		typealias Action = (_ offers: ChargeOffer) -> Void

		@FocusState private var isSearchFieldFocused: Bool
		@Environment(\.dynamicTypeSize) private var dynamicTypeSize
		@Default(.chargeSessionContext) private var chargeSessionContext
		@State private var searchText: String = ""
		@Binding private var offersSectionOrigin: CGPoint
		private var largestCommonPrefix: String
		private var offers: LoadableState<[ChargeOffer]>
		private var processingOffer: ChargeOffer?
		private var offerAction: Action
		private var chargeSessionAction: () -> Void

		init(
			offers: LoadableState<[ChargeOffer]>,
			offersSectionOrigin: Binding<CGPoint>,
			processingOffer: ChargeOffer?,
			offerAction: @escaping Action,
			chargeSessionAction: @escaping () -> Void
		) {
			self.offers = offers
			_offersSectionOrigin = offersSectionOrigin
			self.processingOffer = processingOffer
			self.offerAction = offerAction
			self.chargeSessionAction = chargeSessionAction
			largestCommonPrefix = offers.data?.largestCommonEvseIdPrefix ?? ""
		}

		var body: some View {
			VStack(alignment: .leading, spacing: 16) {
				switch offers {
				case .absent,
				     .loading,
				     .error:
					activityContent
				case let .loaded(offers):
					offerBanner(for: offers)
					chargePointList(for: offers)
				}
			}
			.animation(.default, value: offers)
			.frame(maxWidth: .infinity, alignment: .leading)
		}

		@ViewBuilder private func offerBanner(for offers: [ChargeOffer]) -> some View {
			if chargeSessionContext != nil {
				Button {
					chargeSessionAction()
				} label: {
					CustomSection {
						HStack {
							Image(.bolt)
								.foregroundStyle(.brand)
								.typography(.copy(size: .xLarge), weight: .bold)
							Text("Manage your current charge session", bundle: .elvahCharge)
								.frame(maxWidth: .infinity, alignment: .leading)
							Image(.chevronRight)
						}
					}
				}
				.typography(.copy(size: .medium), weight: .bold)
				.foregroundStyle(.primaryContent)
				.padding(.horizontal, 16)
				.dynamicTypeSize(...(.accessibility1))
			} else if offers.contains(where: { $0.isDiscounted }) {
				CustomSection {
					HStack(spacing: Size.S.size) {
						if dynamicTypeSize.isAccessibilitySize == false {
							Image(.discounting)
						}
						Text(
							"Start charging before the offer ends & get the full discount!",
							bundle: .elvahCharge
						)
					}
				}
				.typography(.copy(size: .medium), weight: .bold)
				.foregroundStyle(.primaryContent)
				.padding(.horizontal, 16)
				.dynamicTypeSize(...(.accessibility1))
			}
		}

		@ViewBuilder private func chargePointList(for offers: [ChargeOffer]) -> some View {
			let filteredOffers = filtered(offers: offers)

			LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
				Section {
					TimelineView(.periodic(from: .now, by: 1)) { _ in
						VStack(spacing: 0) {
							if filteredOffers.isEmpty, isSearchActive {
								noResultsView
							} else {
								ForEach(filteredOffers) { offer in
									chargePointButton(for: offer)
										.overlay {
											loadingOverlay(show: processingOffer?.id == offer.id)
										}
									Divider().padding(.leading, .M)
								}
							}
						}
						.buttonStyle(ChargePointButtonStyle())
						.foregroundStyle(.primaryContent)
						.animation(.bouncy, value: processingOffer)
						.animation(.default, value: searchText)
					}
				} header: {
					if offers.count >= 5 {
						searchField
							.background(Color.canvas)
					}
				}
			}
			.overlay(alignment: .top) {
				Color.clear.frame(height: 0)
					.scrollPositionReader($offersSectionOrigin, in: "ScrollView")
			}
			.frame(maxWidth: .infinity)
		}

		private var isSearchActive: Bool {
			searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
		}

		private func filtered(offers: [ChargeOffer]) -> [ChargeOffer] {
			let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
			guard needle.isEmpty == false else {
				return offers
			}

			func matches(_ value: String?) -> Bool {
				guard let value = value, value.isEmpty == false else {
					return false
				}
				return value.localizedCaseInsensitiveContains(needle)
			}

			return offers.filter { offer in
				let chargePoint = offer.chargePoint
				return matches(chargePoint.evseId)
					|| matches(chargePoint.physicalReference)
					|| chargePoint.evseId.fuzzyMatches(needle)
					|| matches(String(chargePoint.evseId.filter { $0 != "*" }))
			}
		}

		@ViewBuilder private var noResultsView: some View {
			VStack(alignment: .center, spacing: Size.S.size) {
				Text("No results for \(Text(verbatim: searchText))", bundle: .elvahCharge)
					.typography(.copy(size: .xLarge), weight: .bold)
					.foregroundStyle(.primaryContent)
				Text("Check your search input and try again", bundle: .elvahCharge)
					.typography(.copy(size: .small))
					.foregroundStyle(.secondaryContent)
				Button("Clear filters", bundle: .elvahCharge) {
					searchText = ""
				}
				.buttonStyle(.textPrimary)
			}
			.padding(.vertical, .M)
			.multilineTextAlignment(.center)
			.frame(maxWidth: .infinity)
			.animation(nil, value: searchText)
		}

		@ViewBuilder private var searchField: some View {
			HStack(spacing: Size.S.size) {
				Image(systemName: "magnifyingglass")
					.accessibilityHidden(true)
				TextField("Type charge point ID", text: $searchText, prompt: Text("Type charge point ID", bundle: .elvahCharge))
					.focused($isSearchFieldFocused)
					.typography(.copy(size: .medium))
					.frame(maxWidth: .infinity, alignment: .leading)
				Spacer(minLength: 0)
				if searchText.isEmpty == false {
					Button {
						searchText = ""
					} label: {
						Image(systemName: "xmark")
							.foregroundStyle(.primaryContent)
					}
					.accessibilityHidden(true)
				}
			}
			.padding(.M)
			.background(.container, in: .rect(cornerRadius: 8))
			.overlay {
				RoundedRectangle(cornerRadius: 8)
					.strokeBorder(Color.decorativeStroke, lineWidth: 1)
			}
			.padding(.horizontal, .M)
			.background(Color.canvas)
			.padding(.bottom, .M)
			.dynamicTypeSize(...(.accessibility2))
			.accessibilityElement(children: .combine)
			.accessibilityAction(named: Text("Clear input", bundle: .elvahCharge)) {
				searchText = ""
			}
			.contentShape(.rect)
			.onTapGesture {
				isSearchFieldFocused = true
			}
		}

		@ViewBuilder private func loadingOverlay(show: Bool) -> some View {
			ZStack(alignment: .trailing) {
				if show {
					LinearGradient(
						stops: [
							Gradient.Stop(color: .container, location: 0),
							Gradient.Stop(color: .clear, location: 1),
						],
						startPoint: .trailing,
						endPoint: .leading
					)
					.transition(.opacity)
				}
				if show {
					ProgressView()
						.progressViewStyle(.inlineActivity)
						.padding(.trailing, .L)
						.transition(.opacity.combined(with: .move(edge: .trailing)))
				}
			}
		}

		@ViewBuilder private func chargePointButton(for offer: ChargeOffer) -> some View {
			let chargePoint = offer.chargePoint
			Button {
				offerAction(offer)
			} label: {
				let evseDisplayText: String = {
					if let physicalReference = chargePoint.physicalReference, physicalReference.isEmpty == false {
						return physicalReference
					}
					if chargePoint.evseId.hasPrefix(largestCommonPrefix) {
						return String(chargePoint.evseId.dropFirst(largestCommonPrefix.count))
					}
					return chargePoint.evseId
				}()

				let evseIdLabel = Text(verbatim: evseDisplayText)
					.typography(.copy(size: .medium), weight: .bold)
					.foregroundStyle(.onBrand)
					.padding(.horizontal, .XS)
					.padding(.vertical, .XXS)
					.background(.brand, in: .rect(cornerRadius: 4))

				let priceLabel = Text(offer.price.pricePerKWh.formatted())

				let originalPriceLabel: Text? = {
					if let originalPrice = offer.originalPrice?.pricePerKWh {
						return Text(originalPrice.formatted())
					}
					return nil
				}()

				let connectorTitle: String? = {
					if let connector = chargePoint.connectors.sorted().first {
						if connector == .type2 {
							return "Type 2"
						}
						return connector.localizedTitle
					} else if let powerType = chargePoint.powerType {
						return powerType.localizedTitle
					} else {
						return nil
					}
				}()

				VStack(alignment: .leading, spacing: Size.XXS.size) {
					HStack(alignment: .firstTextBaseline) {
						evseIdLabel
						Spacer()
						if offer.isDiscounted, let original = originalPriceLabel {
							HStack(spacing: Size.XS.size) {
								priceLabel
									.typography(.copy(size: .medium), weight: .bold)
									.foregroundStyle(.primaryContent)
								original
									.typography(.copy(size: .small), weight: .regular)
									.foregroundStyle(.secondaryContent)
									.strikethrough()
							}
						} else {
							priceLabel
								.typography(.copy(size: .medium), weight: .bold)
								.foregroundStyle(.primaryContent)
						}
					}

					HStack(alignment: .firstTextBaseline) {
						Spacer()
						if let connectorTitle {
							Text("\(connectorTitle) • \(chargePoint.maxPowerInKWFormatted)")
						} else {
							Text(chargePoint.maxPowerInKWFormatted)
						}
					}
					.typography(.copy(size: .small))
					.foregroundStyle(.secondaryContent)
				}
				.withChevron()
				.padding(.M)
			}
			.opacity(offer.isAvailable && chargeSessionContext == nil ? 1 : 0.5)
			.disabled(offer.isAvailable == false || chargeSessionContext != nil)
			.animation(.default, value: offer.isAvailable)
		}

		@ViewBuilder private var activityContent: some View {
			var title: LocalizedStringKey? {
				if offers.isError {
					return "An error occurred"
				}
				return nil
			}

			var message: LocalizedStringKey? {
				if offers.isError {
					return "The charge offers could not be loaded. Please try again later."
				}
				return nil
			}

			var state: ActivityInfoComponent.ActivityState {
				if offers.isError {
					return .error
				}
				return .animating
			}

			ActivityInfoComponent(state: state, title: title, message: message)
				.padding(.horizontal, 16)
				.padding(.vertical, 16)
		}
	}
}

// MARK: - Helpers

@available(iOS 16.0, *)
private struct AvailabilityPill: View {
	var chargePoint: ChargePoint

	var body: some View {
		Text(chargePoint.localizedAvailability)
			.typography(.copy(size: .small), weight: .bold)
			.foregroundStyle(chargePoint.availabilityForegroundColor)
			.padding(.horizontal, 8)
			.padding(.vertical, 4)
			.background(chargePoint.availabilityBackgroundColor, in: .capsule)
	}
}

@available(iOS 16.0, *)
private struct ChargePointButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.contentShape(.rect)
			.background {
				if configuration.isPressed {
					Color.decorativeStroke
				}
			}
	}
}

@available(iOS 16.0, *)
#Preview {
	NavigationStack {
		ZStack {
			Color.canvas.ignoresSafeArea()
			ScrollView {
				VStack(spacing: 20) {
					RoundedRectangle(cornerRadius: 8)
						.foregroundStyle(.decorativeStroke)
						.frame(height: 100)
						.padding(.horizontal, 16)
						.opacity(0.2)
					ChargeOfferDetailFeature.ChargePointSection(
						offers: .loaded([.mockAvailable, .mockUnavailable, .mockOutOfService]),
						offersSectionOrigin: .constant(.zero),
						processingOffer: .mockAvailable
					) { _ in } chargeSessionAction: {}
				}
			}
		}
	}
	.withFontRegistration()
	.withMockEnvironmentObjects()
	.preferredColorScheme(.dark)
}
