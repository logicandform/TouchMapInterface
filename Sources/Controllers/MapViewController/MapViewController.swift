//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MapKit
import MONode
import PromiseKit
import AppKit
import MacGestures


struct MapConstants {
    static let canadaRect = MKMapRect(origin: MKMapPoint(x: 23000000, y: 25000000), size: MKMapSize(width: 160000000, height: 0))
}


class MapViewController: NSViewController, MKMapViewDelegate, GestureResponder, NSGestureRecognizerDelegate {
    static let storyboard = "Map"

    @IBOutlet private weak var mapView: CustomMapView!

    var gestureManager: GestureManager!
    private var annotationForTouch = [Touch: MKAnnotation]()
    private var currentTextScale: CGFloat = 1
    private var initialized = false

    private struct Constants {
        static let maxZoomWidth = MapConstants.canadaRect.size.width
        static let minZoomWidth = 424500.0
        static let annotationHitSize = CGSize(width: 40, height: 40)
        static let doubleTapScale = 0.5
        static let spacingBetweenAnnotations = 0.008
        static let coordinateToMapPointOriginOffset = 180.0
        static let animationDuration = 0.5
        static let recordWindowOffset: CGFloat = 20
        static let mapTitleUpdateThreshold = 10000000.0
        static let indicatorRadius: CGFloat = 4
        static let indicatorColor = NSColor.white
    }


    // MARK: Init

    static func instance() -> MapViewController {
        let storyboard = NSStoryboard(name: MapViewController.storyboard, bundle: nil)
        return storyboard.instantiateInitialController() as! MapViewController
    }


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = GestureManager(responder: self)
        TouchManager.instance.mapGestureManager = gestureManager
        gestureManager.touchReceived = { [weak self] touch in
            self?.displayIndicator(for: touch)
        }

