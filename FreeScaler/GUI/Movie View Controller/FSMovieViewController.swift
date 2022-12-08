//
//  FSMovieViewController.swift
//  FreeScaler
//
//  Created by Hany El Imam on 29/11/22.
//

import Foundation
import AVFoundation
import AVKit
import CoreMedia
import AppKit

class FSMovieViewController: NSViewController {

    var originalPath = String()
    var asset : AVURLAsset? = nil
    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var btnUpscale: NSButton!
    @IBOutlet weak var btnClear: NSButton!
   // @IBOutlet weak var btnShare: NSButton!
   // @IBOutlet weak var btnANE: NSButton!
    @IBOutlet weak var popupModel: NSPopUpButton!
    @IBOutlet weak var progrview: NSView!
    
    
    
    // MARK: Init
    
    convenience init(originalPath: String) {
        self.init()
        self.originalPath = originalPath
        self.asset = AVURLAsset(url: URL(fileURLWithPath: self.originalPath))
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.progrview.isHidden = true
        let player = AVPlayer(playerItem: .init(asset: self.asset!))
            playerView.player = player
        
        // setup model popup button
        self.populateModelPopupButton()
        let currentModelURL = URL(fileURLWithPath: selectedModelPath)
        for item in self.popupModel.itemArray {
            if item.representedObject as? URL == currentModelURL {
                self.popupModel.select(item)
            }
        }
        
        // model popup update when importing a new custom CoreML model
        notificationcenter.addObserver(self, selector: #selector(self.updateModelPopupAndSetupNewModel(_:)), name: NSNotification.Name(rawValue:"newcustommodel"), object: nil)
    }
    
    
    // MARK: Clear
    
    @IBAction func clickClearAll(_ sender: Any) {
        (winCtrl["main"] as! FSMainWindowController).mainview.subviews.removeAll()
        (winCtrl["main"] as! FSMainWindowController).droplabelview.isHidden = false
        viewCtrl["single"] = nil
    }
    
   
    // MARK: MODELS POPUP BUTTON
    
    func menuWillOpen(_ menu: NSMenu) {
        if menu == self.popupModel.menu {
            self.populateModelPopupButton()
        }
    }
    
    
    // MARK: Update Popup and Setup new custom model
    
    // called when importing a custom model
    @objc func updateModelPopupAndSetupNewModel(_ note:Notification) {
        if let dict = note.userInfo as? [String:String] {
            if let name = dict["title"] {
                self.populateModelPopupButton()
                DispatchQueue.main.async {
                    self.popupModel.selectItem(withTitle: name)
                    print("updating models popup selecting item \(name)")
                    let item = self.popupModel.item(withTitle: name)
                    if let url = item?.representedObject as? URL {
                        selectedModelPath = url.path
                    }
                    
                    // setup imported model
                    if let modelurl = self.popupModel.selectedItem?.representedObject as? URL {
                        (winCtrl["main"] as! FSMainWindowController).setupModelFromPath(path: modelurl.path)
                    }
                }
            }
        }
    }
    
    
    // MARK: Populate Model Popup
    
    func populateModelPopupButton() {
        if let menu = self.popupModel.menu {
            print("populate popup")
            let selectedItemtitle = self.popupModel.selectedItem?.title
            // clear menu
            menu.removeAllItems()
            // add realesrgan512
            let item1 = NSMenuItem()
            item1.title = "Photo (Real-ESRGAN)"
            item1.representedObject = URL(fileURLWithPath: Bundle.main.path(forResource: "realesrgan512", ofType: "mlmodelc")!)
            menu.addItem(item1)
            // add realesrganAnime512
            let item2 = NSMenuItem()
            item2.title = "Anime (Real-ESRGAN)"
            item2.representedObject = URL(fileURLWithPath: Bundle.main.path(forResource: "realesrganAnime512", ofType: "mlmodelc")!)
            menu.addItem(item2)
            // custom models
            let customModelsURLs = installedCustomModels()
            if !customModelsURLs.isEmpty {
                // add separator
                let separator = NSMenuItem.separator()
                menu.addItem(separator)
                // custom models title item
                let itemtitle = NSMenuItem()
                itemtitle.title = "Custom CoreML Models"
                menu.addItem(itemtitle)
                itemtitle.isEnabled = false
                // add custom models
                for modelURL in customModelsURLs {
                    let customitem = NSMenuItem()
                    customitem.title = modelURL.lastPathComponent
                    customitem.representedObject = modelURL
                    menu.addItem(customitem)
                }
            }
            // add separator
            let separator2 = NSMenuItem.separator()
            menu.addItem(separator2)
            // add 'import' item
            let importitem = NSMenuItem()
            importitem.title = "Import CoreML model from file..."
            importitem.representedObject = nil
            menu.addItem(importitem)
            //
            
            if let selectedItemtitle = selectedItemtitle {
                self.popupModel.selectItem(withTitle: selectedItemtitle)
                print("popup selectedItemtitle = \(selectedItemtitle)")
            } else {
                self.popupModel.selectItem(at: 0)
            }
            
        }
    }
    
    
    
    
    // MARK: Switch Model
    
    var lastSelectedModelItem : NSMenuItem? = nil
    
    @IBAction func switchPopupModel(_ sender: NSPopUpButton) {
        if let modelURL = sender.selectedItem?.representedObject as? URL {
            self.lastSelectedModelItem = sender.selectedItem
            selectedModelPath = modelURL.path
            // SETUP MODEL
            print("model url \(modelURL.path)")
            (winCtrl["main"] as! FSMainWindowController).setupModelFromPath(path: modelURL.path)
            
        } else if sender.selectedItem?.representedObject == nil {
            // IMPORT CUSTOM MODEL
            print("import CoreML model...")
            importModel()
            if let lastitem = self.lastSelectedModelItem {
                self.popupModel.selectItem(withTitle: lastitem.title)
            } else {
                self.popupModel.selectItem(at: 0)
            }
        }
    }
    
    
    
    
    // MARK: Switch Neural Engine
    
    @IBAction func switchBtnANE(_ sender: NSButton) {
        useNeuralEngine = sender.state == .on
        (winCtrl["main"] as! FSMainWindowController).setupModelFromPath(path: selectedModelPath)
    }
    
    
    
    
    
    
    
    // MARK: Upscale
    
    @IBAction func clickUpscale(_ sender: Any) {
        self.progrview.isHidden = false
        self.timertime = 0
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.setTimer), userInfo: nil, repeats: true)
        
        let panel = NSSavePanel()
        panel.runModal()
        
        if let urloutput = panel.url {
            DispatchQueue.global().async {
                VideoConverter.shared.upscale(urlInput: URL(fileURLWithPath: self.originalPath),urlOutput: urloutput) { exit in
                    print("exit")
                    DispatchQueue.main.async {
                        self.timer.invalidate()
                        self.progrview.isHidden = true
                    }
                }
            }
        }
    }
    
    
    
    @IBOutlet weak var time: NSTextField!
    @IBOutlet weak var timelabel: NSTextField!
    @IBOutlet weak var totaltime: NSTextField!
    @IBOutlet weak var progr: NSProgressIndicator!
    
    @IBOutlet weak var speed: NSTextField!
    var timertime = 0
    var timer = Timer()
    @objc func setTimer() {
        timertime+=1
        DispatchQueue.main.async {
            self.time.intValue = Int32(self.timertime)
            // speed
            self.speed.doubleValue = ((self.timelabel.doubleValue / self.time.doubleValue) * 1000).rounded() / 1000
        }
    }
}
