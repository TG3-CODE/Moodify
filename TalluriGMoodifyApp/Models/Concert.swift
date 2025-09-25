//
//  Concert.swift
//  TalluriGMoodifyApp
//
//  Created by Gayatri Talluri on 6/3/25.
//

import Foundation
import CoreLocation

struct Concert: Identifiable, Codable {
    let id: String
    let artistName: String
    let venueName: String
    let date: Date
    let ticketURL: String
    let imageURL: String?
    let coordinate: CLLocationCoordinate2D
    let city: String
    let priceRange: String?
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var isThisWeek: Bool {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? Date()
        return date >= startOfWeek && date < endOfWeek
    }
    enum CodingKeys: String, CodingKey {
        case id, artistName, venueName, date, ticketURL, imageURL, city, priceRange
        case latitude, longitude
    }
    
    init(id: String, artistName: String, venueName: String, date: Date, ticketURL: String, imageURL: String?, coordinate: CLLocationCoordinate2D, city: String, priceRange: String?) {
        self.id = id
        self.artistName = artistName
        self.venueName = venueName
        self.date = date
        self.ticketURL = ticketURL
        self.imageURL = imageURL
        self.coordinate = coordinate
        self.city = city
        self.priceRange = priceRange
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        artistName = try container.decode(String.self, forKey: .artistName)
        venueName = try container.decode(String.self, forKey: .venueName)
        date = try container.decode(Date.self, forKey: .date)
        ticketURL = try container.decode(String.self, forKey: .ticketURL)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        city = try container.decode(String.self, forKey: .city)
        priceRange = try container.decodeIfPresent(String.self, forKey: .priceRange)
        
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(artistName, forKey: .artistName)
        try container.encode(venueName, forKey: .venueName)
        try container.encode(date, forKey: .date)
        try container.encode(ticketURL, forKey: .ticketURL)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(city, forKey: .city)
        try container.encodeIfPresent(priceRange, forKey: .priceRange)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}
extension Concert {
    static let sampleConcerts: [Concert] = [
        Concert(
            id: "1",
            artistName: "Taylor Swift",
            venueName: "Chase Center",
            date: Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date(),
            ticketURL: "https://www.ticketmaster.com",
            imageURL: nil,
            coordinate: CLLocationCoordinate2D(latitude: 37.7682, longitude: -122.3874),
            city: "San Francisco",
            priceRange: "$85-$250 USD"
        ),
        Concert(
            id: "2",
            artistName: "Coldplay",
            venueName: "Oracle Park",
            date: Calendar.current.date(byAdding: .day, value: 22, to: Date()) ?? Date(),
            ticketURL: "https://www.ticketmaster.com",
            imageURL: nil,
            coordinate: CLLocationCoordinate2D(latitude: 37.7786, longitude: -122.3893),
            city: "San Francisco",
            priceRange: "$75-$200 USD"
        ),
        Concert(
            id: "3",
            artistName: "Billie Eilish",
            venueName: "The Fillmore",
            date: Calendar.current.date(byAdding: .day, value: 8, to: Date()) ?? Date(),
            ticketURL: "https://www.ticketmaster.com",
            imageURL: nil,
            coordinate: CLLocationCoordinate2D(latitude: 37.7844, longitude: -122.4324),
            city: "San Francisco",
            priceRange: "$95-$180 USD"
        ),
        Concert(
            id: "4",
            artistName: "The Weeknd",
            venueName: "Madison Square Garden",
            date: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            ticketURL: "https://www.ticketmaster.com",
            imageURL: nil,
            coordinate: CLLocationCoordinate2D(latitude: 40.7505, longitude: -73.9934),
            city: "New York",
            priceRange: "$120-$300 USD"
        ),
        Concert(
            id: "5",
            artistName: "Ariana Grande",
            venueName: "United Center",
            date: Calendar.current.date(byAdding: .day, value: 25, to: Date()) ?? Date(),
            ticketURL: "https://www.ticketmaster.com",
            imageURL: nil,
            coordinate: CLLocationCoordinate2D(latitude: 41.8807, longitude: -87.6742),
            city: "Chicago",
            priceRange: "$90-$220 USD"
        ),
        Concert(
            id: "6",
            artistName: "Ed Sheeran",
            venueName: "Staples Center",
            date: Calendar.current.date(byAdding: .day, value: 18, to: Date()) ?? Date(),
            ticketURL: "https://www.ticketmaster.com",
            imageURL: nil,
            coordinate: CLLocationCoordinate2D(latitude: 34.0430, longitude: -118.2673),
            city: "Los Angeles",
            priceRange: "$110-$280 USD"
        ),
        Concert(
            id: "7",
            artistName: "Bruno Mars",
            venueName: "Climate Pledge Arena",
            date: Calendar.current.date(byAdding: .day, value: 35, to: Date()) ?? Date(),
            ticketURL: "https://www.ticketmaster.com",
            imageURL: nil,
            coordinate: CLLocationCoordinate2D(latitude: 47.6219, longitude: -122.3540),
            city: "Seattle",
            priceRange: "$105-$260 USD"
        ),
        Concert(
            id: "8",
            artistName: "Dua Lipa",
            venueName: "American Airlines Center",
            date: Calendar.current.date(byAdding: .day, value: 42, to: Date()) ?? Date(),
            ticketURL: "https://www.ticketmaster.com",
            imageURL: nil,
            coordinate: CLLocationCoordinate2D(latitude: 32.7903, longitude: -96.8103),
            city: "Dallas",
            priceRange: "$80-$190 USD"
        )
    ]
}
