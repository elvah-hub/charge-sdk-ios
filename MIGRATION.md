# Migration Guide

## [0.3.0]

The 0.3.0 release contais no breaking changes. No migration is needed.

## [0.2.0]

The 0.2.0 release introduces several significant API changes, primarily focused on renaming components to better reflect their functionality and introducing a more consistent domain model.

### Breaking Changes

#### CampaignBanner → ChargeBanner

The banner component has been renamed from `CampaignBanner` to `ChargeBanner`.

**Before (0.1.0):**
```swift
import ElvahCharge

struct MyView: View {
    @CampaignSource private var campaignSource
    
    var body: some View {
        VStack {
            if let $campaignSource {
                CampaignBanner(source: $campaignSource)
                    .variant(.compact)
            }
        }
    }
}
```

**After (0.2.0):**
```swift
import ElvahCharge

struct MyView: View {
    @ChargeBannerSource private var chargeBannerSource
    
    var body: some View {
        VStack {
            if let $chargeBannerSource {
                ChargeBanner(source: $chargeBannerSource)
                    .variant(.compact)
            }
        }
    }
}
```

#### CampaignSource → ChargeBannerSource

The property wrapper has been renamed from `CampaignSource` to `ChargeBannerSource`.

**Before (0.1.0):**
```swift
@CampaignSource private var campaignSource
@CampaignSource(display: .whenContentAvailable) private var campaignSource
```

**After (0.2.0):**
```swift
@ChargeBannerSource private var chargeBannerSource  
@ChargeBannerSource(display: .whenContentAvailable) private var chargeBannerSource
```

#### Campaign → ChargeSite Domain Model

The core domain model has shifted from `Campaign` to `ChargeSite`:

**Before (0.1.0):**
```swift
// Loading campaigns
let campaigns = try await Campaign.campaigns(in: region)
let campaigns = try await Campaign.campaigns(near: location)

// Direct usage
campaignSource = .direct(campaign)
```

**After (0.2.0):**
```swift  
// Loading charge sites
let chargeSites = try await ChargeSite.sites(in: region)
let chargeSites = try await ChargeSite.sites(near: location)

// Direct usage
chargeBannerSource = .direct(chargeSite)
```

#### Presentation Modifiers

View modifiers for presenting detail screens have been updated:

**Before (0.1.0):**
```swift
.campaignDetailPresentation(for: $campaign)
```

**After (0.2.0):**
```swift
.chargePresentation(site: $site)
```

#### Callback Changes

The callback signature for charge banner actions has been updated:

**Before (0.1.0):**
```swift
CampaignBanner(source: $campaignSource) { destination in
    switch destination {
    case .campaignDetailPresentation(let campaign):
        // Handle campaign detail
    case .chargeSessionPresentation:
        // Handle charge session
    }
}
```

**After (0.2.0):**
```swift
ChargeBanner(source: $chargeBannerSource) { destination in
    switch destination {
    case .chargeSitePresentation(let chargeSite):
        // Handle charge site detail  
    case .chargeSessionPresentation:
        // Handle charge session
    }
}
```
