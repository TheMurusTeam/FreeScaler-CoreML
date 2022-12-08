//
//  FSMainWindowController.swift
//  FreeScaler
//
//  Created by Hany El Imam on 28/11/22.
//

import Cocoa
import AVFoundation


class FSMainWindowController: NSWindowController {

    @IBOutlet var waitwin: NSWindow!
    @IBOutlet weak var waitprogr: NSProgressIndicator!
    @IBOutlet weak var waitlabel: NSTextField!
    
    @IBOutlet weak var mainview: NSView!
    @IBOutlet weak var droplabelview: NSView!
    
    convenience init(windowNibName:String, info:[String:AnyObject]?) {
        self.init(windowNibName: windowNibName)
        // show main window
        NSApplication.shared.activate(ignoringOtherApps: true)
        self.window?.makeKeyAndOrderFront(nil)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        // set droplabelview
        self.droplabelview.wantsLayer = true
        self.droplabelview.canDrawSubviewsIntoLayer = true
        self.droplabelview.layer?.cornerRadius = 36.0
        self.droplabelview.layer?.borderWidth = 1
        self.droplabelview.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        self.droplabelview.layer?.masksToBounds = true
        // setup model at start
        print("setting up model at start...")
        self.setupModelFromPath(path: selectedModelPath)
        
    }
    
    
    // MARK: SetUp CoreML Model
    
    func setupModelFromPath(path:String) {
        // show wait window
        self.waitprogr.startAnimation(nil)
        self.waitlabel.stringValue = "Loading \(URL(fileURLWithPath: path).lastPathComponent) CoreML model, please wait..."
        self.window?.beginSheet(self.waitwin)
        
        // load model
        DispatchQueue.global().async {
            Upscaler.shared.setupModelFromPath(path: path)
            DispatchQueue.main.async {
                self.window?.endSheet(self.waitwin)
            }
        }
    }
    
    
    
    // MARK: Display single image
    
    func displaySingleImage(path:String,
                            image:NSImage) {
        self.droplabelview.isHidden = true
        self.mainview.subviews.removeAll()
        // create new single view controller
        viewCtrl["single"] = FSImageViewController(originalImage: image,
                                                   originalPath: path)
        // attach to main view
        let imageView = (viewCtrl["single"] as! FSImageViewController).view
        self.mainview.addSubview(imageView)
        applyConstraints(view: imageView, containerView: (self.mainview))
    }
    
    
    // MARK: Display batch view
    
    func displayBatchView(path:String) {
        self.droplabelview.isHidden = true
        self.mainview.subviews.removeAll()
        // create new single view controller
        viewCtrl["batch"] = FSBatchViewController(path: path)
        // attach to main view
        let imageView = (viewCtrl["batch"] as! FSBatchViewController).view
        self.mainview.addSubview(imageView)
        applyConstraints(view: imageView, containerView: (self.mainview))
    }
    
    
    // MARK: Display single movie
    
    func displayMovie(path:String) {
        self.droplabelview.isHidden = true
        self.mainview.subviews.removeAll()
        // create new single view controller
        viewCtrl["single"] = FSMovieViewController(originalPath: path)
        // attach to main view
        let imageView = (viewCtrl["single"] as! FSMovieViewController).view
        self.mainview.addSubview(imageView)
        applyConstraints(view: imageView, containerView: (self.mainview))
    }
    
    
    
    // MARK: Import Image from file
    
    @IBAction func clickImport(_ sender: Any) {
        let myFiledialog:NSOpenPanel = NSOpenPanel()
        myFiledialog.allowsMultipleSelection = false
        myFiledialog.canChooseDirectories = true
        myFiledialog.message = "Import image or folder"
        myFiledialog.runModal()
        
        if let url = myFiledialog.url {
            do {
                guard let typeID = try url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else { return }
                guard let supertypes = UTType(typeID)?.supertypes else { return }
             
                if url.isFolder == true {
                    // FOLDER
                    print("Folder")
                    importFolder(path: url.path)
                    
                } else {
                    // FILE
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
                        return
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    
    
}
