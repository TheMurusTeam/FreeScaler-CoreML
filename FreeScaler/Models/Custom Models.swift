//
//  Custom Models.swift
//  FreeScaler
//
//  Created by Hany El Imam on 30/11/22.
//

import Foundation
import Cocoa
import CoreML

let customModelsPath = "models" // /Users/hany/Library/Containers/it.murus.FreeScaler/Data/models/


// MARK: Import CoreML model from file

func importModel() {
    let panel = NSOpenPanel()
    panel.allowedFileTypes = ["com.apple.coreml.model"]
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.canCreateDirectories = false
    panel.runModal()
    if let url = panel.url {
        let filename = url.lastPathComponent
        createCustomModelsDirectoryIfNeeded()
        var temporaryModelURL : URL? = nil
        // compile model
        do {
            print("compiling model...")
            temporaryModelURL = try MLModel.compileModel(at: URL(fileURLWithPath: url.path))
        } catch {
            // error compiling model
            print("error compiling model")
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = "Cannot import model"
            alert.runModal()
            return
        }
        // install model
        if let tmpUrl = temporaryModelURL {
            print("installing model...")
            // copy custom model to FreeScaler custom models directory
            do {
                try FileManager.default.copyItem(at: tmpUrl,
                                                 to: URL(fileURLWithPath: "\(customModelsPath)/\(filename)"))
                notificationcenter.post(name: Notification.Name(rawValue: "newcustommodel"), object: nil, userInfo: ["title":filename])
                
            } catch { print("error installing model") }
            
        }
        
    }
}

func createCustomModelsDirectoryIfNeeded() {
    if !FileManager.default.fileExists(atPath: customModelsPath) {
        print("creating FreeScaler custom models directory")
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: customModelsPath), withIntermediateDirectories: true)
        } catch {}
    } else {
        print("custom models dir found")
    }
}




// MARK: Enumerate installed custom CoreML models

func installedCustomModels() -> [URL] {
    var urls = [URL]()
    do {
        let directoryContents = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: customModelsPath),includingPropertiesForKeys: nil)
        urls = directoryContents
    } catch {}
    return urls.filter{ $0.pathExtension == "mlmodelc" || $0.pathExtension == "mlmodel" }
}
