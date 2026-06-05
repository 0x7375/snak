import CoreLocation
import MapKit
import SwiftUI

struct MapDestination: Hashable {
    let title: String
    let latitude: Double
    let longitude: Double
    let precision: Double
}

struct MapView: View {
    let dest: MapDestination

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: dest.latitude, longitude: dest.longitude)
    }

    var body: some View {
        // good enough zoom approximation
        let rawZoom = 12.0 * pow(dest.precision, 0.7)
        let zoomDegrees = min(max(rawZoom, 0.004), 15.0)

        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: zoomDegrees, longitudeDelta: zoomDegrees)
        )

        Map(initialPosition: .region(region)) {
            Marker(dest.title, coordinate: coordinate)
                .tint(.strongRed)
        }
        .navigationTitle(dest.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
