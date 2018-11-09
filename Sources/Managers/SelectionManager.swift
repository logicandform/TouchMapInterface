//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


// Interface for the TimelineHandler to update it's views
protocol SelectionHandler: class {
    func handle(item: Int, selected: Bool)
    func replace(selection: Set<TimelineSelection>)
    func handle(items: Set<Int>, highlighted: Bool)
    func replace(highlighted: Set<Int>)
}


/// Handles notifications for Timeline selection and highlights
final class SelectionManager {
    static let instance = SelectionManager()

    weak var delegate: SelectionHandler?

    /// Selections for an app's timeline indexed by it's appID
    private var selectionForApp = [Set<TimelineSelection>]()

    /// Remaining duration of highlight for event supplied by it's id
    private var timeForHighlight = [Int: [Int: Int]]()

    /// The current time of the system core video clock
    private var currentTime = UInt64.min

    /// The timer used to update the current time and decrement highlight times
    private weak var highlightTimer: Foundation.Timer?

    private struct Constants {
        static let highlightDuration = 25
        static let highlightTimerInterval = 0.1
    }

    private struct Keys {
        static let id = "id"
        static let group = "group"
        static let index = "index"
        static let state = "state"
        static let type = "type"
        static let selection = "selection"
    }


    // MARK: Init

    /// Use Singleton
    private init() {
        let numberOfApps = Configuration.appsPerScreen * Configuration.numberOfScreens
        self.selectionForApp = Array(repeating: Set<TimelineSelection>(), count: numberOfApps)
        for app in (0 ..< numberOfApps) {
            timeForHighlight[app] = [:]
        }

        highlightTimer = Timer.scheduledTimer(withTimeInterval: Constants.highlightTimerInterval, repeats: true) { [weak self] _ in
            self?.highlightTimerFired()
        }
        highlightTimer?.tolerance = Constants.highlightTimerInterval / 10
    }


    // MARK: API

    func merge(app: Int, toGroup group: Int?) {
        guard let group = group else {
            return
        }

        let selection = selectionForApp[group]
        let times = timeForHighlight[group]
        selectionForApp[app] = selection
        timeForHighlight[app] = times
        if app == appID {
            delegate?.replace(selection: selection)
            delegate?.replace(highlighted: Set(times!.keys))
        }
    }

    func set(item: Int, selected: Bool) {
        var info: JSON = [Keys.id: appID, Keys.index: item, Keys.state: selected]
        if let group = ConnectionManager.instance.groupForApp(id: appID, type: .timeline) {
            info[Keys.group] = group
        }
        DistributedNotificationCenter.default().postNotificationName(TimelineNotification.select.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func highlight(item: Int) {
        var info: JSON = [Keys.index: item, Keys.state: true]
        if let group = ConnectionManager.instance.groupForApp(id: appID, type: .timeline) {
            info[Keys.group] = group
        }
        DistributedNotificationCenter.default().postNotificationName(TimelineNotification.highlight.name, object: nil, userInfo: info, deliverImmediately: true)
    }

    func registerForNotifications() {
        let notifications: [TimelineNotification] = [.select, .highlight]
        for notification in notifications {
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: notification.name, object: nil)
        }
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: SettingsNotification.reset.name, object: nil)
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(handleNotification(_:)), name: SettingsNotification.hardReset.name, object: nil)
    }


    // MARK: Notifications

    @objc
    private func handleNotification(_ notification: NSNotification) {
        guard let info = notification.userInfo else {
            return
        }

        let group = info[Keys.group] as? Int

        switch notification.name {
        case TimelineNotification.select.name:
            if let id = info[Keys.id] as? Int, let index = info[Keys.index] as? Int, let state = info[Keys.state] as? Bool {
                set(index: index, group: group, selected: state, from: id)
            }
        case TimelineNotification.highlight.name:
            if let index = info[Keys.index] as? Int {
                setHighlight(index: index, group: group)
            }
        case SettingsNotification.reset.name:
            if let group = group, let typeString = info[Keys.type] as? String, let type = ApplicationType(rawValue: typeString) {
                reset(group: group, for: type)
            }
        case SettingsNotification.hardReset.name:
            resetAll()
        default:
            return
        }
    }


    // MARK: Helpers

    private func resetAll() {
        let appStates = ConnectionManager.instance.states(for: .timeline).enumerated()
        let emptySelectionSet = Set<TimelineSelection>()
        let emptyIntSet = Set<Int>()

        for (app, _) in appStates {
            selectionForApp[app] = emptySelectionSet
            timeForHighlight[app] = [:]

            if app == appID {
                delegate?.replace(selection: emptySelectionSet)
                delegate?.replace(highlighted: emptyIntSet)
            }
        }
    }

    private func reset(group: Int, for type: ApplicationType) {
        let appStates = ConnectionManager.instance.states(for: .timeline).enumerated()
        let emptySelectionSet = Set<TimelineSelection>()
        let emptyIntSet = Set<Int>()

        for (app, _) in appStates {
            guard ConnectionManager.instance.typeForApp(id: app) == type else {
                return
            }

            if let groupForApp = ConnectionManager.instance.groupForApp(id: app, type: type), groupForApp != group {
                return
            }

            selectionForApp[app] = emptySelectionSet
            timeForHighlight[app] = [:]

            if app == appID {
                delegate?.replace(selection: emptySelectionSet)
                delegate?.replace(highlighted: emptyIntSet)
            }
        }
    }

    private func set(index: Int, group: Int?, selected: Bool, from id: Int) {
        let appStates = ConnectionManager.instance.states(for: .timeline).enumerated()
        let selection = TimelineSelection(index: index, app: id)

        for (app, state) in appStates {
            // Check if same group
            if state.group == group, selected {
                selectionForApp[app].insert(selection)
                if app == appID {
                    delegate?.handle(item: index, selected: selected)
                }
            } else if !selected, selectionForApp[app].contains(where: { $0.app == id && $0.index == index }) {
                selectionForApp[app].remove(selection)
                if app == appID {
                    delegate?.handle(item: index, selected: selected)
                }
            }
        }
    }

    private func setHighlight(index: Int, group: Int?) {
        let appStates = ConnectionManager.instance.states(for: .timeline).enumerated()

        for (app, state) in appStates {
            // Check if same group
            if state.group == group {
                timeForHighlight[app]![index] = Constants.highlightDuration
                if app == appID {
                    delegate?.handle(items: [index], highlighted: true)
                }
            }
        }
    }

    private func highlightTimerFired() {
        let time = CVGetCurrentHostTime() / UInt64(CVGetHostClockFrequency())
        if time != currentTime {
            decrementHighlightDuration()
            currentTime = time
        }
    }

    private func decrementHighlightDuration() {
        var itemsToSet = Set<Int>()
        for (app, appTimes) in timeForHighlight {
            for (index, time) in appTimes {
                let newTime = time - 1
                if newTime <= 0 {
                    timeForHighlight[app]!.removeValue(forKey: index)
                    if app == appID {
                        itemsToSet.insert(index)
                    }
                } else {
                    timeForHighlight[app]![index] = newTime
                }
            }
        }

        if !itemsToSet.isEmpty {
            delegate?.handle(items: itemsToSet, highlighted: false)
        }
    }
}
