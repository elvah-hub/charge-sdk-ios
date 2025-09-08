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
		private var largestCommonPrefix: String
		private var offers: LoadableState<[ChargeOffer]>
		private var processingOffer: ChargeOffer?
		private var offerAction: Action
		private var chargeSessionAction: () -> Void

		init(
			offers: LoadableState<[ChargeOffer]>,
			processingOffer: ChargeOffer?,
			offerAction: @escaping Action,
			chargeSessionAction: @escaping () -> Void
		) {
			self.offers = offers
			self.processingOffer = processingOffer
			self.offerAction = offerAction
			self.chargeSessionAction = chargeSessionAction
			largestCommonPrefix = offers.data?.largestCommonEvseIdPrefix ?? ""
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
			VStack(alignment: .leading, spacing: 24) {
				TimelineView(.periodic(from: .now, by: 1)) { _ in
					VStack(spacing: 0) {
						ForEach(offers) { offer in
							chargePointButton(for: offer)
								.overlay {
									loadingOverlay(show: processingOffer?.id == offer.id)
								}
							Divider()
								.padding(.leading, .M)
						}
					}
					.buttonStyle(ChargePointButtonStyle())
					.foregroundStyle(.primaryContent)
					.animation(.bouncy, value: processingOffer)
				}
			}
			.frame(maxWidth: .infinity)
		}

		@ViewBuilder private func loadingOverlay(show: Bool) -> some View {
			ZStack(alignment: .trailing) {
				if show {
					LinearGradient(
						stops: [
							Gradient.Stop(color: .canvas, location: 0),
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
				// Determine the label for the charge point identifier
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
					.foregroundStyle(.onSuccess)
					.padding(.horizontal, .XS)
					.padding(.vertical, .XXS)
					.background(
						RoundedRectangle(cornerRadius: 4)
							.fill(Color.success)
					)

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
					// Row 1: EVSE badge on the left, price on the right
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
