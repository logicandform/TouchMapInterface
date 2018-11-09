//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


let style = Style()


struct Configuration {
    static let serverURL = "http://localhost:3000"
    static let localMediaURLs = true
    static let touchScreenPosition = 1
    static let touchScreen = TouchScreen.pct2485
    static let customMBTilesPath: String? = "/Users/Tim/Xcode/UBC/CanadaShoreIceRoad.mbtiles"
    static let broadcastPort: UInt16 = 13001
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        RecordManager.instance.initialize { [weak self] in
            self?.setupApplication()
        }
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
