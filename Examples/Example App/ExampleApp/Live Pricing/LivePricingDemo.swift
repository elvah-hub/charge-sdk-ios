// Copyright © elvah. All rights reserved.

import ElvahCharge
import SwiftUI

/// Demonstrates integrating `LivePricingView` with a loaded `ChargeSiteSchedule`.
struct LivePricingDemo: View {
	@State private var schedule: ChargeSiteSchedule?
	@State private var isLoading = false
	@State private var error: Error?

	var body: some View {
		DemoContent {
			VStack(spacing: 15) {
				Button("Load Live Pricing") {
					Task { await loadSchedule() }
				}
				.disabled(isLoading)

				if isLoading {
					ProgressView("Loading schedule...")
						.padding()
				} else if let error {
					ErrorView(error: error)
				} else if let schedule {
					LivePricingView(schedule: schedule)
				}
			}
			.animation(.default, value: isLoading)
			.animation(.default, value: schedule)
		}
		.navigationTitle("Live Pricing")
		.navigationBarTitleDisplayMode(.inline)
	}

	@MainActor private func loadSchedule() async {
		isLoading = true
		error = nil

		do {
			// Prefer a site with an active campaign in simulation
			if let site = try await ChargeSite.campaigns(in: .mock).first {
				schedule = try await ChargeSiteSchedule.schedule(for: site)
			} else if let site = try await ChargeSite.sites(in: .mock).first {
				schedule = try await ChargeSiteSchedule.schedule(for: site)
			} else {
				error = NSError(domain: "LivePricingDemo", code: -1, userInfo: [NSLocalizedDescriptionKey: "No site available in simulation."])
			}

			isLoading = false
		} catch {
			self.error = error
			isLoading = false
		}
	}
}

#Preview {
	NavigationStack {
		LivePricingDemo()
			.preferredColorScheme(.dark)
	}
}
