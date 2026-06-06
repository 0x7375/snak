import CoreLocation
import MapKit
import SwiftUI

struct MapDestination: Hashable, Codable {
    let title: String
    let latitude: Double
    let longitude: Double
    let precision: Double?
}

struct MapView: View {
    let dest: MapDestination

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: dest.latitude, longitude: dest.longitude)
    }

    var region: MKCoordinateRegion {
        // good enough zoom approximation
        let rawZoom = 12.0 * pow(dest.precision ?? 0.0001, 0.7)
        let zoomDegrees = min(max(rawZoom, 0.004), 15.0)

        return MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: zoomDegrees, longitudeDelta: zoomDegrees)
        )
    }

    var mapMarker: some MapContent {
        Marker(dest.title.smartCase, coordinate: coordinate)
            .tint(.strongRed)
    }

    var map: some View {
        #if os(watchOS)
            Map(initialPosition: .region(region)) { mapMarker }
        #else
            Map(initialPosition: .region(region), selection: $selectedFeature) { mapMarker }
        #endif
    }

    @Environment(\.navigate) var navigate

    #if !os(watchOS)
        @State private var selectedFeature: MapFeature?
        @State private var toastMessage: String?
    #endif

    var body: some View {
        map
            .navigationTitle(dest.title.smartCase)
            .navigationBarTitleDisplayMode(.inline)
            #if os(iOS)
                .onChange(of: selectedFeature) { _, tappedPOI in
                    Task {
                        if let tappedPOI { await handlePOITap(feature: tappedPOI) }
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
                            )
                        )
                        .padding(.horizontal, .medium)
                    }
                }
                .animation(.snappy, value: toastMessage)
            #endif
    }

    #if !os(watchOS)
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

                if let bestMatch = POIMatcher.findBestMatch(
                    applePOI: name, wikidataResults: results)
                {
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
    #endif
}
