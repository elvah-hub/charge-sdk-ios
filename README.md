# elvah Charge SDK

The elvah Charge SDK is a lightweight toolkit that enables apps to discover nearby EV charge offers and initiate charging sessions through a fully native and seamless interface.

With just a few lines of code, you can add a `ChargeBanner` view to your app that intelligently finds and displays nearby charge offers. The SDK handles everything from deal discovery to payment processing and charge session management, allowing your users to charge their cars without ever leaving your app.

## Content

1. [Installation](#installation)
	- [Swift Package Manager](#swift-package-manager)
2. **[Getting Started](#getting-started)**
	- [Charge Banner](#charge-banner)
	- [Charge Session Observation](#charge-session-observation)
3. **[Custom UI Components](#custom-ui-components)**
4. [Compatibility](#compatibility)
5. [Examples](#examples)
6. [Glossary](#glossary)
7. [Support](#support)
8. [License](#license)

## Installation

The SDK supports integration into projects targeting iOS 15 or later and requires Swift 6 for compilation.

> [!NOTE]
> While you can add the SDK to iOS 15 projects, the provided UI components require iOS 16 or later to function. See [Compatibility](#compatibility) for more details.

### Swift Package Manager

Add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/elvah-hub/charge-sdk-ios", from: "0.2.0")
```

Alternatively, if you want to add the package to your Xcode project, go to `File` > `Add Packages...` 
and enter the URL "https://github.com/elvah-hub/charge-sdk-ios" into the search field at the top right. 
The package should appear in the list. Select it, then click "Add Package" in the bottom-right corner.

## Getting Started

To set up the SDK, call `Elvah.initialize(with:)` as early as possible in your app's lifecycle. A good place could be the `AppDelegate` for UIKit apps or the `App`'s initializer for SwiftUI apps.

The configuration allows you to pass the following values:
- `apiKey`: The API key that allows the SDK to connect with elvah's backend.
- `store`: The `UserDefaults` store that the SDK should use to store local data. Defaults to `UserDefaults.standard`.
- `theme`: The theme that should be used in the visual components of the SDK. Defaults to `.default`.

> [!NOTE]
> If you do not have an api key yet or just want to quickly test capabilities, you can initialize the SDK in simulation mode:
>
> ```swift
> Elvah.initialize(with: .simulator)
> ```
>
> It is also possible to configure the behavior of the simulator. See the documentation of `ChargeSimulator` for more information and examples.

### Charge Banner

The SDK's primary entry point is the `ChargeBanner` view. You can add it anywhere you want to offer users a deal to charge their electric car nearby.

The minimal setup to integrate a `ChargeBanner` into your view hierarchy is this:

```swift 
import ElvahCharge

struct DemoView: View {
  @ChargeBannerSource private var chargeBannerSource

  var body: some View {
    VStack {
      // Your other views
            
      if let $chargeBannerSource {
        ChargeBanner(source: $chargeBannerSource)
      }
    }
  }
}
```

A `ChargeBanner` is controlled by a `ChargeBannerSource` that is responsible for fetching and managing charge offer data as well as deciding when to actually display the attached banner.

The banner will initially remain hidden until a source value is set:

```swift
// Load nearest charge offer at a location
chargeBannerSource = .remote(near: coordinate)

// Or load a charge offer in a map region
chargeBannerSource = .remote(in: mapRegion)

// Or load a charge offer from a list of specific evse ids
chargeBannerSource = .remote(evseIds: someEvseIds)
```

Once you have done that, the source object will attempt to find a charge offer from the given source data and present it inside the `ChargeBanner` view.

> [!IMPORTANT]
> Currently, there is only a single demo charge offer available at these coordinates: Latitude: 51.03125° N, Longitude: 4.41047° E

#### Fetch Mode

By default, the `ChargeBanner` will try to fetch all available charge offers from the given source. You can limit that to only fetch offers that are part of an active *campaign*. A campaign is a time period in which charge offers are available with special  conditions, i.e. potentially lower prices.

```swift 
// Default: Fetches all available charge offers
@ChargeBannerSource(fetching: .allOffers) private var chargeBannerSource

// Fetches only charge offers that are part of an active campaign
@ChargeBannerSource(fetching: .campaigns) private var chargeBannerSource
```

#### Display Behavior

By default, there will be visible loading and error states inside the `ChargeBanner` view, whenever a source is set. To change this, specify a `DisplayBehavior` on the `ChargeBannerSource` property wrapper:

```swift 
// Default: Show the banner whenever a source is set, including visible loading and error states
@ChargeBannerSource(display: .whenSourceSet) private var chargeBannerSource

// Show the banner only whenever there is a charge offer loaded, hiding loading and error states
@ChargeBannerSource(display: .whenContentAvailable) private var chargeBannerSource
```

Setting the `DisplayBehavior` to `.whenContentAvailable` can be useful when you do not want to introduce changes to your UI until it is certain there is a charge offer available.

#### Reset Source

To reset the banner and remove it from the view hierarchy, simply set its source to `nil`:

```swift
chargeBannerSource = nil
```

#### External Loading

It is possible to inject a charge site with its offers directly into a banner's source. You can fetch those from the `ChargeSite` object:

```swift
let sites = try await ChargeSite.sites(in: someRegion) 
// Or: ChargeSite.sites(near: someLocation)
// Or: ChargeSite.sites(forEvseIds: evseIds)

if let site = sites.first {
  chargeBannerSource = .direct(site)
}
```

This will disable the internal loading mechanisms and lets you have full control over the presented charge offers.

#### Banner Variants

The `ChargeBanner` view comes in two variants: `large` and `compact`. You can specify the variant through a view modifier:

```swift
ChargeBanner(source: $chargeBannerSource)
  .variant(.compact)
```

### Charge Session Observation

Users should be able to reopen an active charge session that was minimized, whether manually or due to app termination. The `ChargeBanner` view takes care of that out of the box. Whenever there is an active charge session, it will show a button to re-open the charge session.

However, it is usually a good idea to also offer a prominently placed button or banner in your app that users can tap
to re-open an active charge session without having to go back to a place where the `ChargeBanner` is being shown.

You can do this by adding the `.chargeSessionPresentation(isPresented:)` view modifier anywhere in your app. While you can trigger that presentation at any time, it makes sense to do so only when there is an active charge session.

To detect this, you can observe charge session updates using the `ChargeSession.updates()` method. This method returns an `AsyncStream` that yields whenever there are changes to the charge session status. 

```swift
for try await update in ChargeSession.updates() {
  self.showChargeSessionButton = update.isActive
}
```

The `update` you receive from this stream is an `enum` with three cases:

- `inactive`: There is no active charge session
- `active(nil)`:  There is an active charge session but no session data is currently available
- `active(SessionData)`:  There is an active charge session and session data (e.g. consumption, duration) is available.

> [!NOTE] 
> As with all asynchronous APIs in the SDK, there is also a callback-style overload available: `ChargeSession.updates(handler:)`

## Custom UI Components

The SDK provides a set of functions to help you build custom UI elements that interact with the SDK's underlying data structures and APIs. You can use these to make the charging experience feel truly native to your app.

### Charge Offers

The primary interaction between your own components and the SDK happens through the `ChargeOffer` object. A charge offer is made up of information about the specific charge point it belongs to as well as details about the pricing that it includes.

```swift
ChargeOffer.offers(forEvseIds:)
```

> [!NOTE] 
> Any pricing details provided in a `ChargeOffer` object are considered to be a *preview*. Once an offer is passed to the SDK for resolution and charging, it is properly signed and the pricing becomes fixed for a few minutes.

### Charge Site

When you need more context about a site's charge points and their associated offers, or want to access offers at a broader level, use the `ChargeSite` object. It contains both the site information and its related `ChargeOffer` objects.

```swift
// Fetch all charge offers from sites
ChargeSite.sites(in:)  
ChargeSite.sites(near:)  
ChargeSite.sites(forEvseIds:)

// Only fetch charge offers that are part of an active campaign
ChargeSite.campaigns(in:)  
ChargeSite.campaigns(near:)  
ChargeSite.campaigns(forEvseIds:)
```

> [!NOTE] 
> When calling `ChargeSite.sites(forEvseIds:)` or `ChargeSite.campaigns(forEvseIds:)`, the functions will may return multiple `ChargeSite` objects because the provided list of evse ids might not all belong to the same site.

> [!NOTE] 
> The sites returned by a call to `ChargeSite.sites(forEvseIds:)` or `ChargeSite.campaigns(forEvseIds:)` will only contain charge offers for the provided evse ids. If the site has additional charge points, they will be ignored and will not be part of the returned `ChargeSite` object.

### Charge Presentation

The SDK provides several view modifiers to present charging interfaces.

#### Single Offer

When you want to resolve a charge offer and start the payment and charge flow, you can pass the `ChargeOffer` object to the `chargePresentation(offer:)` view modifier. The presented modal view will automatically sign the offer and guide the user through the next steps.

```swift 
import ElvahCharge

struct DemoView: View {
  @State private var selectedChargeOffer: ChargeOffer?

  var body: some View {
    NavigationStack {
      // Your other views
    }
    .chargePresentation(offer: $selectedChargeOffer)
  }
}
```

#### Multiple Offers

To present a selection of charge offers from potentially different sites, use the `chargePresentation(offers:)` modifier with a `ChargeOfferList`. This opens a detail page where users can browse and select from the provided offers.

```swift
import ElvahCharge

struct DemoView: View {
  @State private var chargeOfferList: ChargeOfferList?

  var body: some View {
    NavigationStack {
      // Your other views
    }
    .chargePresentation(offers: $chargeOfferList)
  }
}
```

#### Site Details

To present all charge offers for a specific site with full site context, use the `chargePresentation(site:)` modifier. This provides users with comprehensive site information along with all available charge offers.

```swift
import ElvahCharge

struct DemoView: View {
  @State private var selectedSite: ChargeSite?

  var body: some View {
    NavigationStack {
      // Your other views
    }
    .chargePresentation(site: $selectedSite)
  }
}
```

> [!NOTE]
> All presentation modifiers require iOS 16 or later and will do nothing on earlier versions.

#### Presentation Options

You can configure what is shown in the offer detail presentation using `ChargePresentationOptions`. These options are available on the site and offers presentation modifiers via the `options:` parameter. The default is an empty set, which means nothing is hidden.

- `.hideOperatorDetails`: Hides the operator name and address header.
- `.hideDiscountBanner`: Hides the promotional discount banner above the charge points list. The current-session banner remains visible.

Examples:

```swift
// Hide operator details when presenting a single site
.chargePresentation(site: $selectedSite, options: .hideOperatorDetails)

// Hide both operator details and the discount banner for a list of offers
.chargePresentation(offers: $chargeOfferList, options: [.hideOperatorDetails, .hideDiscountBanner])
```

## Compatibility

You can integrate the SDK into projects that support iOS 15 and above. However, the `ChargeBanner` view requires an iOS 16 (or newer) runtime to function.

On devices running iOS 15, the banner will simply not be displayed. There’s no need to perform runtime checks yourself — the SDK automatically ensures that the banner is only shown when the runtime supports it.

You can safely include `ChargeBannerSource` and `ChargeBanner` in your view hierarchy without additional conditionals. The SDK handles platform availability behind the scenes.

## Examples

Open `ElvahCharge.xcworkspace` at the root of the repository to run the example app. See the [Examples README](./Examples/README.md) for more information.

## Glossary

- **Charge Site**: A place with one or more charge points to charge an electric car at.
- **Charge Point**: A plug used to charge an electric car.
- **Charge Offer**: A charge point with attached pricing information.
- **Campaign**: A period of time with special pricing conditions for a charge point.
- **Charge Session**: An instance of charging an electric car at a charge point.

## Support

For technical support and inquiries, please contact us at tech-support@elvah.de.

## Legal Notice

Please note that the contents of this repository are **not** open source and **must not** be used, modified, or distributed without prior written permission.  
See [LEGAL_NOTICE.md](./LEGAL_NOTICE.md) for full details.
