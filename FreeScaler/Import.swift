//
//  Import.swift
//  FreeScaler
//
//  Created by Hany El Imam on 28/11/22.
//

import Foundation
import Cocoa


func importImage(path:String) {
    if let image = NSImage(contentsOf: URL(fileURLWithPath: path)) {
        // CHECK IMAGE SIZE
        if image.size.width > 3840 || image.size.height > 2160 {
            // ERROR, TOO BIG
            let alert = NSAlert()
            alert.messageText = "Unable to import image"
            alert.informativeText = "Image is too big. Maximum allowed size is 3840x2160."
            alert.runModal()
        } else {
            // DISPLAY IMAGE VIEW
            (winCtrl["main"] as? FSMainWindowController)?.displaySingleImage(path:path,
                                                                             image:image)
        }
    } else {
        // ERROR, NOT AN IMAGE
        let alert = NSAlert()
        alert.messageText = "Unable to import image"
        alert.informativeText = "Unknown image format"
        alert.runModal()
    }
}



func importFolder(path:String) {
    (winCtrl["main"] as? FSMainWindowController)?.displayBatchView(path:path)
}



func importMovie(path:String) {
    (winCtrl["main"] as? FSMainWindowController)?.displayMovie(path:path)
}
