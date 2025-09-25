//
//  ConcertMapView.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct ConcertMapView: View {
    @StateObject private var concertManager = ConcertManager()
    @EnvironmentObject var locationManager: LocationManager
    @State private var searchText = ""
    @State private var selectedCity = "All Cities"
    @State private var showingCityPicker = false
    @State private var showingConcertDetails: Concert? = nil
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // San Francisco default
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
    )
    
    let majorCities = [
        "All Cities",
        "San Francisco", "Los Angeles", "New York", "Chicago",
        "Houston", "Phoenix", "Philadelphia", "San Antonio",
        "San Diego", "Dallas", "Austin", "Seattle", "Denver",
        "Las Vegas", "Miami", "Atlanta", "Boston", "Portland"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Map Background
                Map(coordinateRegion: $mapRegion, annotationItems: concertManager.concerts) { concert in
                    MapAnnotation(coordinate: concert.coordinate) {
                        ConcertPin(concert: concert) {
                            showingConcertDetails = concert
                        }
                    }
                }
                .onAppear {
                    if let userLocation = locationManager.location {
                        mapRegion.center = userLocation.coordinate
                    }
                }
                VStack {
                    VStack(spacing: 12) {
                        Text("🎵 Live Music")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        // Artist Search Bar
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.purple)
                            
                            TextField("Search artists (e.g., Taylor Swift, Coldplay)", text: $searchText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .onSubmit {
                                    searchConcerts()
                                }
                        }
                        
                        // City Selection
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.purple)
                            
                            Button(action: {
                                showingCityPicker = true
                            }) {
                                HStack {
                                    Text(selectedCity)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.purple)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Search Button
                        Button(action: searchConcerts) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text(searchText.isEmpty ? "Search All Concerts" : "Find \(searchText) Concerts")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [.purple, .pink]),
                                             startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(25)
                        }
                        .disabled(concertManager.isLoading)
                        
                        // Loading/Status Indicator
                        if concertManager.isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Searching concerts...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else if let errorMessage = concertManager.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        } else if !concertManager.concerts.isEmpty {
                            Text("Found \(concertManager.concerts.count) concerts")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding()
                    
                    Spacer()
                    
                    // Refresh Button
                    VStack {
                        Button("Refresh") {
                            searchConcerts()
                        }
                        .foregroundColor(.purple)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(20)
                        .shadow(radius: 3)
                    }
                    .padding(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    if !concertManager.concerts.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(concertManager.concerts.prefix(3)) { concert in
                                    ConcertCard(concert: concert) {
                                        showingConcertDetails = concert
                                        withAnimation {
                                            mapRegion.center = concert.coordinate
                                            mapRegion.span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 120)
                        .background(Color.white.opacity(0.95))
                        .roundedCorner(15, corners: [.topLeft, .topRight])
                        .shadow(radius: 5)
                    }
                }
            }
        }
        .onAppear {
            concertManager.loadSampleConcerts()
        }
        .actionSheet(isPresented: $showingCityPicker) {
            ActionSheet(
                title: Text("Select City"),
                message: Text("Choose a city to search in"),
                buttons: majorCities.map { city in
                    .default(Text(city)) {
                        selectedCity = city
                        searchConcerts()
                    }
                } + [.cancel()]
            )
        }
        .sheet(item: $showingConcertDetails) { concert in
            ConcertDetailView(concert: concert)
        }
    }
    
    private func searchConcerts() {
        let city = selectedCity == "All Cities" ? nil : selectedCity
        concertManager.searchConcerts(artist: searchText.isEmpty ? nil : searchText, city: city)
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

class ConcertManager: ObservableObject {
    @Published var concerts: [Concert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadSampleConcerts() {
        concerts = Concert.sampleConcerts
    }
    
    func searchConcerts(artist: String? = nil, city: String? = nil) {
        print("🎪 Searching concerts - Artist: \(artist ?? "All"), City: \(city ?? "All")")
        
        isLoading = true
        errorMessage = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            var filteredConcerts = Concert.sampleConcerts
            if let artist = artist, !artist.isEmpty {
                filteredConcerts = filteredConcerts.filter { concert in
                    concert.artistName.localizedCaseInsensitiveContains(artist)
                }
            }
            if let city = city, city != "All Cities" {
                filteredConcerts = filteredConcerts.filter { concert in
                    concert.city.localizedCaseInsensitiveContains(city)
                }
            }
            if filteredConcerts.isEmpty {
                if let artist = artist, !artist.isEmpty {
                    if let city = city, city != "All Cities" {
                        self.errorMessage = "No \(artist) concerts found in \(city)"
                    } else {
                        self.errorMessage = "No concerts found for \(artist)"
                    }
                } else if let city = city, city != "All Cities" {
                    self.errorMessage = "No concerts found in \(city)"
                } else {
                    self.errorMessage = "No concerts found"
                }
            } else {
                self.errorMessage = nil
            }
            
            self.concerts = filteredConcerts
            
            if !filteredConcerts.isEmpty {
                print("✅ Found \(filteredConcerts.count) concerts")
            }
        }
    }
}
struct ConcertPin: View {
    let concert: Concert
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Text("🎵")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.purple))
                    .shadow(radius: 3)
                
                Text(concert.artistName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                    .shadow(radius: 2)
            }
        }
    }
}
struct ConcertCard: View {
    let concert: Concert
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(concert.artistName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(concert.venueName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(concert.city)
                    .font(.caption)
                    .foregroundColor(.purple)
                
                HStack {
                    Text(concert.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let price = concert.priceRange {
                        Text(price)
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 3)
        }
        .frame(width: 180)
    }
}
struct ConcertDetailView: View {
    let concert: Concert
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Rectangle()
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [.purple, .pink]),
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Text("🎵")
                                    .font(.system(size: 60))
                                Text(concert.artistName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        )
                        .cornerRadius(15)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(concert.artistName)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.purple)
                            Text("\(concert.venueName), \(concert.city)")
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.purple)
                            Text(concert.formattedDate)
                                .font(.subheadline)
                        }
                        
                        if let price = concert.priceRange {
                            HStack {
                                Image(systemName: "dollarsign.circle")
                                    .foregroundColor(.green)
                                Text(price)
                                    .font(.subheadline)
                            }
                        }
                    }
                    Button(action: {
                        if let url = URL(string: concert.ticketURL) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "ticket")
                            Text("Buy Tickets")
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [.purple, .pink]),
                                         startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(15)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Concert Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
extension View {
    func roundedCorner(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
