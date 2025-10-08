// Copyright © elvah. All rights reserved.

import SwiftUI

/// A view that shows promotional charging deals near a given location or inside a map region.
///
/// To show a ``ChargeBanner`` view, you need an instance of a ``ChargeBannerSource``, which is a
/// property wrapper that you can add to any SwiftUI view. A source is responsible for
/// controlling how and when the data for a ``ChargeBanner`` view is loaded. Its projected value
/// (`$`-prefixed property) gives you an optional binding that you can conditionally unwrap and
/// initialize the ``ChargeBanner`` with. The binding will provide the banner with all required
/// information and will trigger internal state updates as needed. Furthermore, a setup like this
/// allows the ``ChargeBanner`` view to control its own presentation in the view hierarchy.
///
/// ```swift
/// struct Demo: View {
/// 	@ChargeBannerSource private var chargeBannerSource
///
/// 	var body: some View {
/// 		// ... Your view content
///
/// 		if let $chargeBannerSource {
/// 			ChargeBanner(source: $chargeBannerSource)
/// 		}
/// 	}
/// }
/// ```
///
/// ## Load Charge Offers
///
/// When you want to load charge offers, you set your source to a location or map
/// region:
///
/// ```swift
/// chargeBannerSource = .remote(near: myLocation) // CLLocationCoordinate2D
/// // Or
/// chargeBannerSource = .remote(in: someRegion) // MKMapRect
/// ```
///
/// Alternatively, you can also pass in a specific set of evse ids:
///
/// ```swift
/// chargeBannerSource = .remote(evseIds: someEvseIds) // [String]
/// ```
///
/// This will cause the ``ChargeBanner`` to automatically fetch and show an appropriate
/// charge offer. If that offer ends, the component will attempt to load another offer from
/// the source and show it. If that fails, the ``ChargeBanner`` will either show a "no offers
/// found" message or remove itself from the view hierarchy, depending on the specified display
/// behavior in the source object.
///
/// ```swift
/// // Hide banner when no offer is available
/// @ChargeBannerSource(display: .whenContentAvailable) private var chargeBannerSource
/// ```
///
/// ## Load Campaigns
///
/// When you want to display charge offers that are part of a campaign, with discounted pricing, you can configure your source to only fetch those:
///
/// ```swift
/// // Hide banner when no offer is available
/// @ChargeBannerSource(fetching: .campaigns) private var chargeBannerSource
/// ```
///
/// ## Reset Banner
///
/// To reset the banner, set its source to `nil`:
///
/// ```swift
/// chargeBannerSource = nil
/// ```
///
/// ## Animation
///
/// To animate the presentation and internal state changes of a ``ChargeBanner`` view, you can
/// pass the source to an `.animation` view modifier like this:
///
/// ```swift
/// .animation(.default, value: chargeBannerSource)
/// ```
///
/// ## Button Configuration
/// ### Variant
///
/// You can configure the button's size via its ``ChargeBanner/variant(_:)`` modifier:
///
/// ```swift
/// ChargeBanner(source: $chargeBannerSource)
/// 	.variant(.compact) // Defaults to .large
/// ```
///
/// ## Full Example
///
/// ```swift
/// struct Demo: View {
/// 	@ChargeBannerSource private var chargeBannerSource
/// 	var body: some View {
/// 		ScrollView {
/// 			VStack {
/// 				Button("Offers Nearby") {
/// 					let myLocation = /* ... */
/// 					chargeBannerSource = .remote(near: myLocation)
/// 				}
/// 				if let $chargeBannerSource {
/// 					ChargeBanner(source: $chargeBannerSource)
/// 				}
/// 			}
/// 			.padding()
/// 			.frame(maxWidth: .infinity)
/// 			.animation(.default, value: chargeBannerSource)
/// 		}
/// 	}
/// }
/// ```
public struct ChargeBanner: View {
  @StateObject private var router = ChargeBanner.Router()
  private var variant = ChargeBannerVariant.large
  private var source: ChargeBannerSource.Binding
  private var action: ChargeBannerActionResolution

  /// Initializes the ``ChargeBanner`` view.
  /// - Parameter source: The source that drives the charge offer loading for the view.
  public init(source: ChargeBannerSource.Binding) {
    self.source = source
    action = .automatic
  }

  /// Initializes the ``ChargeBanner`` view.
  /// - Parameter source: The source that drives the charge offer loading for the view.
  /// - Parameter action: A closure that is called when the primary action of the view is tapped.
  /// You can use this to perform your own logic before triggering a presentation.
  public init(
    source: ChargeBannerSource.Binding,
    action: @MainActor @escaping (_ destination: ChargeBannerActionDestination) -> Void,
  ) {
    self.source = source
    self.action = .custom(action)
  }

  public var body: some View {
    if #available(iOS 16.0, *) {
      ChargeBannerComponent(source: source, variant: variant) { destination in
        switch (action, destination) {
        case let (.automatic, .chargeSitePresentation(chargeSite)):
          router.chargeSiteDetail = chargeSite
        case (.automatic, .chargeSessionPresentation):
          router.showChargeSession = true
        case let (.custom(handler), _):
          handler(destination)
        }
      }
      .fullScreenCover(item: $router.chargeSiteDetail) { chargeSite in
        ChargeOfferDetailRootFeature(site: chargeSite.site, offers: chargeSite.offers)
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

  /// Returns a ``ChargeBanner`` with the configured variant.
  /// - Parameter variant: The variant to use.
  /// - Returns: A ``ChargeBanner`` with the configured variant.
  public func variant(_ variant: ChargeBannerVariant) -> ChargeBanner {
    var copy = self
    copy.variant = variant
    return copy
  }
}

package extension ChargeBanner {
  final class Router: BaseRouter {
    @Published var chargeSiteDetail: ChargeSite?
    @Published var showChargeSession = false

    package func reset() {
      chargeSiteDetail = nil
      showChargeSession = false
    }
  }
}

@available(iOS 17.0, *)
#Preview {
  @Previewable @ChargeBannerSource var chargeBannerSource = .direct(.mock)
  ZStack {
    if let $chargeBannerSource {
      ChargeBanner(source: $chargeBannerSource)
        .padding()
    }
  }
  .withFontRegistration()
  .preferredColorScheme(.dark)
}
