# Changelog

All notable changes to this project will be documented in this file.

## [0.4.0]

### Bug Fixes
- Fixed a bug where charge points in the charge offer detail screen would not be tappable when no charge site was provided

## [0.3.0]

### Additions
- Added preliminary support for French and German in the SDK

### Bug Fixes
- Fixed crash that could occur if the backend sends incorrect coordinate values
- Fixed warning log message appearing erroneously in simulation mode

## [0.2.0]

### Major Changes

**Charge Anywhere**
- Replaced the concept of campaigns and deals with charge sites and charge offers
	- A campaign is now just a special type of charge offer

**New Entry Points**
- Added view modifier to start the payment and charge flow for a specific charge offer:

  ```swift
  .chargePresentation(offer: myChargeOffer)
  ```
- Added view modifier to display a list of charge offers:

  ```swift
  .chargePresentation(offers: myChargeOfferList)
  ```
- Added view modifier to display a charge site with all its offers:

  ```swift
  .chargePresentation(site: myChargeSite)
  ```

**Simulation Mode**
- Added simulation mode to the SDK

  ```swift
  // No api key needed
  Elvah.initialize(with: .simulator)
  ```
- Added support for customizing the behavior of the simulator 
	- See `ChargeSimulator` for detailed instructions and examples

**Support for Custom Fonts**
- Added support for passing a custom font to `Theme.Typography`

**Breaking API Changes**
- This release changes a lot of the public API. See [MIGRATION.md](MIGRATION.md) for detailed migration instructions from version 0.1.0.

### Additions
- Added font property to `Theme.Typography` to support passing in custom fonts
- Added migration guide: [MIGRATION.md](MIGRATION.md)
- Added simulation mode via `Elvah.initialize(with: .simulator)`
- Added `ChargeSite.sites(in:)`, `ChargeSite.sites(near:)` and `ChargeSite.sites(forEvseIds:)`
- Added `ChargeSite.campaigns(forEvseIds:)`
- Added `ChargeSimulator` for deep customization of the simulation mode
- Added `.chargePresentation(offer:)`
- Added `.chargePresentation(offers:)`
- Added `.chargePresentation(site:)`
- Added `fetching` parameter to `ChargeBannerSource` to specify the type of offers to fetch

### Changes
- Removed `.campaignDetailPresentation(for:)`; Use `.chargePresentation(site:)` instead
- Renamed concept of `Campaign` to `ChargeSite`
- Renamed concept of `Deal` to `ChargeOffer`
- Moved `Campaign.campaigns(in:)` to ChargeSite.campaigns(in:)`
- Moved `Campaign.campaigns(near:)` to ChargeSite.campaigns(near:)`
- Removed `onCampaignEnd(perform:)` modifier from `ChargeBanner`

### Bug Fixes
- Added exit buttons for all states in the charge flow
- Fixed background color in the support sheet

---

## [0.1.0] - Initial Release

Initial release of the elvah Charge SDK.
