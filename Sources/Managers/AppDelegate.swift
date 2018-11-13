//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


let style = Style()


struct Configuration {
    static let touchPort: UInt16 = 13001
    static let touchScreenPosition = 1
    static let touchScreen = TouchScreen.pct2485
    static let customMBTilesPath: String? = nil
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        TouchManager.instance.setupTouchSocket()
        RecordManager.instance.initialize()
        setupApplication()
    }


    // MARK: Helpers

    private func setupApplication() {
        let screen = NSScreen.at(position: Configuration.touchScreenPosition)
        let mapController = MapViewController.instance()
        let mapWindow = BorderlessWindow(frame: screen.frame, controller: mapController, level: style.mapWindowLevel)
        mapWindow.setFrame(screen.frame, display: true)
        mapWindow.makeKeyAndOrderFront(self)
    }
}
