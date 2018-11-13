//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class RecordManager {
    static let instance = RecordManager()

    /// Type: [ID: Record]
    private var recordsForType: [RecordType: [Int: Record]] = [:]


    // MARK: Init

    /// Use singleton
    private init() {
        for type in RecordType.allCases {
            recordsForType[type] = [:]
        }
    }


    // MARK: API

    /// Creates mock records and relates them to one another
    func initialize() {

        guard let jsonURL = Bundle.main.url(forResource: "cities", withExtension: "json"), let data = try? Data(contentsOf: jsonURL), let json = try? JSONSerialization .jsonObject(with: data, options: []) as? [JSON], let citiesJSON = json else {
            print("Failed to serialize City records from cities.json file.")
            return
        }

        let cities = citiesJSON.compactMap { City(json: $0) }
        store(cities, for: .city)

//        createRelationships()
    }

    func allRecords() -> [Record] {
        return RecordType.allCases.reduce([]) { $0 + records(for: $1) }
    }

    func record(for type: RecordType, id: Int) -> Record? {
        return recordsForType[type]?[id]
    }

    func records(for type: RecordType, ids: [Int]) -> [Record] {
        return ids.compactMap { recordsForType[type]?[$0] }
    }

    func records(for type: RecordType) -> [Record] {
        guard let recordsForID = recordsForType[type] else {
            return []
        }

        return Array(recordsForID.values)
    }


    // MARK: Helpers

    private func createRecords(of type: RecordType) -> [Record] {
        return []
    }

    private func store(_ records: [Record], for type: RecordType) {
        for record in records {
            recordsForType[type]?[record.id] = record
        }
    }

    private func createRelationships() {
        for (_, records) in recordsForType {
            for (_, record) in records {
                makeRelationships(for: record)
            }
        }
    }

    private func makeRelationships(for record: Record) {

    }
}
