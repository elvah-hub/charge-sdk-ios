# elvah Charge SDK

The elvah Charge SDK is a lightweight toolkit that enables apps to discover nearby EV charging deals and initiate charge sessions through a fully native and seamless interface.

With just a few lines of code, you can add a `CampaignBanner` view to your app that intelligently finds and displays nearby charging deals. The SDK handles everything from deal discovery to payment processing and charge session management, allowing your users to charge their cars without ever leaving your app.

## Content

1. [Installation](#installation)
	- [Swift Package Manager](#swift-package-manager)
2. **[Getting Started](#getting-started)**
	- [Campaign Banner](#campaign-banner)
3. **[Charge Session Observation](#charge-session-observation)**
4. [Compatibility](#compatibility)
5. [Examples](#examples)
6. [Glossary](#glossary)
7. [Support](#support)
8. [License](#license)

## Installation

The SDK supports integration into projects targeting iOS 15 and above.

You need Swift 6 to compile the SDK.

> [!NOTE]
> While you can add the SDK to iOS 15 projects, the provided UI components require iOS 16 or above to work. See [Compatibility](#compatibility) for more details.

### Swift Package Manager

Add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/elvah-hub/charge-sdk-ios", from: "0.1.0")
```

Alternatively, if you want to add the package to your Xcode project, go to `File` > `Add Packages...` 
and enter the URL "https://github.com/elvah-hub/charge-sdk-ios" into the search field at the top right. 
The package should appear in the list. Select it and click "Add Package" in the bottom right.

## Getting Started

> [!IMPORTANT]
> You will need to request an api key from elvah in order to start using the SDK.

To set up the SDK, call ``Elvah.initialize(with:)`` as early as possible in your app's lifecycle. A good place could be the `AppDelegate` for UIKit apps or the `App`'s initializer for SwiftUI apps.

The configuration allows you to pass the following values:
- `apiKey`: The API key that allows the SDK to connect with elvah's backend.
- `store`: The `UserDefaults` store that the SDK should use to store local data. Defaults to `UserDefaults.standard`.
- `theme`: The theme that should be used in the visual components of the SDK. Defaults to `.neutral`.

### Campaign Banner

The SDK's primary entry point is the `CampaignBanner` view. You can add it anywhere you want to offer users a deal to charge their electric car nearby.

The minimal setup to integrate a `CampaignBanner` into your view hierarchy is this:

```swift 
import ElvahCharge

struct DemoView: View {
  @CampaignSource private var campaignSource

  var body: some View {
    VStack {
      // Your other views
            
      if let $campaignSource {
        CampaignBanner(source: $campaignSource)
      }
    }
  }
}
```

A `CampaignBanner` is controlled by a `CampaignSource` that is responsible for fetching and managing the campaign data as well as deciding when to actually display the attached banner.

The banner will initially remain hidden until a source value is set:

```swift
// Load nearest campaign at a location
campaignSource = .remote(near: coordinate)

// Or load a campaign in a map region
campaignSource = .remote(in: mapRegion)
```

Once you have done that, the source object will attempt to find an active campaign from the given source data and present it inside the `CampaignBanner` view.

> [!IMPORTANT]
> Currently, there is only a single demo campaign available at these coordinates: Latitude: 51.03125° N, Longitude: 4.41047° E

#### Display Behavior

By default, there will be visible loading and error states inside the `CampaignBanner` view, whenever a source is set. To change this, specify a `DisplayBehavior` on the `CampaignSource` property wrapper:

```swift 
// Default: Show the banner whenever a source is set, including visible loading and error states
@CampaignSource(display: .whenSourceSet) private var campaignSource

// Show the banner only whenever there is an active campaign loaded, hiding loading and error states
@CampaignSource(display: .whenContentAvailable) private var campaignSource
```

Setting the `DisplayBehavior` to `.whenContentAvailable` can be useful when you do not want to introduce changes to your UI until it is certain there is an active campaign available.

#### Reset Source

To reset the banner and remove it from the view hierarchy, simply set its source to `nil`:

```swift
campaignSource = nil
```

#### External Loading

It is possible to inject a campaign directly into a banner's source. You can fetch campaigns from the `Campaign` object:

```swift
let campaigns = try await Campaign.campaigns(in: someRegion) 
// Or: Campaign.campaigns(near: someLocation)

if let campaign = campaigns.first {
  campaignSource = .direct(campaign)
}
```

This will disable the internal loading mechanisms and lets you have full control over the presented campaign.

#### Banner Variants

The `CampaignBanner` view comes in two variants: `large` and `compact`. You can specify the variant through a view modifier:

```swift
CampaignBanner(source: $campaignSource)
  .variant(.compact)
```

#### Campaign Ended Notification

You can add a view modifier that will call a given closure whenever a loaded campaign has ended and needs to be replaced:

```swift
CampaignBanner(source: $campaignSource)
  .onCampaignEnd { expiredCampaign in 
    // Perform some logic
  }
```

> [!NOTE] 
> Typically, you do not need to worry about this, but in case you need the extra control, it is available.

## Charge Session Observation
Users should be able to reopen an active charge session that was minimized, whether manually or due to app termination. The `CampaignBanner` view takes care of that out of the box. Whenever there is an active charge session, the banner will show a button to re-open the charge session.

However, it is usually a good idea to also offer a prominently placed button or banner in your app that the user can tap
to re-open an active charge session without having to go back to a place where the `CampaignBanner` is being shown.

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

## Compatibility

You can integrate the SDK into projects that support iOS 15 and above. However, the `CampaignBanner` view requires an iOS 16 (or newer) runtime to function.

On devices running iOS 15, the banner will simply not be displayed. There’s no need to perform runtime checks yourself — the SDK automatically ensures that the banner is only shown when the runtime supports it.

You can safely include `CampaignSource` and `CampaignBanner` in your view hierarchy without additional conditionals. The SDK handles platform availability behind the scenes.

## Examples

You can find an example project in the `Examples` directory of this repository.

## Glossary
- **Site**: A place with one or more charge points to charge an electric car at.
- **Charge Point**: A plug used to charge an electric car.
- **Deal**: A charge point with attached pricing information and a signed agreement to charge under those conditions.
- **Campaign**: A site with a list of deals attached to it.
- **Charge Session**: An instance of charging an electric car at a charge point.

## Support

For technical support and inquiries, please contact us at tech-support@elvah.de.

## Legal Notice

Please note that the contents of this repository are **not** open source and **must not** be used, modified, or distributed without prior written permission.  
See [LEGAL_NOTICE.md](./LEGAL_NOTICE.md) for full details.
