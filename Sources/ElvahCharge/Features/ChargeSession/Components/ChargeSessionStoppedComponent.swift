// Copyright © elvah. All rights reserved.

import SwiftUI

#if canImport(Defaults)
	import Defaults
#endif

@available(iOS 16.0, *)
struct ChargeSessionStoppedComponent: View {
	@EnvironmentObject private var chargeSettlementProvider: ChargeSettlementProvider
	@Environment(\.dynamicTypeSize) private var dynamicTypeSize
	@Default(.chargeSessionContext) private var chargeSessionContext

	@TaskIdentifier private var paymentSummaryTaskId
	@Loadable<PaymentSummary> private var paymentSummary

	var session: ChargeSession
	var site: Site
	var offer: ChargeOffer

	var body: some View {
		if #available(iOS 16.4, *) {
			content
				.scrollBounceBehavior(.basedOnSize)
		} else {
			content
		}
	}

	@ViewBuilder private var content: some View {
		ScrollView {
			VStack(spacing: Size.XL.size) {
				CPOLogo(url: chargeSessionContext?.organisationDetails.logoUrl)
				ActivityInfoComponent(state: .success, title: nil, message: nil)
				CustomSectionStack {
					if let operatorName = site.operatorName, let address = site.address {
						siteInformation(title: operatorName, address: address)
					}

					if let paymentSummary = paymentSummary.data {
						paymentSummarySection(paymentSummary: paymentSummary)
					} else {
						paymentSummaryLoadingSection
					}
				}
				.padding(.horizontal, .M)
			}
			.foregroundStyle(.primaryContent)
			.animation(.default, value: paymentSummary)
			.task(id: paymentSummaryTaskId) {
				await reloadPaymentSummary()
			}
		}
	}

	@ViewBuilder private func siteInformation(title: String, address: Site.Address) -> some View {
		CustomSection {
			VStack(alignment: .leading, spacing: Size.XXS.size) {
				Text(title)
					.typography(.title(size: .small), weight: .bold)
				Text(address.formatted())
					.typography(.copy(size: .medium))
					.foregroundStyle(.secondaryContent)
			}
			AdaptiveHStack { isHorizontalStack in
				Text("EVSE ID:", bundle: .elvahCharge)
				if isHorizontalStack {
					Spacer()
				}
				Text(offer.chargePoint.evseId)
			}
			.typography(.copy(size: .medium))
		}
	}

	@ViewBuilder private var paymentSummaryLoadingSection: some View {
		CustomSection {
			VStack(alignment: .trailing, spacing: Size.XS.size) {
				AdaptiveHStack { isHorizontalStack in
					Text("Payment Summary", bundle: .elvahCharge)
						.foregroundStyle(.secondaryContent)
						.typography(.copy(size: .small))
					if isHorizontalStack {
						Spacer()
					}
					if paymentSummary.isError {
						Text("Cannot fetch summary")
							.foregroundStyle(.red)
							.typography(.copy(size: .small))
					} else {
						ProgressView()
							.progressViewStyle(.inlineActivity)
					}
				}
			}
		}
	}

	@ViewBuilder private func paymentSummarySection(paymentSummary: PaymentSummary) -> some View {
		let startedAt = paymentSummary.sessionStartedAt
		let endedAt = paymentSummary.sessionEndedAt
		let duration = Duration.seconds(endedAt.timeIntervalSince(startedAt))
		CustomSectionStack(
			axis: dynamicTypeSize.isAccessibilitySize ? .vertical : .horizontal
		) {
			chargeAmountSection(consumedKWh: paymentSummary.consumedKWh)
			chargeDurationSection(duration: duration)
		}
		.fixedSize(horizontal: false, vertical: true)
		totalCostSection(totalCost: paymentSummary.totalCost)
	}

	@ViewBuilder private func chargeAmountSection(consumedKWh: KilowattHours) -> some View {
		CustomSection {
			VStack(alignment: .leading, spacing: Size.XS.size) {
				Text("kWh charged", bundle: .elvahCharge)
					.foregroundStyle(.secondaryContent)
					.typography(.copy(size: .small))
				Text(consumedKWh.formattedWithFraction(includeUnit: false))
					.typography(.title(size: .medium), weight: .bold)
			}
			.frame(maxHeight: .infinity, alignment: .top)
		}
	}

	@ViewBuilder private func chargeDurationSection(duration: Duration) -> some View {
		CustomSection {
			VStack(alignment: .leading, spacing: Size.XS.size) {
				Text("Charging duration", bundle: .elvahCharge)
					.foregroundStyle(.secondaryContent)
					.typography(.copy(size: .small))
				Text(duration.formatted(.units(maximumUnitCount: 2)))
					.typography(.title(size: .medium), weight: .bold)
			}
			.frame(maxHeight: .infinity, alignment: .top)
		}
	}

	@ViewBuilder private func totalCostSection(totalCost: Currency) -> some View {
		CustomSection {
			VStack(alignment: .trailing, spacing: Size.XS.size) {
				AdaptiveHStack { isHorizontalStack in
					Text("Total", bundle: .elvahCharge)
						.foregroundStyle(.secondaryContent)
						.typography(.copy(size: .small))
					if isHorizontalStack {
						Spacer()
					}
					Text(totalCost.formatted())
						.typography(.copy(size: .large), weight: .bold)
				}
			}
		}
	}

	// MARK: - Actions

	private func reloadPaymentSummary() async {
		guard let context = chargeSessionContext else {
			paymentSummary.setError(NetworkError.unknown)
			return
		}

		await $paymentSummary.load {
			while Task.isCancelled == false {
				do {
					let paymentSummary = try await chargeSettlementProvider
						.summary(paymentId: context.paymentId)

					if let paymentSummary {
						return paymentSummary
					}
				} catch {
					Elvah.logger.error(
						"""
						Cannot fetch payment summary:  \(error.localizedDescription). \
						Trying again in 2 seconds.
						"""
					)
				}

				// Sleep and try again
				try await Task.sleep(for: .seconds(2))
			}

			throw NetworkError.unknown
		}
	}

	// MARK: - Helpers

	private var timerString: String {
		return Duration.seconds(session.duration).formatted(.units())
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @State var session: ChargeSession = .mock(status: .charging)
	ZStack {
		Color.canvas.ignoresSafeArea()
		ChargeSessionStoppedComponent(
			session: session,
			site: .mock,
			offer: .mockAvailable
		)
	}
	.preferredColorScheme(.dark)
	.withFontRegistration()
	.withMockEnvironmentObjects()
}
