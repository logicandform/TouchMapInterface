//  Copyright © 2018 slant. All rights reserved.

import Foundation
import AppKit


final class Style {


    // MARK: General Properties

    let darkBackground = NSColor(srgbRed: 30/255, green: 33/255, blue: 35/255, alpha: 0.98)
    let darkBackgroundOpaque = NSColor(srgbRed: 17/255, green: 17/255, blue: 17/255, alpha: 1)
    let dragAreaBackground = NSColor(srgbRed: 30/255, green: 33/255, blue: 35/255, alpha: 0.98)
    let menuTintColor = NSColor(calibratedRed: 0, green: 0.90, blue: 0.70, alpha: 1)
    let touchIndicatorColor = NSColor.gray
    let defaultBorderColor = NSColor(white: 0.5, alpha: 1)
    let defaultBorderWidth: CGFloat = 1
    let defaultBorderZPosition: CGFloat = 20
    let windowHighlightWidth: CGFloat = 3
    let windowHighlightZPosition: CGFloat = 10


    // MARK: RecordType Colors

    let artifactColor = NSColor(srgbRed: 205/255, green: 33/255, blue: 54/255, alpha: 1)
    let schoolColor = NSColor(srgbRed: 7/255, green: 61/255, blue: 224/255, alpha: 1)
    let eventColor = NSColor(srgbRed: 228/255, green: 54/255, blue: 188/255, alpha: 1)
    let organizationColor = NSColor(srgbRed: 0/255, green: 159/255, blue: 75/255, alpha: 1)
    let collectionColor = NSColor(srgbRed: 229/255, green: 121/255, blue: 0/255, alpha: 1)
    let individualColor = NSColor.red
    let themeColor = NSColor(srgbRed: 0/255, green: 154/255, blue: 254/255, alpha: 1)


    // MARK: Window Levels

    let masterWindowLevel = NSWindow.Level.normal
    let nodeWindowLevel = NSWindow.Level(27)
    let mapWindowLevel = NSWindow.Level(28)
    let timelineWindowLevel = NSWindow.Level(29)
    let borderWindowLevel = NSWindow.Level(30)
    let recordWindowLevel = NSWindow.Level(31)
    let menuWindowLevel = NSWindow.Level(32)
    let touchIndicatorWindowLevel = NSWindow.Level(33)


    // MARK: Title Attributes

    var mapLabelAttributes: [NSAttributedString.Key: Any] {
        let fontSize: CGFloat = 26
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.maximumLineHeight = fontSize + 5
        paragraphStyle.lineBreakMode = .byWordWrapping
        let font = NSFont(name: "Soleil", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.white,
                .kern: 0.5
        ]
    }

    var clusterLabelAttributes: [NSAttributedString.Key: Any] {
        let fontSize: CGFloat = 14
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.maximumLineHeight = fontSize + 3
        let font = NSFont(name: "Soleil", size: fontSize) ?? NSFont.systemFont(ofSize: fontSize)
        return [.paragraphStyle: paragraphStyle,
                .font: font,
                .foregroundColor: NSColor.black,
                .kern: 0.5
        ]
    }
}
