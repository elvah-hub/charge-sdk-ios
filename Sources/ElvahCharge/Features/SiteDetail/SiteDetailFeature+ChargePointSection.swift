// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
extension SiteDetailFeature {
	struct ChargePointSection: View {
		typealias Action = (_ deal: Deal) -> Void

		@Environment(\.dynamicTypeSize) private var dynamicTypeSize
		@Default(.chargeSessionContext) private var chargeSessionContext
		@State private var selectedPowerType: PowerType
		@Binding private var dealsSectionOrigin: CGPoint
		private var deals: LoadableState<[Deal]>
		private var processingDeal: Deal?
		private var dealAction: Action
		private var chargeSessionAction: () -> Void

		init(
			initialPowerTypeSelection: PowerType? = nil,
			deals: LoadableState<[Deal]>,
			dealsSectionOrigin: Binding<CGPoint>,
			processingDeal: Deal?,
			dealAction: @escaping Action,
			chargeSessionAction: @escaping () -> Void
		) {
			self.deals = deals
			_dealsSectionOrigin = dealsSectionOrigin
			self.processingDeal = processingDeal
			self.dealAction = dealAction
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
				switch deals {
				case .absent,
				     .loading,
				     .error:
					activityContent
				case let .loaded(deals):
					dealBanner(for: deals)
					chargePointList(for: deals)
				}
			}
			.animation(.default, value: selectedPowerType)
			.animation(.default, value: deals)
			.frame(maxWidth: .infinity, alignment: .leading)
		}

		@ViewBuilder private func dealBanner(for deals: [Deal]) -> some View {
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

		@ViewBuilder private func chargePointList(for deals: [Deal]) -> some View {
			VStack(alignment: .leading, spacing: 24) {
				TimelineView(.periodic(from: .now, by: 1)) { _ in
					let hasMultiplePowerTypes = deals
						.compactMap(\.chargePoint.powerType)
						.unique()
						.count > 1
					let groups = chargePointGroups(for: hasMultiplePowerTypes ? selectedPowerType : nil)

					VStack(spacing: 0) {
						if hasMultiplePowerTypes {
							PowerTypeSelector(selection: $selectedPowerType)
						}
						ForEach(groups) { group in
							ForEach(group.deals) { deal in
								chargePointButton(for: deal)
									.overlay {
										loadingOverlay(show: processingDeal?.id == deal.id)
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
					.animation(.bouncy, value: processingDeal)
				}
			}
			.overlay(alignment: .top) {
				Color.clear.frame(height: 0)
					.scrollPositionReader($dealsSectionOrigin, in: "ScrollView")
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

		@ViewBuilder private func chargePointButton(for deal: Deal) -> some View {
			let chargePoint = deal.chargePoint
			Button {
				dealAction(deal)
			} label: {
				let evseIdLabel = Text(chargePoint.evseId)
					.typography(.copy(size: .medium), weight: .bold)

				let priceLabel = Text(deal.pricePerKWh.formatted() + " / kWh")
					.typography(.copy(size: .medium), weight: .bold)
					.foregroundStyle(.brand)

				let maxPowerLabel = Text("\(chargePoint.maxPowerInKwFormatted)kW", bundle: .elvahCharge)
					.typography(.copy(size: .small))

				let dealEndTimer = TimelineView(.periodic(from: .now, by: 1)) { context in
					DealEndLabel(
						deal: deal,
						referenceDate: context.date,
						prefix: "Offer ends in ",
						primaryColor: .secondaryContent
					)
					.typography(.copy(size: .small), weight: .bold)
					.multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
				}

				VStack(alignment: .leading, spacing: Size.XXS.size) {
					HStack(alignment: .firstTextBaseline) {
						if dynamicTypeSize.isAccessibilitySize == false {
							evseIdLabel
						}
						Spacer()
						priceLabel
					}
					if dynamicTypeSize.isAccessibilitySize {
						evseIdLabel
					}
					AdaptiveHStack(horizontalAlignment: .leading) { isHorizontalStack in
						maxPowerLabel
						if isHorizontalStack {
							Spacer()
						}
						dealEndTimer
					}
					.frame(maxWidth: .infinity, alignment: .leading)
				}
				.withChevron()
				.padding(.M)
			}
			.opacity(deal.hasEnded || chargeSessionContext != nil ? 0.5 : 1)
			.disabled(deal.hasEnded || chargeSessionContext != nil)
			.animation(.default, value: deal.hasEnded)
		}

		@ViewBuilder private var activityContent: some View {
			var title: LocalizedStringKey? {
				if deals.isError {
					return "An error occurred"
				}
				return "Loading chargepoints"
			}

			var message: LocalizedStringKey? {
				if deals.isError {
					return "The charge points could not be loaded. Please try again later."
				}
				return nil
			}

			var state: ActivityInfoComponent.ActivityState {
				if deals.isError {
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
			guard let deals = deals.data else {
				return []
			}

			return deals.compactMap { deal -> ChargePointGroup? in
				// Filter by selected power type if needed
				let chargePointPowerType = deal.chargePoint.powerType ?? .ac
				if let powerType, chargePointPowerType != powerType {
					return nil
				}

				return ChargePointGroup(deals: [deal], pricePerKWh: deal.pricePerKWh)
			}
		}
	}
}

// MARK: - Helpers

private struct ChargePointGroup: Identifiable, Equatable {
	package var id: String {
		"\(pricePerKWh.amount)+\(deals.map(\.evseId))"
	}

	package let deals: [Deal]
	package let pricePerKWh: Currency
	package let joinedEvseIdString: String

	package init(
		deals: [Deal],
		pricePerKWh: Currency
	) {
		self.deals = deals
		self.pricePerKWh = pricePerKWh
		joinedEvseIdString = deals.map { $0.evseId }.sorted().joined()
	}
}

@available(iOS 16.0, *)
private struct AvailabilityPill: View {
	var chargePoint: ChargePointDetails

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
					SiteDetailFeature.ChargePointSection(
						deals: .loaded([.mockAvailable, .mockUnavailable, .mockOutOfService]),
						dealsSectionOrigin: .constant(.zero),
						processingDeal: .mockAvailable
					) { _ in } chargeSessionAction: {}
				}
			}
		}
	}
	.withFontRegistration()
	.withMockEnvironmentObjects()
	.preferredColorScheme(.dark)
}
