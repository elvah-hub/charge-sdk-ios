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
			height: MKMapPoint(topLeft).y - MKMapPoint(bottomRight).y
		)
	}

	static func around(_ center: CLLocationCoordinate2D, radius: CLLocationDistance) -> MKMapRect {
		// Convert the coordinate to an MKMapPoint.
		let centerPoint = MKMapPoint(center)

		// Determine the number of meters per map point at the given latitude.
		let metersPerMapPoint = MKMetersPerMapPointAtLatitude(center.latitude)

		// Calculate the half-size in map points for a 2.5 km (half of 5 km) offset.
		let halfMapPointLength = (radius / 2) / metersPerMapPoint

		// Create the rectangle, centering it on the map point.
		let origin = MKMapPoint(
			x: centerPoint.x - halfMapPointLength,
			y: centerPoint.y - halfMapPointLength
		)
		let size = MKMapSize(
			width: halfMapPointLength * 2,
			height: halfMapPointLength * 2
		)

		return MKMapRect(origin: origin, size: size)
	}
}
