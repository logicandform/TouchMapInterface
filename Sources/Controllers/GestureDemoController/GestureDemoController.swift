//  Copyright © 2017 JABT. All rights reserved.

import MONode
import MacGestures


class GestureDemoController: NSViewController, SocketManagerDelegate, GestureResponder {
    static let storyboard = "Demo"
    static let config = NetworkConfiguration(broadcastHost: "10.58.73.255", nodePort: 13003)

    let socketManager = SocketManager(networkConfiguration: config)
    var gestureManager: GestureManager!
    var updateForTouch = [Touch: Bool]()
    var rect: NSView!

    static func instance() -> GestureDemoController {
        let storyboard = NSStoryboard(name: GestureDemoController.storyboard, bundle: .main)
        return storyboard.instantiateInitialController() as! GestureDemoController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        socketManager.delegate = self
        gestureManager = GestureManager(responder: self)
        view.wantsLayer = true
        view.layer?.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)

        rect = NSView(frame: CGRect(x: view.bounds.midX - 200, y: view.bounds.midY - 200, width: 400, height: 400))
        rect.wantsLayer = true
        rect.layer?.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        view.addSubview(rect)

        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: rect)
        tapGesture.gestureUpdated = rectTapped(_:)

        let panGesture = PanGestureRecognizer()
        gestureManager.add(panGesture, to: rect)
        panGesture.gestureUpdated = { [weak self] gesture in
            self?.rectPanned(gesture)
        }

        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: view)
        pinchGesture.gestureUpdated = rectPinched(_:)
    }


    // MARK: SocketManagerDelegate

    func handleError(_ message: String) {
        print("Socket error: \(message)")
    }

    func handlePacket(_ packet: Packet) {
        guard let touch = Touch(from: packet), shouldUpdate(touch) else {
            return
        }

        convertToScreen(touch)
        gestureManager.handle(touch)
    }


    // MARK: Gesture handling

    var big = false

    func rectTapped(_ gesture: GestureRecognizer) {
        big = !big
        let size = big ? CGSize(width: 800, height: 400) : CGSize(width: 400, height: 400)
        rect.animator().setFrameSize(size)
    }

    func rectPanned(_ gesture: GestureRecognizer) {
        guard let pan = gesture as? PanGestureRecognizer else {
            return
        }

        switch pan.state {
        case .recognized, .momentum:
            let newFrameOriginX = min(view.frame.origin.x + view.frame.width - rect.frame.width, max(view.frame.origin.x, rect.frame.origin.x + pan.delta.dx))
            let newFrameOriginY = min(view.frame.origin.y + view.frame.height - rect.frame.height, max(view.frame.origin.y, rect.frame.origin.y + pan.delta.dy))
            rect.frame.origin = CGPoint(x: newFrameOriginX, y: newFrameOriginY)
        default:
            return
        }
    }

    func rectPinched(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer else {
            return
        }

        switch pinch.state {
        case .recognized, .momentum:
            let width = max(300, rect.frame.size.width * pinch.scale)
            let height = max(300, min(view.frame.height, rect.frame.size.height * pinch.scale))
            var originX = min(view.frame.origin.x + view.frame.width - rect.frame.width, max(view.frame.origin.x, rect.frame.origin.x + pinch.delta.dx))
            var originY = min(view.frame.origin.y + view.frame.height - rect.frame.height, max(view.frame.origin.y, rect.frame.origin.y + pinch.delta.dy))
            originX += (rect.frame.width - width) / 2
            originY += (rect.frame.height - height) / 2

            rect.frame.origin = CGPoint(x: originX, y: originY)
            rect.frame.size = CGSize(width: width, height: height)
        default:
            return
        }
    }


    // MARK: GestureResponder

    func draggableInside(bounds: CGRect) -> Bool {
        return true
    }

    func subview(contains position: CGPoint) -> Bool {
        return true
    }


    // MARK: Helpers

    private func shouldUpdate(_ touch: Touch) -> Bool {
        switch touch.state {
        case .down:
            updateForTouch[touch] = false
        case .up:
            updateForTouch.removeValue(forKey: touch)
        case .moved:
            let update = updateForTouch[touch]!
            updateForTouch[touch] = !update
            return update
        }

        return true
    }

    /// Converts a position received from a touch screen to the coordinate of the current devices bounds.
    private func convertToScreen(_ touch: Touch) {
        guard let screen = NSScreen.screens.at(index: touch.screen) else {
            return
        }

        let xPos = (touch.position.x / Configuration.touchScreen.touchSize.width * CGFloat(screen.frame.width)) + screen.frame.origin.x
        let yPos = (1 - touch.position.y / Configuration.touchScreen.touchSize.height) * CGFloat(screen.frame.height)
        touch.position = CGPoint(x: xPos, y: yPos)
    }
}
