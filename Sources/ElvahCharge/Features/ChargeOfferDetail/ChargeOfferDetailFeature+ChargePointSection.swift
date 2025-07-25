// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
extension ChargeOfferDetailFeature {
	struct ChargePointSection: View {
		typealias Action = (_ offers: ChargeOffer) -> Void

		@Environment(\.dynamicTypeSize) private var dynamicTypeSize
		@Default(.chargeSessionContext) private var chargeSessionContext
		@State private var selectedPowerType: PowerType
		@Binding private var offersSectionOrigin: CGPoint
		private var offers: LoadableState<[ChargeOffer]>
		private var processingOffer: ChargeOffer?
		private var offerAction: Action
		private var chargeSessionAction: () -> Void

		init(
			initialPowerTypeSelection: PowerType? = nil,
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
			self.offerAction = offerAction
			self.chargeSessionAction = chargeSessionAction
			_selectedPowerType = State(initialValue: initialPowerTypeSelection ?? .ac)
		}

		var body: some View {
			VStack(alignment: .leading, spacing: 16) {
				Text("Select charge point", bundle: .elvahCharge)
					.typography(.copy(size: .xLarge), weight: .bold)
					.foregroundStyle(.primaryContent)
					.padding(.horizontal, 16)
					.dynamicTypeSize(...(.accessibility2))
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
			.animation(.default, value: selectedPowerType)
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
							Text("You are already charging", bundle: .elvahCharge)
								.frame(maxWidth: .infinity, alignment: .leading)
							Image(.chevronRight)
						}
					}
				}
				.typography(.copy(size: .medium), weight: .bold)
				.foregroundStyle(.primaryContent)
				.padding(.horizontal, 16)
				.dynamicTypeSize(...(.accessibility1))
			} else {
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
			VStack(alignment: .leading, spacing: 24) {
				TimelineView(.periodic(from: .now, by: 1)) { _ in
					let hasMultiplePowerTypes = offers
						.compactMap(\.chargePoint.powerType)
						.unique()
						.count > 1
					let groups = chargePointGroups(for: hasMultiplePowerTypes ? selectedPowerType : nil)

					VStack(spacing: 0) {
						if hasMultiplePowerTypes {
							PowerTypeSelector(selection: $selectedPowerType)
						}
						ForEach(groups) { group in
							ForEach(group.offers) { offers in
								chargePointButton(for: offers)
									.overlay {
										loadingOverlay(show: processingOffer?.id == offers.id)
									}
							}
							.buttonStyle(ChargePointButtonStyle())
							.foregroundStyle(.primaryContent)
							if group != groups.last {
								Divider()
									.padding(.leading, .M)
							}
						}
					}
					.animation(.default, value: groups)
					.animation(.bouncy, value: processingOffer)
				}
			}
			.overlay(alignment: .top) {
				Color.clear.frame(height: 0)
					.scrollPositionReader($offersSectionOrigin, in: "ScrollView")
			}
			.frame(maxWidth: .infinity)
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
				let evseIdLabel = Text(chargePoint.evseId)
					.typography(.copy(size: .medium), weight: .bold)

				let priceLabel = Text(offer.price.pricePerKWh.formatted() + " / kWh")
					.typography(.copy(size: .medium), weight: .bold)
					.foregroundStyle(.brand)

				let maxPowerLabel = Text(chargePoint.maxPowerInKWFormatted)
					.typography(.copy(size: .small))

				let offerEndTimer = TimelineView(.periodic(from: .now, by: 1)) { context in
					OfferEndLabel(
						offer: offer,
						referenceDate: context.date,
						prefix: "Offer ends in ",
						primaryColor: .secondaryContent
					)
					.typography(.copy(size: .small), weight: .bold)
					.multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
				}

				let PriceLayout = dynamicTypeSize.isAccessibilitySize || offer.evseId.count > 15
				? AnyLayout(VStackLayout(alignment: .trailing))
				: AnyLayout(HStackLayout())

				HStack {
					VStack(alignment: .leading, spacing: Size.XXS.size) {
						HStack(alignment: .firstTextBaseline) {
							if dynamicTypeSize.isAccessibilitySize == false {
								evseIdLabel
								Spacer()
							}
							if offer.isDiscounted {
								PriceLayout {
									if let originalPrice = offer.originalPrice?.pricePerKWh {
										Text(originalPrice.formatted() + " / kWh")
											.typography(.copy(size: .small), weight: .regular)
											.foregroundStyle(.secondaryContent)
											.strikethrough()
									}
									priceLabel
								}
							}
						}
						if dynamicTypeSize.isAccessibilitySize {
							evseIdLabel
						}
						AdaptiveHStack(horizontalAlignment: .leading) { isHorizontalStack in
							maxPowerLabel
							if isHorizontalStack, offer.isDiscounted {
								Spacer()
								offerEndTimer
							}
						}
						.frame(maxWidth: .infinity, alignment: .leading)
					}
					if offer.isDiscounted == false {
						priceLabel
					}
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

		// MARK: - Helpers

		private func chargePointGroups(for powerType: PowerType? = nil) -> [ChargePointGroup] {
			guard let offers = offers.data else {
				return []
			}

			return offers.compactMap { offer -> ChargePointGroup? in
				// Filter by selected power type if needed
				let chargePointPowerType = offer.chargePoint.powerType ?? .ac
				if let powerType, chargePointPowerType != powerType {
					return nil
				}

				return ChargePointGroup(offers: [offer], pricePerKWh: offer.price.pricePerKWh)
			}
		}
	}
}

// MARK: - Helpers

private struct ChargePointGroup: Identifiable, Equatable {
	package var id: String {
		"\(pricePerKWh.amount)+\(offers.map(\.evseId))"
	}

	package let offers: [ChargeOffer]
	package let pricePerKWh: Currency
	package let joinedEvseIdString: String

	package init(
		offers: [ChargeOffer],
		pricePerKWh: Currency
	) {
		self.offers = offers
		self.pricePerKWh = pricePerKWh
		joinedEvseIdString = offers.map { $0.evseId }.sorted().joined()
	}
}

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
