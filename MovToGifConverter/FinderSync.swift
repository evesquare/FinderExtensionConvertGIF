//
//  FinderSync.swift
//  MovToGifConverter
//
//  Created by evesquare on 2025/04/26.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    var myFolderURL = URL(fileURLWithPath: "/Users/Shared/MySyncExtension Documents")
    
    override init() {
        super.init()
        
        NSLog("FinderSync() launched from %@", Bundle.main.bundlePath as NSString)
        
        // Set up the directory we are syncing.
        FIFinderSyncController.default().directoryURLs = [self.myFolderURL]
        
        // Set up images for our badge identifiers. For demonstration purposes, this uses off-the-shelf images.
        FIFinderSyncController.default().setBadgeImage(NSImage(named: NSImage.colorPanelName)!, label: "Status One" , forBadgeIdentifier: "One")
        FIFinderSyncController.default().setBadgeImage(NSImage(named: NSImage.cautionName)!, label: "Status Two", forBadgeIdentifier: "Two")
    }
    
    // MARK: - Primary Finder Sync protocol methods
    
    override func beginObservingDirectory(at url: URL) {
        // The user is now seeing the container's contents.
        // If they see it in more than one view at a time, we're only told once.
        NSLog("beginObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    
    override func endObservingDirectory(at url: URL) {
        // The user is no longer seeing the container's contents.
        NSLog("endObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    override func requestBadgeIdentifier(for url: URL) {
        NSLog("requestBadgeIdentifierForURL: %@", url.path as NSString)
        
        // For demonstration purposes, this picks one of our two badges, or no badge at all, based on the filename.
        let whichBadge = abs(url.path.hash) % 3
        let badgeIdentifier = ["", "One", "Two"][whichBadge]
        FIFinderSyncController.default().setBadgeIdentifier(badgeIdentifier, for: url)
    }
    
    // MARK: - Menu and toolbar item support
    
    override var toolbarItemName: String {
        return "FinderSy"
    }
    
    override var toolbarItemToolTip: String {
        return "FinderSy: Click the toolbar item for a menu."
    }
    
    override var toolbarItemImage: NSImage {
        return NSImage(named: NSImage.cautionName)!
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        // メニューに新規追加
        let menu = NSMenu(title: "")
        let menuItem = NSMenuItem(title: "MOV to GIF", action: #selector(convertToGif(_:)), keyEquivalent: "")
        menu.addItem(menuItem)
        return menu
    }
    
    @IBAction func convertToGif(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs() else { return }
        
        for item in items {
            if item.pathExtension.lowercased() == "mov" {
                convertMovToGif(at: item)
            }
        }
        
    }
    
    func convertMovToGif(at url: URL) {
        NSLog("\(url.path)")
        
        // Create output file path with .gif extension
        let outputURL = url.deletingPathExtension().appendingPathExtension("gif")
        NSLog("\(outputURL.path)")
    
        
        // Create a process for running FFmpeg
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        
        // FFmpeg command to convert MOV to GIF with good quality
        let arguments = [
//            "-i", url.path,
//            "-vf", "fps=10,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse",
//            "-loop", "0",
//            outputURL.path
            "-c",
            "which ffmpeg"
        ]
        task.arguments = arguments
        
        // Setup error pipe to catch any issues
        let pipe = Pipe()
        task.standardError = pipe

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            // Check if conversion was successful
            if task.terminationStatus == 0 {
                // Show success notification
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outputData, encoding: .utf8) ?? ""
                print("標準出力: \(output)")
                NSLog("ok")
            } else {
                // Get error message
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let error = String(data: data, encoding: .utf8) ?? "Unknown error"
                
                // Log the error
                print("data: \(data)")
                print("FFmpeg Error: \(error)")
            }
        } catch {
            NSLog("実行エラー: \(error.localizedDescription)")
            showAlert(title: "エラー", message: "FFmpegの実行に失敗しました: \(error.localizedDescription)")
        }
    }
    
    // Helper function to show alert
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    @IBAction func sampleAction(_ sender: AnyObject?) {
        let target = FIFinderSyncController.default().targetedURL()
        let items = FIFinderSyncController.default().selectedItemURLs()
        
        let item = sender as! NSMenuItem
        NSLog("sampleAction: menu item: %@, target = %@, items = ", item.title as NSString, target!.path as NSString)
        for obj in items! {
            NSLog("    %@", obj.path as NSString)
        }
    }

}

