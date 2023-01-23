//
//  Start.swift
//  FreeScaler
//
//  Created by Hany El Imam on 28/11/22.
//

import Foundation
import Cocoa


extension AppDelegate {
    
    func startFreeScaler() {
        NSLog("Starting FreeScaler")
        // read preferences
        /*
         selectedModelPath = (UserDefaults.standard.value(forKey: "selectedModelPath") as? String) ??
                                (Bundle.main.path(forResource: "realesrgan512", ofType: "mlmodelc")!)
        */
        useNeuralEngine = (UserDefaults.standard.value(forKey: "useNeuralEngine") as? Bool) ?? true
        // show main window
        winCtrl["main"] = FSMainWindowController(windowNibName: "FSMainWindowController", info: nil)
    }
    
    
   
}
