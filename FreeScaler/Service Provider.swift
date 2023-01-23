//
//  Service Provider.swift
//  FreeScaler
//
//  Created by hany on 14/12/22.
//

import Foundation
import Cocoa
import AVFoundation

// /System/Library/CoreServices/pbs -flush

class ServiceProvider: NSObject {
    
    // SINGLE IMAGE
    
    @objc func serviceUpscale(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            if fileURLs.count == 1 {
                let url = fileURLs[0]
                do {
                    guard let typeID = try url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else { return }
                    guard let supertypes = UTType(typeID)?.supertypes else { return }
                 
                    if supertypes.contains(.image) {
                        print("Image file")
                        importImage(path: url.path)
                        return
                    } else if supertypes.contains(.movie) {
                        print("Video file")
                        importMovie(path: url.path)
                        return
                    } else {
                        print("Something else!")
                        let alert = NSAlert()
                        alert.messageText = "Unable to import"
                        alert.informativeText = "File format not supported"
                        alert.runModal()
                        return
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    
    // BATCH
    
    @objc func serviceBatchUpscale(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>) {
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            if fileURLs.count == 1 {
                let url = fileURLs[0]
                if !url.isFolder {
                    // unsupported file format
                    let alert = NSAlert()
                    alert.messageText = "Unable to import"
                    alert.informativeText = "File format not supported"
                    alert.runModal()
                    return
                } else {
                    // import all images in a folder
                    importFolder(path: url.path)
                }
                
            }
        }
    }
}
