// Copyright © elvah. All rights reserved.

import Foundation
import MapKit

extension MKMapRect {
  static var mock: MKMapRect {
    let topLeft = CLLocationCoordinate2D(latitude: 5.0, longitude: 4)
    let bottomRight = CLLocationCoordinate2D(latitude: 52, longitude: 50)
    return MKMapRect(
      x: MKMapPoint(topLeft).x,
      y: MKMapPoint(bottomRight).y,
      width: MKMapPoint(bottomRight).x - MKMapPoint(topLeft).x,
      height: MKMapPoint(topLeft).y - MKMapPoint(bottomRight).y,
    )
  }
}
