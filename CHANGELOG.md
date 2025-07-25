# Changelog

All notable changes to this project will be documented in this file.

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

**Breaking API Changes**
- This release changes a lot of the public API. See [MIGRATION.md](MIGRATION.md) for detailed migration instructions from version 0.1.0.

### New Features

**Campaign Filtering**
- Added `fetching` parameter to `@ChargeBannerSource`:
  ```swift
  @ChargeBannerSource(fetching: .campaigns) private var chargeBannerSource
  ```
- Enables filtering for campaign-only offers

**Enhanced Charge Offer API**
- New presentation modifier: `.chargePresentation(offers:)` for offer lists

**Developer Experience**
- Added migration guide in `MIGRATION.md`
- Improved documentation with updated examples
- Enhanced test infrastructure with better simulation flows

### Bug Fixes
- Added exit buttons for all states in the charge flow

---

## [0.1.0] - Initial Release

Initial release of the elvah Charge SDK.
