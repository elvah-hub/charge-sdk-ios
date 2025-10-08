// Copyright © elvah. All rights reserved.

import MapKit
import SwiftUI

@available(iOS 16.0, *)
package extension Site {
  /// Opens directions in Apple Maps for the station's location, in driving mode.
  func openDirectionsInAppleMaps() {
    let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
    openInAppleMaps(launchOptions: options)
  }

  /// Opens the station's location in Apple Maps.
  /// - Parameter launchOptions: Additional options to configure the maps launch. Defaults to `nil`.
  func openInAppleMaps(launchOptions: [String: Any]? = nil) {
    let coordinate = CLLocationCoordinate2D(
      latitude: location.latitude,
      longitude: location.longitude,
    )
    let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
    let mapItem = MKMapItem(placemark: placemark)
    mapItem.name = address?.formatted()
    mapItem.openInMaps(launchOptions: launchOptions)
  }

  /// Opens the station's location in Google Maps application.
  /// Does nothing if the Google Maps URL can't be created.
  @MainActor func openInGoogleMaps() {
    let string = "comgooglemaps://?&daddr=\(location.latitude),\(location.longitude)"
    guard let googleMapsURL = URL(string: string) else {
      return
    }
    UIApplication.shared.open(googleMapsURL)
  }

  /// Opens driving directions to the station's location in Google Maps.
  /// Does nothing if the Google Maps URL can't be created.
  @MainActor func openDirectionsInGoogleMaps() {
    let string =
      "comgooglemaps://?&daddr=\(location.latitude),\(location.longitude)&directionsmode=driving"
    guard let googleMapsURL = URL(string: string) else {
      return
    }
    UIApplication.shared.open(googleMapsURL)
  }
}
