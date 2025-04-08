// Copyright © elvah. All rights reserved.

import SwiftUI

/// A view that shows promotional charging deals near a given location or inside a map region.
///
/// To show a ``CampaignBanner`` view, you need an instance of a ``CampaignSource``, which is a
/// property wrapper that you can add to any SwiftUI view. A campaign source is responsible for
/// controlling how and when the data for a ``CampaignBanner`` view is loaded. Its projected value
/// (`$`-prefixed property) gives you an optional binding that you can conditionally unwrap and
/// initialize the ``CampaignBanner`` with. The binding will provide the banner with all required
/// information and will trigger internal state updates as needed. Furthermore, a setup like this
/// allows the ``CampaignBanner`` view to control its own presentation in the view hierarchy.
///
/// ```swift
/// struct Demo: View {
/// 	@CampaignSource private var campaignSource
///
/// 	var body: some View {
/// 		// ... Your view content
///
/// 		if let $campaignSource {
/// 			CampaignBanner(source: $campaignSource)
/// 		}
/// 	}
/// }
/// ```
///
/// ## Load a Campaign
///
/// When you want to load a campaign, you set your campaign source to a location or map
/// region:
///
/// ```swift
/// campaignSource = .remote(near: myLocation) // CLLocationCoordinate2D
/// // Or
/// campaignSource = .remote(in: someRegion) // MKMapRect
/// ```
///
/// This will cause the ``CampaignBanner`` to automatically fetch and show an appropriate
/// campaign. Once that campaign expires, the component will attempt to load another campaign from
/// the source and show it. If that fails, the ``CampaignBanner`` will either show a "no deals
/// found" message or remove itself from the view hierarchy, depending on the specified display
/// behavior in the source object.
///
/// ```swift
/// // Hide banner when no campaign is available
/// @CampaignSource(display: .whenContentAvailable) private var campaignSource
/// ```
///
/// ## Reset Banner
///
/// To reset the banner, set its source to `nil`:
///
/// ```swift
/// campaignSource = nil
/// ```
///
/// ## Animation
///
/// To animate the presentation and internal state changes of a ``CampaignBanner`` view, you can
/// pass the campaign source to an `.animation` view modifier like this:
///
/// ```swift
/// .animation(.default, value: campaignSource)
/// ```
///
/// ## Button Configuration
/// ### Variant
///
/// You can configure the button's size via its ``CampaignBanner/variant(_:)`` modifier:
///
/// ```swift
/// CampaignBanner(source: $campaignSource)
/// 	.variant(.compact) // Defaults to .large
/// ```
///
/// ## Full Example
///
/// ```swift
/// struct Demo: View {
/// 	@CampaignSource private var campaignSource
/// 	var body: some View {
/// 		ScrollView {
/// 			VStack {
/// 				Button("Deals Nearby") {
/// 					let myLocation = /* ... */
/// 					campaignSource = .remote(near: myLocation)
/// 				}
/// 				if let $campaignSource {
/// 					CampaignBanner(source: $campaignSource)
/// 				}
/// 			}
/// 			.padding()
/// 			.frame(maxWidth: .infinity)
/// 			.animation(.default, value: campaignSource)
/// 		}
/// 	}
/// }
/// ```
public struct CampaignBanner: View {
	public typealias CampaignEndedBlock = @MainActor (_ expiredCampaign: Campaign) -> Void

	@StateObject private var router = CampaignBanner.Router()
	private var variant = CampaignBannerVariant.large
	private var source: CampaignSource.Binding
	private var onCampaignEnd: CampaignEndedBlock?
	private var action: CampaignBannerActionResolution

	/// Initializes the ``CampaignBanner`` view.
	/// - Parameter source: The source that drive the campaign loading for the view.
	public init(source: CampaignSource.Binding) {
		self.source = source
		action = .automatic
	}

	/// Initializes the ``CampaignBanner`` view.
	/// - Parameter source: The source that drive the campaign loading for the view.
	/// - Parameter action: A closure that is called when the primary action of the view is tapped.
	/// You can use this to perform your own logic before triggering a presentation.
	public init(
		source: CampaignSource.Binding,
		action: @MainActor @escaping (_ destination: CampaignBannerActionDestination) -> Void
	) {
		self.source = source
		self.action = .custom(action)
	}

	public var body: some View {
		if #available(iOS 16.0, *) {
			CampaignBannerComponent(
				source: source,
				variant: variant,
				onCampaignEnd: onCampaignEnd
			) { destination in
				switch (action, destination) {
				case let (.automatic, .campaignDetailPresentation(campaign)):
					router.campaignDetail = campaign
				case (.automatic, .chargeSessionPresentation):
					router.showChargeSession = true
				case let (.custom(handler), _):
					handler(destination)
				}
			}
			.fullScreenCover(item: $router.campaignDetail) { capaign in
				SiteDetailWrapperFeature(site: capaign.site, deals: capaign.deals)
			}
			.fullScreenCover(isPresented: $router.showChargeSession) {
				ChargeEntryFeature()
			}
			.withEnvironmentObjects()
		} else {
			EmptyView()
		}
	}

	// MARK: - View Modifier

	/// Returns a ``CampaignBanner`` with the configured variant.
	/// - Parameter variant: The variant to use.
	/// - Returns: A ``CampaignBanner`` with the configured variant.
	public func variant(_ variant: CampaignBannerVariant) -> CampaignBanner {
		var copy = self
		copy.variant = variant
		return copy
	}

	/// Returns a ``CampaignBanner`` with a closure that will be called whenever a campaign has
	/// ended.
	/// - Parameter block: A closure that is called when the campaign ends.
	/// - Returns: A ``CampaignBanner`` with the configured campaign end closure.
	public func onCampaignEnd(
		perform block: @MainActor @escaping (_ expiredCampaign: Campaign) -> Void
	) -> CampaignBanner {
		var copy = self
		copy.onCampaignEnd = block
		return copy
	}
}

package extension CampaignBanner {
	@MainActor
	final class Router: BaseRouter {
		@Published var campaignDetail: Campaign?
		@Published var showChargeSession = false

		package func reset() {
			campaignDetail = nil
			showChargeSession = false
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @CampaignSource var campaignSource = .direct(.mock)
	ZStack {
		if let $campaignSource {
			CampaignBanner(source: $campaignSource)
				.padding()
		}
	}
	.preferredColorScheme(.dark)
}
