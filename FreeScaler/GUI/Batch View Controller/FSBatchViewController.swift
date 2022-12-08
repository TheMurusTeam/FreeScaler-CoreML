//
//  FSBatchViewController.swift
//  FreeScaler
//
//  Created by Hany El Imam on 15/10/22.
//

import Cocoa



let temporaryoutputBatchpath = NSTemporaryDirectory() + "batch/"


class FSImage : NSObject {
    @objc dynamic var path: String
    @objc dynamic var thumbnail: NSImage
    @objc dynamic var sizeString: String
    @objc dynamic var isUpscaling: Bool
    @objc dynamic var upscaled: Bool
    @objc dynamic var progr: Double {
        didSet {
            if progr > 8800 {
                progr = 10000
            }
        }
    }
    var image = NSImage() // original image
    @objc dynamic var upscaledImage : NSImage // upscaled image
    
    init(path: String,
         image:NSImage,
         thumbnail:NSImage,
         originalSize:NSSize) {
        self.path = path
        self.image = image
        self.upscaledImage = NSImage()
        self.thumbnail = thumbnail
        self.sizeString = "\(Int(originalSize.width))x\(Int(originalSize.height))"
        self.isUpscaling = false
        self.upscaled = false
        self.progr = 0
    }
}





class FSBatchViewController: NSViewController,NSSharingServicePickerDelegate, NSMenuDelegate {
    
    @objc dynamic var images = [FSImage]()
    @IBOutlet var imagesArrayController: NSArrayController!
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var progrview: NSView!
    
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var progrLabel: NSTextField!
    @IBOutlet weak var iprogress: NSProgressIndicator!
    
    
    @IBOutlet weak var btnUpscale: NSButton!
    @IBOutlet weak var btnClear: NSButton!
    @IBOutlet weak var btnShare: NSButton!
    @IBOutlet weak var btnANE: NSButton!
    @IBOutlet weak var btnStop: NSButton!
    @IBOutlet weak var popupModel: NSPopUpButton!
    
    @objc dynamic var upscalerIsRunning = Bool()
    var path = String()
    
    // MARK: Init
    
    convenience init(path: String) {
        self.init()
        self.path = path
        self.upscalerIsRunning = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnShare.isEnabled = false
        self.btnANE.state = useNeuralEngine ? .on : .off
        self.btnStop.isEnabled = false
        
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
        // progress view
        self.progrview.wantsLayer = true
        self.progrview.canDrawSubviewsIntoLayer = true
        self.progrview.layer?.cornerRadius = 16.0
        self.progrview.layer?.borderWidth = 1
        self.progrview.layer?.borderColor = NSColor.controlAccentColor.cgColor
        self.progrview.layer?.masksToBounds = true
        self.iprogress.startAnimation(nil)
        self.hideProgressView()
        // import images from folder
        self.importedNewFolder(selectedURL: URL(fileURLWithPath: self.path))
    }
    
    
    func hideProgressView() {
        self.progress.doubleValue = 0
        self.progress.isHidden = true
        self.progress.stopAnimation(nil)
        self.iprogress.isHidden = true
        self.iprogress.stopAnimation(nil)
        self.progrview.isHidden = true
    }
    
    func showProgressViewForImport() {
        self.progress.doubleValue = 0
        self.progress.isHidden = true
        self.progress.stopAnimation(nil)
        self.iprogress.isHidden = false
        self.iprogress.startAnimation(nil)
        self.progrview.isHidden = false
        self.progrLabel.stringValue = "Importing images..."
    }
    
    func showProgressViewForSaving() {
        self.progress.doubleValue = 0
        self.progress.isHidden = true
        self.progress.stopAnimation(nil)
        self.iprogress.isHidden = false
        self.iprogress.startAnimation(nil)
        self.progrview.isHidden = false
        self.progrLabel.stringValue = "Saving images..."
    }
    
    
    
    // MARK: IMPORT IMAGES FROM FOLDER
    
