//
//  FSImageViewController.swift
//  FreeScaler
//
//  Created by Hany El Imam on 28/11/22.
//

import Cocoa

class FSImageViewController: NSViewController,
                             NSSplitViewDelegate,
                             NSSharingServicePickerDelegate,
                             NSMenuDelegate{

    
    @IBOutlet weak var splitview: NSSplitView!
    @IBOutlet weak var right: NSView!
    @IBOutlet weak var left: NSView!
    @IBOutlet weak var img_left: NSImageView!
    @IBOutlet weak var img_right: NSImageView!
    
    @IBOutlet weak var btnUpscale: NSButton!
    @IBOutlet weak var btnClear: NSButton!
    @IBOutlet weak var btnShare: NSButton!
    @IBOutlet weak var btnANE: NSButton!
    @IBOutlet weak var popupModel: NSPopUpButton!
    
    @IBOutlet weak var progrview: NSView!
    @IBOutlet weak var progr: NSProgressIndicator!
    
    var originalImage = NSImage()
    var upscaledImage : NSImage? = nil
    var originalPath = String()
    
    // MARK: Init
    
    convenience init(originalImage: NSImage,
                     originalPath: String) {
        self.init()
        self.originalImage = originalImage
        self.originalPath = originalPath
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.img_left.image = self.originalImage
        self.img_right.image = NSImage()
        self.collapseDivider()
        self.btnShare.isEnabled = false
        self.btnANE.state = useNeuralEngine ? .on : .off
        
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
    
    
    
    
    
    
    
    // MARK: MODELS POPUP BUTTON
    
    func menuWillOpen(_ menu: NSMenu) {
        if menu == self.popupModel.menu {
            self.lastSelectedModelItem = self.popupModel.selectedItem
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
            // add 'show dir' item
            let finderitem = NSMenuItem()
            finderitem.title = "Reveal custom model directory in Finder"
            finderitem.representedObject = "revealmodeldir"
            menu.addItem(finderitem)
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
        } else if sender.selectedItem?.representedObject as? String == "revealmodeldir" {
            // REVEAL MODEL DIR IN FINDER
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: customModelsPath).absoluteURL])
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
        UserDefaults.standard.set(useNeuralEngine, forKey: "useNeuralEngine")
        (winCtrl["main"] as! FSMainWindowController).setupModelFromPath(path: selectedModelPath)
    }
    
    
    

    
    
    // MARK: Split View Delegate
    
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {return true}
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {return true}
    
    // MARK: Control Split View Divider
    
    func collapseDivider() {
        //self.splitview.setPosition(self.view.frame.size.width, ofDividerAt: 0)
        self.splitview.setPosition((winCtrl["main"] as! FSMainWindowController).window!.frame.size.width, ofDividerAt: 0)
    }
    func centerDivider() {
        self.splitview.setPosition(self.view.frame.size.width / 2, ofDividerAt: 0)
    }
    
    // MARK: Upscale
    
    @IBAction func clickUpscale(_ sender: NSButton) {
        self.displayProgressView()
        DispatchQueue.global().async {
            if let image = Upscaler.shared.upscale(image: self.originalImage) {
                self.upscaledImage = image
                DispatchQueue.main.async {
                    self.img_right.image = self.upscaledImage
                    self.upscaledImage?.size = self.originalImage.size
                    self.centerDivider()
                    self.progrview.isHidden = true
                    self.btnShare.isEnabled = true
                }
            }
        }
    }
    
    func displayProgressView() {
        self.progrview.wantsLayer = true
        self.progrview.canDrawSubviewsIntoLayer = true
        self.progrview.layer?.cornerRadius = 16.0
        self.progrview.layer?.borderWidth = 1
        self.progrview.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        self.progrview.layer?.masksToBounds = true
        self.progrview.isHidden = false
        self.progr.startAnimation(nil)
    }
    
    
    // MARK: Clear
    
    @IBAction func clickClearAll(_ sender: Any) {
        (winCtrl["main"] as! FSMainWindowController).mainview.subviews.removeAll()
        (winCtrl["main"] as! FSMainWindowController).droplabelview.isHidden = false
        viewCtrl["single"] = nil
    }
    
    
    
    
    
    
    
    // MARK: - Share
    
    // draw share menu
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        guard let image = NSImage(named: "Freescaler") else {
            return proposedServices
        }
        var share = proposedServices
        let customService = NSSharingService(title: "Save Upscaled Image As...", image: image, alternateImage: image, handler: {
            if let upscaledImage = items.first as? NSImage {
                // action
                self.displaySavePanel(image:upscaledImage)
            }
        })
        share.insert(customService, at: 0)
        return share
    }
    
    
    
    // share or save output image
    @IBAction func clickSaveButton(_ sender: NSButton) {
        var items = [NSImage]()
        
        // SHARE SINGLE IMAGE
        if let image = self.upscaledImage {
            items = [image]
        }
        
        let sharingPicker = NSSharingServicePicker(items: items)
        sharingPicker.delegate = self
        sharingPicker.show(relativeTo: NSZeroRect, of: sender, preferredEdge: .minY)
    }
    
    
    // MARK: Save Panel
    
    // save panel for single image
    func displaySavePanel(image:NSImage) {
        let panel = NSSavePanel()
        // suggested file name
        let url = NSURL(fileURLWithPath: originalPath)
        if let filename = url.lastPathComponent {
            let filenoext = (filename as NSString).deletingPathExtension
            let proposedfilename = filenoext + "-UPSCALED" + ".png"
            panel.nameFieldStringValue = proposedfilename
        }
        // panel strings
        panel.title = "Save image"
        panel.prompt = "Save Image"
        if panel.runModal().rawValue == 1 {
            if let path = panel.url?.path {
                // write to file
                writeImageToFile(path: path,
                                 image: image,
                                 format: .png)
            }
        }
    }
}




// MARK: Write To File

func writeImageToFile(path:String,
                     image: NSImage,
                     format:NSBitmapImageRep.FileType) {
    let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!)
    if let imageData = imageRep?.representation(using: format, properties: [:]) {
        do {
            try imageData.write(to: URL(fileURLWithPath: path))
        }catch{}
    }
}
