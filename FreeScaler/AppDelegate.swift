//
//  AppDelegate.swift
//  FreeScaler
//
//  Created by Hany El Imam on 28/11/22.
//

import Cocoa

/*
 _____  ____     ___    ___  _____   __   ____  _        ___  ____
|     ||    \   /  _]  /  _]/ ___/  /  ] /    || |      /  _]|    \
|   __||  D  ) /  [_  /  [_(   \_  /  / |  o  || |     /  [_ |  D  )
|  |_  |    / |    _]|    _]\__  |/  /  |     || |___ |    _]|    /
|   _] |    \ |   [_ |   [_ /  \ /   \_ |  _  ||     ||   [_ |    \
|  |   |  .  \|     ||     |\    \     ||  |  ||     ||     ||  .  \
|__|   |__|\_||_____||_____| \___|\____||__|__||_____||_____||__|\_| 2
                                                                             
*/

// Version 2
// Upscaler for macOS
// developed by Hany El Imam
// and Davide Feroldi


// https://www.murusfirewall.com/freescaler
// https://github.com/TheMurusTeam/FreeScaler-CoreML
// info@murus.it


@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) { self.startFreeScaler() }
    func applicationWillTerminate(_ aNotification: Notification) {  }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return true }
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { return true }
}

