//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class City: Record {
    static private var counter = 0

    private struct Keys {
        static let title = "city"
        static let population = "population"
        static let latitude = "lat"
        static let longitude = "lng"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let title = json[Keys.title] as? String, let latitude = json[Keys.latitude] as? String, let population = json[Keys.population] as? String, let longitude = json[Keys.longitude] as? String, let long = Double(longitude), let lat = Double(latitude) else {
            return nil
        }

        City.counter += 1
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let description = "\(title) has a population of \(population)."
        super.init(type: .city, id: City.counter, title: title, description: description, dates: nil, coordinate: coordinate)
    }
}
