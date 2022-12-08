//
//  DropView.swift
//  FreeScaler
//
//  Created by Hany El Imam on 28/11/22.
//

import Foundation
import AVFoundation
import Cocoa


class DropView: NSView {

    let mycolor : CGColor = CGColor.clear
    let tcolor : CGColor = CGColor(gray: 0.0, alpha: 0.3)

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        //self.wantsLayer = true
        //self.layer?.backgroundColor = NSColor.gray.cgColor
        registerForDraggedTypes([NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.fileURL])
    } 

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("dragging entered")
        self.layer?.backgroundColor = self.tcolor
        // Drag only one item
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = pasteboard[0] as? String
        else { return NSDragOperation() }
        
        // FILTER
        if pasteboard.count == 1 {
            return .copy
            /*
            if URL(fileURLWithPath: path).isPNG || URL(fileURLWithPath: path).isJPEG || URL(fileURLWithPath: path).isFolder {
                print("draggingEntered")
                return .copy
            }
            */
        }
        
        return NSDragOperation()
        
    }

   
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        print("draggingExited")
        self.layer?.backgroundColor = self.mycolor
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        print("draggingEnded")
        self.layer?.backgroundColor = self.mycolor
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray,
              let path = pasteboard[0] as? String
        else { return false }
        
        do {
            let url = URL(fileURLWithPath: path)
         
            guard let typeID = try url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else { return false }
            guard let supertypes = UTType(typeID)?.supertypes else { return false }
         
            if url.isFolder == true {
                // FOLDER
                print("import folder")
                importFolder(path: url.path)
            } else {
                // FILE
                if supertypes.contains(.image) {
                    print("Image file")
                    importImage(path: path)
                    return true
                } else if supertypes.contains(.movie) {
                    print("Video file")
                    importMovie(path: path)
                    return true
                } else {
                    print("Something else!")
                    return false
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return false
    }
}
