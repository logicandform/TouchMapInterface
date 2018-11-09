//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class ResponseHandler {


    // MARK: Schools

    static func serializeSchools(from json: Any) throws -> [School] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.compactMap { School(json: $0) }
    }


    // MARK: Events

    static func serializeEvents(from json: Any) throws -> [Event] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.compactMap { Event(json: $0) }
    }


    // MARK: Collections

    static func serializeCollections(from json: Any) throws -> [RecordCollection] {
        guard let json = json as? [JSON] else {
            throw NetworkError.badResponse
        }

        return json.compactMap { RecordCollection(json: $0) }
    }
}
