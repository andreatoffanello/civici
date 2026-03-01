import SwiftUI
import MapKit

struct ResultView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.strings) private var strings
    @AppStorage("defaultMapView") private var defaultMapViewPref: String = DefaultMapView.threeD.rawValue
    @AppStorage("preferredNavApp") private var preferredNavApp: String = PreferredNavApp.appleMaps.rawValue
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var is3D = true
    @State private var is3DInitialized = false
    @State private var mapAppeared = false
    @State private var showNavigationOptions = false
    @Environment(\.colorScheme) private var colorScheme

    private var vignetteColor: Color {
        colorScheme == .dark ? Color(hex: "1A1A1A") : Color.niziolettoBackground
    }

    private func cameraFor(_ civico: Civico) -> MapCamera {
        MapCamera(
            centerCoordinate: civico.coordinate,
            distance: 500,
            heading: 0,
            pitch: is3D ? 45 : 0
        )
    }

    var body: some View {
        if let civico = viewModel.selectedCivico {
            ZStack {
                // Full-screen map
                Map(position: $mapCameraPosition) {
                    Annotation(
                        "",
                        coordinate: civico.coordinate,
                        anchor: .bottom
                    ) {
                        VStack(spacing: 0) {
                            VStack(spacing: 2) {
                                Text(civico.number)
                                    .font(.system(.callout, design: .rounded, weight: .bold))
                                    .foregroundStyle(.white)

                                if let distance = locationManager.formattedDistance(to: civico.coordinate) {
                                    Text(distance)
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.doVeAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            // Pin tail
                            Triangle()
                                .fill(Color.doVeAccent)
                                .frame(width: 14, height: 8)
                        }
                    }

                    // User location
                    UserAnnotation()
                }
                .mapStyle(.standard(elevation: is3D ? .realistic : .flat, pointsOfInterest: .excludingAll))
                .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .ignoresSafeArea()
                .scaleEffect(mapAppeared ? 1 : 1.08)
                .opacity(mapAppeared ? 1 : 0)
                .animation(.easeOut(duration: 1.8), value: mapAppeared)
                .onAppear {
                    if !is3DInitialized {
                        is3D = defaultMapViewPref == DefaultMapView.threeD.rawValue
                        is3DInitialized = true
                    }
                    mapAppeared = true
                    locationManager.startUpdating()
                    mapCameraPosition = .camera(cameraFor(civico))
                }
                .onDisappear {
                    locationManager.stopUpdating()
                }

                // Vignette overlay
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .clear,
                                .clear,
                                vignetteColor.opacity(0.4),
                                vignetteColor.opacity(0.7),
                                vignetteColor.opacity(0.9)
                            ],
                            center: .center,
                            startRadius: 100,
                            endRadius: 450
                        )
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                // UI overlay
                VStack(spacing: 0) {
                    // Top bar: back + nizioleto + share
                    HStack(alignment: .top) {
                        Button {
                            viewModel.selectedCivico = nil
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .frame(width: 44, height: 44)
                                .contentShape(Circle())
                                .adaptiveGlassEffect(interactive: true, in: Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Nizioleto address card
                        VStack(spacing: 4) {
                            Text(civico.areaName.uppercased())
                                .font(.custom("Sotoportego-Medium", size: 13))
                                .foregroundStyle(Color(hex: "2A2A2A"))

                            if let via = civico.via {
                                Text(via.uppercased())
                                    .font(.custom("Sotoportego-Medium", size: 18))
                                    .foregroundStyle(Color(hex: "2A2A2A"))
                                    .multilineTextAlignment(.center)
                            }

                            Text(civico.number)
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .foregroundStyle(Color.doVeAccent)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "F5F0E6"))
                        .clipShape(NiziolettoShape())
                        .overlay(
                            NiziolettoShape()
                                .stroke(Color(hex: "2A2A2A").opacity(0.8), lineWidth: 2.5)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                        Spacer()

                        // Share button
                        ShareLink(item: "\(civico.displayName)\nhttps://www.google.com/maps?q=\(civico.coordinate.latitude),\(civico.coordinate.longitude)") {
                            Image(systemName: "square.and.arrow.up")
                                .font(.body.weight(.semibold))
                                .frame(width: 40, height: 40)
                                .adaptiveGlassEffect(interactive: true, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .opacity(mapAppeared ? 1 : 0)
                    .offset(y: mapAppeared ? 0 : -10)
                    .animation(.easeOut(duration: 1.2).delay(0.6), value: mapAppeared)

                    Spacer()

                    // Bottom controls
                    HStack(alignment: .bottom) {
                        // Map controls: 3D toggle + recenter + north reset
                        VStack(spacing: 10) {
                            Button {
                                is3D.toggle()
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    mapCameraPosition = .camera(cameraFor(civico))
                                }
                            } label: {
                                Text(is3D ? "2D" : "3D")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .frame(width: 40, height: 40)
                                    .adaptiveGlassEffect(interactive: true, in: Circle())
                            }
                            .buttonStyle(.plain)

                            // Centra sul civico
                            Button {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    mapCameraPosition = .camera(cameraFor(civico))
                                }
                            } label: {
                                Image(systemName: "scope")
                                    .font(.body.weight(.semibold))
                                    .frame(width: 40, height: 40)
                                    .adaptiveGlassEffect(interactive: true, in: Circle())
                            }
                            .buttonStyle(.plain)

                            // Reset orientamento nord
                            Button {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    mapCameraPosition = .camera(
                                        MapCamera(
                                            centerCoordinate: civico.coordinate,
                                            distance: 500,
                                            heading: 0,
                                            pitch: is3D ? 45 : 0
                                        )
                                    )
                                }
                            } label: {
                                Image(systemName: "location.north.fill")
                                    .font(.body.weight(.semibold))
                                    .frame(width: 40, height: 40)
                                    .adaptiveGlassEffect(interactive: true, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        // Navigate action
                        Button {
                            navigateToCivico(civico)
                        } label: {
                            Label(strings.navigate, systemImage: "arrow.triangle.turn.up.right.diamond")
                                .font(.body.weight(.medium))
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .adaptiveGlassEffect(interactive: true, in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Invisible spacer to balance layout
                        Color.clear
                            .frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                    .opacity(mapAppeared ? 1 : 0)
                    .offset(y: mapAppeared ? 0 : 20)
                    .animation(.easeOut(duration: 1.2).delay(0.8), value: mapAppeared)
                }
                .ignoresSafeArea(edges: .top)
                .padding(.top, 6)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .confirmationDialog(strings.openNavigationWith, isPresented: $showNavigationOptions, titleVisibility: .visible) {
                Button("Apple Maps") {
                    openInAppleMaps(civico: civico)
                }

                if canOpenGoogleMaps {
                    Button("Google Maps") {
                        openInGoogleMaps(civico: civico)
                    }
                }

                if canOpenWaze {
                    Button("Waze") {
                        openInWaze(civico: civico)
                    }
                }

                Button(strings.cancel, role: .cancel) {}
            }
        }
    }

    // MARK: - Navigation

    private func navigateToCivico(_ civico: Civico) {
        let pref = PreferredNavApp(rawValue: preferredNavApp) ?? .appleMaps

        switch pref {
        case .alwaysAsk:
            showNavigationOptions = true
        case .googleMaps where canOpenGoogleMaps:
            openInGoogleMaps(civico: civico)
        case .waze where canOpenWaze:
            openInWaze(civico: civico)
        case .appleMaps:
            openInAppleMaps(civico: civico)
        default:
            // Preferred app not installed — show picker
            showNavigationOptions = true
        }
    }

    private var canOpenGoogleMaps: Bool {
        UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!)
    }

    private var canOpenWaze: Bool {
        UIApplication.shared.canOpenURL(URL(string: "waze://")!)
    }

    private func openInAppleMaps(civico: Civico) {
        let placemark = MKPlacemark(coordinate: civico.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = civico.displayName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }

    private func openInGoogleMaps(civico: Civico) {
        let lat = civico.coordinate.latitude
        let lng = civico.coordinate.longitude
        if let url = URL(string: "comgooglemaps://?daddr=\(lat),\(lng)&directionsmode=walking") {
            UIApplication.shared.open(url)
        }
    }

    private func openInWaze(civico: Civico) {
        let lat = civico.coordinate.latitude
        let lng = civico.coordinate.longitude
        if let url = URL(string: "waze://?ll=\(lat),\(lng)&navigate=yes") {
            UIApplication.shared.open(url)
        }
    }
}

// Custom triangle shape for pin tail
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
