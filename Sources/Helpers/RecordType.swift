//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum RecordType: String, CaseIterable {
    case school
    case event
    case organization
    case individual

    var color: NSColor {
        switch self {
        case .school:
            return style.schoolColor
        case .event:
            return style.eventColor
        case .organization:
            return style.collectionColor
        case .individual:
            return style.individualColor
        }
    }

    var timelineSortOrder: Int {
        switch self {
        case .school:
            return 1
        case .event:
            return 2
        case .organization:
            return 3
        case .individual:
            return 4
        }
    }

    var placeholder: NSImage {
        switch self {
        case .event:
            return NSImage(named: "event-icon")!
        case .organization:
            return NSImage(named: "organization-icon")!
        case .school:
            return NSImage(named: "school-icon")!
        case .individual:
            return NSImage(named: "individual-icon")!
        }
    }
}
