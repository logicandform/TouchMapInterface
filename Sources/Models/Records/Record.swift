//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


class Record: Hashable {

    let type: RecordType
    let id: Int
    let title: String
    let dates: DateRange?
    let coordinate: CLLocationCoordinate2D?
    var relatedRecordsOfType = [RecordType: Record]()

    var hashValue: Int {
        return id.hashValue ^ type.hashValue
    }


    // MARK: Init

    init(type: RecordType, id: Int, title: String, dates: DateRange?, coordinate: CLLocationCoordinate2D?) {
        self.type = type
        self.id = id
        self.title = title
        self.dates = dates
        self.coordinate = coordinate
    }


    // MARK: Hashable

    static func == (lhs: Record, rhs: Record) -> Bool {
        return lhs.id == rhs.id && lhs.type == rhs.type && lhs.title == rhs.title
    }
}