        setupMap()
        setupGestures()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        if !initialized {
            // TODO: Set map to initial position
            initialized = true
        }
    }


    // MARK: API

    func fade(out: Bool) {
        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            view.animator().alphaValue = out ? 0 : 1
        })
    }


    // MARK: Setup

    private func setupMap() {
        if let tilesPath = Configuration.customMBTilesPath, let overlay = MBXMBTilesOverlay(mbTilesPath: tilesPath) {
            overlay.canReplaceMapContent = true
            mapView.addOverlay(overlay)
        }
        addRecordsToMap()
    }

    private func setupGestures() {
        let tapGesture = MultiTapGestureRecognizer()
        gestureManager.add(tapGesture, to: mapView)
        tapGesture.touchUpdated = { [weak self] touch, state in
            self?.didTapOnMap(touch, state: state)
        }

        let pinchGesture = PinchGestureRecognizer()
        gestureManager.add(pinchGesture, to: mapView)
        pinchGesture.gestureUpdated = { [weak self] gesture in
            self?.didPinchOnMap(gesture)
        }
    }


    // MARK: Gesture handling

    private func didPinchOnMap(_ gesture: GestureRecognizer) {
        guard let pinch = gesture as? PinchGestureRecognizer else {
            return
        }

        switch pinch.state {
        case .recognized, .momentum:
            var mapRect = mapView.visibleMapRect
            let scaledWidth = (2 - Double(pinch.scale)) * mapRect.size.width
            let scaledHeight = (2 - Double(pinch.scale)) * mapRect.size.height
            var translationX = -Double(pinch.delta.dx) * mapRect.size.width / Double(mapView.frame.width)
            var translationY = Double(pinch.delta.dy) * mapRect.size.height / Double(mapView.frame.height)
            if scaledWidth >= Constants.minZoomWidth && scaledWidth <= Constants.maxZoomWidth {
                translationX += (mapRect.size.width - scaledWidth) * Double(pinch.center.x / mapView.frame.width)
                translationY += (mapRect.size.height - scaledHeight) * (1 - Double(pinch.center.y / mapView.frame.height))
                mapRect.size = MKMapSize(width: scaledWidth, height: scaledHeight)
            }
            mapRect.origin += MKMapPoint(x: translationX, y: translationY)
            mapView.setVisibleMapRect(mapRect, animated: false)
        default:
            return
        }
    }

    private func didTapOnMap(_ touch: Touch, state: GestureState) {
        switch state {
        case .began:
            let sortedAnnotations = mapView.annotations.sorted(by: { $0 is MKClusterAnnotation && !($1 is MKClusterAnnotation) })
            for annotation in sortedAnnotations {
                let positionInView = mapView.convert(annotation.coordinate, toPointTo: mapView).inverted(in: mapView)
                let hitRadius = Constants.annotationHitSize.width / 2
                let annotationRect = CGRect(origin: CGPoint(x: positionInView.x - hitRadius, y: positionInView.y - hitRadius), size: Constants.annotationHitSize)
                if annotationRect.contains(touch.position) {
                    if let annotationView = mapView.view(for: annotation) as? AnimatableAnnotation {
                        annotationView.grow()
                    }
                    annotationForTouch[touch] = annotation
                    return
                }
            }
        case .failed, .ended:
            if let annotation = annotationForTouch[touch] {
                if let annotationView = mapView.view(for: annotation) as? AnimatableAnnotation {
                    annotationView.shrink()
                }

                annotationForTouch.removeValue(forKey: touch)
                if state == .ended {
                    select(annotation: annotation)
                }
            }
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


    // MARK: NSGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: NSGestureRecognizer) -> Bool {
        return true
    }


    // MARK: MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let tileOverlay = overlay as? MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: tileOverlay)
        }

        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? RecordAnnotation {
            let annotationView = RecordAnnotationView(annotation: annotation, reuseIdentifier: RecordAnnotationView.identifier)
            annotationView.setTitle(scale: currentTextScale)
            return annotationView
        } else if let cluster = annotation as? MKClusterAnnotation {
            return ClusterAnnotationView(annotation: cluster, reuseIdentifier: ClusterAnnotationView.identifier)
        }

        return MKAnnotationView()
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let scale = textScale(for: mapView.visibleMapRect)
        if scale == currentTextScale {
            return
        }

        currentTextScale = scale
        let annotations = mapView.annotations
        for annotation in annotations {
            if let annotationView = mapView.view(for: annotation) as? RecordAnnotationView {
                annotationView.setTitle(scale: scale)
            }
        }
    }


    // MARK: Helpers

    private func select(annotation: MKAnnotation) {
        let annotationPosition = mapView.convert(annotation.coordinate, toPointTo: mapView).inverted(in: mapView)

        switch annotation {
        case let recordAnnotation as RecordAnnotation:
            let offsetPosition = CGPoint(x: annotationPosition.x, y: annotationPosition.y - Constants.recordWindowOffset)
            displayWindow(for: recordAnnotation.record, at: offsetPosition)
        case let clusterAnnotation as MKClusterAnnotation:
            let region = restrainSpan(for: clusterAnnotation.boundingCoordinateRegion())
            var newMapRect = MKMapRect(coordinateRegion: region).withPreservedAspectRatio(in: mapView)
            let translationX = (newMapRect.size.width / 2) - newMapRect.size.width * Double(annotationPosition.x / mapView.frame.width)
            let translationY = -newMapRect.size.height * (1 - Double(annotationPosition.y / mapView.frame.height))
            newMapRect.origin += MKMapPoint(x: translationX, y: translationY)
            mapView.setVisibleMapRect(newMapRect, animated: true)
        default:
            return
        }
    }

    private func addRecordsToMap() {
        let records = RecordManager.instance.allRecords()

        var adjustedRecords = [Record]()
        for record in records {
            if let adjustedRecord = adjustCoordinate(of: record, current: adjustedRecords) {
                adjustedRecords.append(adjustedRecord)
            }
        }

        addAnnotations(for: adjustedRecords)
    }

    private func adjustCoordinate(of record: Record, current records: [Record]) -> Record? {
        guard let coordinate = record.coordinate else {
            return nil
        }

        for next in records {
            guard let fixedCoordinate = next.coordinate else {
                continue
            }

            let latitudeConflict = coordinate.latitude + Double(Constants.spacingBetweenAnnotations) > fixedCoordinate.latitude && coordinate.latitude - Double(Constants.spacingBetweenAnnotations) < fixedCoordinate.latitude
            let longitudeConflict = coordinate.longitude + Double(Constants.spacingBetweenAnnotations) > fixedCoordinate.longitude && coordinate.longitude - Double(Constants.spacingBetweenAnnotations) < fixedCoordinate.longitude

            if latitudeConflict && longitudeConflict {
                record.coordinate!.latitude -= Double(Constants.spacingBetweenAnnotations)
                return adjustCoordinate(of: record, current: records)
            }
        }

        return record
    }

    private func addAnnotations(for records: [Record]) {
        records.forEach { record in
            if let coordinate = record.coordinate {
                let annotation = RecordAnnotation(coordinate: coordinate, record: record)
                mapView.addAnnotation(annotation)
            }
        }
    }

    /// Clamps the region span between the max and min zoom levels
    private func restrainSpan(for region: MKCoordinateRegion) -> MKCoordinateRegion {
        var restrainedRegion = region
        let maxLongSpan = MKMapPoint(x: Constants.maxZoomWidth, y: 0).coordinate.longitude + Constants.coordinateToMapPointOriginOffset
        let minLongSpan = MKMapPoint(x: Constants.minZoomWidth, y: 0).coordinate.longitude + Constants.coordinateToMapPointOriginOffset
        restrainedRegion.span.longitudeDelta = clamp(restrainedRegion.span.longitudeDelta, min: minLongSpan, max: maxLongSpan)

        return restrainedRegion
    }

    private func textScale(for mapRect: MKMapRect) -> CGFloat {
        let mapScalePercent = (mapRect.size.width - Constants.minZoomWidth) / (Constants.maxZoomWidth - Constants.minZoomWidth)
        let scaleFactor = (1 - mapScalePercent).rounded(toPlaces: 1)
        let clamped = clamp(scaleFactor, min: 0.4, max: 1)
        return CGFloat(clamped)
    }

    /// Displays a touch indicator at the given position
    private func displayIndicator(for touch: Touch) {
        let screen = NSScreen.at(position: touch.screen)
        let position = touch.position.transformed(to: screen.frame)
        let radius = Constants.indicatorRadius
        let frame = CGRect(origin: CGPoint(x: position.x - radius, y: position.y - radius), size: CGSize(width: 2*radius, height: 2*radius))
        let indicator = NSView(frame: frame)
        indicator.wantsLayer = true
        indicator.layer?.cornerRadius = radius
        indicator.layer?.masksToBounds = true
        indicator.layer?.backgroundColor = Constants.indicatorColor.cgColor
        view.addSubview(indicator)

        NSAnimationContext.runAnimationGroup({ _ in
            NSAnimationContext.current.duration = Constants.animationDuration
            indicator.animator().alphaValue = 0
            indicator.animator().frame.size = .zero
            indicator.animator().frame.origin = CGPoint(x: indicator.frame.origin.x + radius, y: indicator.frame.origin.y + radius)
        }, completionHandler: {
            indicator.removeFromSuperview()
        })
    }
}