    func importedNewFolder(selectedURL:URL) {
        self.images = [FSImage]()
        self.imagesArrayController.content = nil
        self.showProgressViewForImport()
        
        DispatchQueue.global().async {
            
            var imagesHasBeenFound = false
            if let enumerator = FileManager.default.enumerator(at: selectedURL,
                                                               includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                                                               options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles],
                                                               errorHandler: nil) {
                enumerator.forEach { (url) in
                    guard let url = url as? URL else { return }
                    if url.isPNG || url.isJPEG {
                        imagesHasBeenFound = true
                        if let image = NSImage(contentsOf: url) {
                            if let imageInfo = imageInfoFromFile(image:image, to: NSSize(width: 241, height: 162)) {
                                DispatchQueue.main.async {
                                    // create FSImage object
                                    self.imagesArrayController.addObject(FSImage(path: url.relativePath,
                                                                                 image: image,
                                                                                 thumbnail: imageInfo.1, // thumbnail
                                                                                 originalSize: imageInfo.0)) // size
                                }
                            }
                        }
                        
                    }
                }
            }
            DispatchQueue.main.async {
                    if imagesHasBeenFound {
                        print("Imported \(self.images.count) images")
                    } else {
                        // NO IMAGE IMPORTED
                        let alert = NSAlert()
                        alert.messageText = "No images to import"
                        alert.runModal()
                        
                    }
                
                self.hideProgressView()
            }
            
        }
        
    }
    
    
    
    
    // MARK: REMOVE IMAGE FROM LIST
    
    @IBAction func deleteImage(_ sender: NSButton) {
        if !self.upscalerIsRunning {
            
            if let pathToDelete = sender.toolTip {
                self.images = self.images.filter {$0.path != pathToDelete}
            }
            
            if self.images.isEmpty {
                self.clickClearAll(sender)
            }
        }
    }
    
    
    func setMainControls(enabled:Bool) {
        self.btnANE.isEnabled = enabled
        self.btnClear.isEnabled = enabled
        self.btnUpscale.isEnabled = enabled
        self.popupModel.isEnabled = enabled
    }
    
    
    // MARK: STOP
    
    var upscaleStopped = false
    
    @IBAction func clickStop(_ sender: Any) {
        self.upscaleStopped = true
        self.btnStop.isEnabled = false
        self.setMainControls(enabled: true)
    }
    
    
    // MARK: - CLICK UPSCALE
    
    @IBAction func clickUpscale(_ sender: Any) {
        self.runBatchUpscale()
    }
    
    // called from toolbar button
    func runBatchUpscale() {
        self.setMainControls(enabled: false)
        self.btnStop.isEnabled = true
        self.upscalerIsRunning = true
        self.upscaleStopped = false
        
        // reset objects
        for img in self.images {
            img.isUpscaling = false
            img.upscaled = false
            img.upscaledImage = NSImage()
            img.progr = 0
        }
        
        // LOOP UPSCALE
        DispatchQueue.global().async {
            for img in self.images {
                // stop
                if self.upscaleStopped {
                    DispatchQueue.main.async {
                        self.upscalerIsRunning = false
                        self.btnStop.isEnabled = false
                        self.setMainControls(enabled: true)
                    }
                    return
                }
                DispatchQueue.main.async {
                    img.isUpscaling = true
                }
                // UPSCALE
                if let inputImage = NSImage(contentsOf: URL(fileURLWithPath: img.path)) {
                    //UpscalerML.shared.predict(with: inputImage)
                    if let upscaledImage = Upscaler.shared.upscale(image: inputImage) {
                        DispatchQueue.main.async {
                            img.upscaledImage = upscaledImage
                            img.isUpscaling = false
                            img.upscaled = true
                        }
                    }
                }
            }
            print("batch terminated")
            DispatchQueue.main.async {
                self.upscalerIsRunning = false
                self.btnStop.isEnabled = false
                self.setMainControls(enabled: true)
                // main share button
                if !self.images.filter({$0.upscaled == true}).isEmpty {
                    self.btnShare.isEnabled = true
                }
            }
        }
    }
    
    
    
    
    
    
    // MARK: Clear All
    
    @IBAction func clickClearAll(_ sender: Any) {
        (winCtrl["main"] as! FSMainWindowController).mainview.subviews.removeAll()
        (winCtrl["main"] as! FSMainWindowController).droplabelview.isHidden = false
        viewCtrl["batch"] = nil
    }
    
    
    
    // ****************************************************************
    
    
    // MARK: - MODELS POPUP BUTTON
    
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
    
    
    
    
    
    
    
    
    
    
    // ***************************************************************+
    
    
    
    // MARK: - PREVIEW
    
    @IBAction func clickPreview(_ sender: NSButton) {
        if let path = sender.toolTip {
            let images = self.images.filter({ $0.path == path })
            if images.count == 1 {
                let image = images[0]
                // print("preview image at \(path)")
                if image.upscaled {
                    winCtrl["preview"] = FSPreviewWindowController(windowNibName: "FSPreviewWindowController",
                                                                   inputPath: image.path,
                                                                   upscaledImage: image.upscaledImage)
                    (winCtrl["preview"] as? FSPreviewWindowController)?.window?.makeKeyAndOrderFront(nil)
                }
            }
        }
    }
    
    
    // MARK: - SAVE ALL IMAGES
    
    @IBAction func clickSaveButton(_ sender: NSButton) {
        var items = [NSImage]()
        for img in self.images {
            if img.upscaled {
                items.append(img.upscaledImage)
            }
        }
        
        let sharingPicker = NSSharingServicePicker(items: items)
        sharingPicker.delegate = self
        sharingPicker.show(relativeTo: NSZeroRect, of: sender, preferredEdge: .minY)
    }
    
    
    
    // MARK: SAVE SINGLE IMAGE
    
    var singleImagePath = String()
    
    // click save in collectionview item
    @IBAction func clickShareImage(_ sender: NSButton) {
        if let path = sender.toolTip {
            self.singleImagePath = path
            let images = self.images.filter({ $0.path == path })
            if images.count == 1 {
                let image = images[0]
                let items : [NSImage] = [image.upscaledImage]
                let sharingPicker = NSSharingServicePicker(items: items)
                sharingPicker.delegate = self
                sharingPicker.show(relativeTo: NSZeroRect, of: sender, preferredEdge: .minY)
                
            }
        }
    }
    
    // draw share menu
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        guard let image = NSImage(named: "Freescaler") else {
            return proposedServices
        }
        var share = proposedServices
        
        if items.count == 1 {
            print("save single image")
            let customService = NSSharingService(title: "Save Upscaled Image As...", image: image, alternateImage: image, handler: {
                if let image = items.first as? NSImage {
                    self.displaySavePanel(image:image)
                }
            })
            share.insert(customService, at: 0)
            
        } else {
            print("saving \(items.count) images")
            let customService = NSSharingService(title: "Save All Upscaled Images To Folder...", image: image, alternateImage: image, handler: {
                self.displaySavePanelForBatch()
            })
            share.insert(customService, at: 0)
        }
        
        /*
        let customService = NSSharingService(title: "Save As...", image: image, alternateImage: image, handler: {
            if items.count == 1 {
                print("save single image")
                if let image = items.first as? NSImage {
                    // action
                    self.displaySavePanel(image:image)
                }
            } else {
                print("saving \(items.count) images")
                self.displaySavePanelForBatch()
            }
            
        })
        */
        
        
        return share
    }
    
    // save panel for single batch image
    func displaySavePanel(image:NSImage) {
        let panel = NSSavePanel()
        // suggested file name
        let ipath = self.singleImagePath
        let url = NSURL(fileURLWithPath: ipath)
        if let filename = url.lastPathComponent {
            let filenoext = (filename as NSString).deletingPathExtension
            let proposedfilename = filenoext + "-UPSCALED" + ".png"
            panel.nameFieldStringValue = proposedfilename
        }
        
        panel.title = "Save image"
        panel.prompt = "Save Image"
        if panel.runModal().rawValue == 1 {
            if let path = panel.url?.path {
                writeImageToFile(path: path, image: image, format: .png)
            }
        }
        self.singleImagePath = String()
    }
    
    
    // save panel for all images
    func displaySavePanelForBatch() {
        let panel = NSOpenPanel()
        panel.canCreateDirectories = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Select a folder"
        panel.prompt = "Export All Images"
        if panel.runModal().rawValue == 1 {
            self.showProgressViewForSaving()
            self.btnShare.isEnabled = false
            self.setMainControls(enabled: false)
            if let path = panel.url?.path {
                DispatchQueue.global().async {
                    for image in self.images {
                        let url = NSURL(fileURLWithPath: image.path)
                        if let filename = url.lastPathComponent {
                            let filenoext = (filename as NSString).deletingPathExtension
                            let proposedfilename = filenoext + "-UPSCALED" + ".png"
                            writeImageToFile(path: "\(path)/\(proposedfilename)", image: image.upscaledImage, format: .png)
                        }
                    }
                    DispatchQueue.main.async {
                        self.hideProgressView()
                        self.btnShare.isEnabled = true
                        self.setMainControls(enabled: true)
                    }
                }
            }
            
        }
    }
    
    
    
}












// MARK: IMAGE THUMBNAIL

// get original size and thumbnail
func imageInfoFromFile(image:NSImage?, to size: NSSize) -> (NSSize,NSImage)? {
    if let photo = image {
        let originalSize = photo.size
        if originalSize.width > 3840 || originalSize.height > 2160 {
            return nil // image too big
        }
        let ratio = photo.size.width > photo.size.height ? size.width / photo.size.width : size.height / photo.size.height
        var rect = NSRect(origin: .zero, size: NSSize(width: photo.size.width * ratio, height: photo.size.height * ratio))
        rect.origin = NSPoint(x: (size.width - rect.size.width)/2, y: (size.height - rect.size.height)/2)
        let thumbnail = NSImage(size: size)
        thumbnail.lockFocus()
        photo.draw(in: rect,
                   from: NSRect(origin: .zero, size: photo.size),
                   operation: .copy, fraction: 1.0)
        thumbnail.unlockFocus()
        return (originalSize, thumbnail)
    }
    
    return nil
}


