import CoreLocation
import MapKit
import SwiftUI

struct MapDestination: Hashable, Codable {
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

    @Environment(\.navigate) var navigate
    @State private var selectedFeature: MapFeature?
    @State private var toastMessage: String?

    var body: some View {
        // good enough zoom approximation
        let rawZoom = 12.0 * pow(dest.precision, 0.7)
        let zoomDegrees = min(max(rawZoom, 0.004), 15.0)

        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: zoomDegrees, longitudeDelta: zoomDegrees)
        )

        Map(initialPosition: .region(region), selection: $selectedFeature) {
            Marker(dest.title, coordinate: coordinate)
                .tint(.strongRed)
        }
        .navigationTitle(dest.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedFeature) { _, tappedPOI in
            Task {
                if let tappedPOI {
                    await handlePOITap(feature: tappedPOI)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage {
                Text(toastMessage)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .padding(.horizontal, .large)
                    .padding(.vertical, .medium)
                    .glassEffect()
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .bottom),
                            removal: .opacity
                        ))
            }
        }
        .animation(.snappy, value: toastMessage)
    }

    private func handlePOITap(feature: MapFeature) async {
        let coordinate = feature.coordinate
        let name = feature.title ?? ""

        do {
            let results = try await findSimilarItems(
                SimilarItemsQuery(
                    propertyID: "P625",
                    value: .coordinate(
                        lat: coordinate.latitude, lon: coordinate.longitude, precision: 0),
                    geoRadius: 0.5
                )
            )

            if let bestMatch = POIMatcher.findBestMatch(applePOI: name, wikidataResults: results) {
                navigate(bestMatch)
            } else {
                showToast(String(localized: "No match found for '\(name)'"))
            }
        } catch {
            showToast(String(localized: "Network error"))
        }

        selectedFeature = nil
    }

    private func showToast(_ message: String) {
        toastMessage = message

        Task {
            let duration = min(1.5 + Double(message.count) * 0.05, 4.0)
            try? await Task.sleep(for: .seconds(duration))

            if toastMessage == message {
                toastMessage = nil
            }
        }
    }
}
