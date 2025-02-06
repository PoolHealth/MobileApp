//
//  PoolChangeSettingsView.swift
//  PoolHealth
//
//  Created by user on 16/01/2025.
//

import SwiftUI
import MapKit

struct PoolChangeSettingsView: View {
    var id: String
    var name: String
    var currentSettings: PoolSettings?
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @ObservedObject var manager: PoolManager
    @State private var poolType: PoolType = .unknown
    @State private var usageType: UsageType = .unknown
    @State private var shape: PoolShape = .unknown
    @State private var locationType: PoolLocationType = .unknown
    @State private var coordinates: CLLocationCoordinate2D = .init(latitude: 34.8833, longitude: 32.3875)
    var body: some View {
        VStack {
            PoolParameterView(title: "Pool type", initialValue: currentSettings?.type, options: PoolType.allCases, parameter: $poolType)
            PoolParameterView(title: "Usage type", initialValue: currentSettings?.usageType, options: UsageType.allCases, parameter: $usageType)
            PoolParameterView(title: "Shape", initialValue: currentSettings?.shape, options: PoolShape.allCases, parameter: $shape)
            PoolParameterView(title: "Location type", initialValue: currentSettings?.locationType, options: PoolLocationType.allCases, parameter: $locationType)
            MapReader { proxy in
                Map(initialPosition: initialPosition()) {
                    Marker("Pool location", coordinate: currentSettings?.coordinates ?? coordinates).tint(.blue)
                }.onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        coordinates = coordinate
                    }
                }.mapStyle(.imagery(elevation: .realistic))
            }.onAppear {
                guard let p = currentSettings?.coordinates else {
                    return
                }
                self.coordinates = p
                print(coordinates)
            }
            
            Button("Save") {
                Task {
                    await manager.setSettings(id: id, settings: PoolSettings(type:poolType, usageType: usageType, shape: shape, locationType: locationType, coordinates: coordinates))
                    await MainActor.run{
                        if manager.error == nil {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }.disabled(poolType == .unknown || usageType == .unknown || shape == .unknown || locationType == .unknown)
        }.navigationBarTitle("\(name) PoolSettings")
    }
    
    private func initialPosition() -> MapCameraPosition {
        return MapCameraPosition.region(
            MKCoordinateRegion(
                center: currentSettings?.coordinates ?? CLLocationCoordinate2D(latitude: 34.8833, longitude: 32.3875),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            )
    }
}

#Preview {
    PoolChangeSettingsView(id: UUID().uuidString, name: "Eleonas", currentSettings: PoolSettings(type: .skimmer, coordinates: CLLocationCoordinate2D(latitude: 0, longitude: 0)), manager: .init())
}
