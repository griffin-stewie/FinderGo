//
//  FinderSync.swift
//  FinderSyncExtension
//
//  Created by Khoa Pham on 13/03/2017.
//  Copyright © 2017 Fantageek. All rights reserved.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync, NSMenuDelegate {

  override init() {
    super.init()

    NSLog("FinderSync() launched from %@", Bundle.main.bundlePath as NSString)
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
  }

  var scriptsDirectoryURL: URL? {
    return try? FileManager.default.url(for: .applicationScriptsDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
  }

  func titles() -> [String] {
    guard let scriptsDirectoryURL = scriptsDirectoryURL else {
      NSLog("%@ %@", #function, "applicationScriptsDirectory does not exist");
      return []
    }

    let fs = FileManager.default
    guard let scriptsURLs = try? fs.contentsOfDirectory(at: scriptsDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]) else {
      NSLog("%@ %@", #function, "applicationScriptsDirectory contents does not exist");
      return []
    }

    let names = scriptsURLs.compactMap { (url) -> String? in
      guard url.pathExtension == "scpt" else {
        return nil
      }

      return url.deletingPathExtension().lastPathComponent
    }

    return names
  }

  // MARK: - Menu and toolbar item support

  override var toolbarItemName: String {
    return "FinderGo"
  }

  override var toolbarItemToolTip: String {
    return "FinderGo: Click the toolbar item for a menu."
  }

  override var toolbarItemImage: NSImage {
    return NSImage(named: "barIcon")!
  }

  override func menu(for menuKind: FIMenuKind) -> NSMenu {
    let menu = NSMenu(title: "")
    menu.delegate = self

    for title in titles().sorted() {
      menu.addItem(withTitle: title, action: #selector(open(_:)), keyEquivalent: "")
    }

    return menu
  }

  // MARK: - NSMenuDelegate

  func menuWillOpen(_ menu: NSMenu) {
    guard let targetedUrl = FIFinderSyncController.default().targetedURL() else {
      return
    }

    let board = NSPasteboard.general
    board.setString(targetedUrl.path, forType: NSPasteboard.PasteboardType.string)
  }

  // MARK: - Action
  @IBAction func open(_ sender: NSMenuItem) {
    run(fileName: sender.title)
  }

  // MARK: - Script

  func run(fileName: String) {
    guard let targetedUrl = FIFinderSyncController.default().targetedURL() else {
      return
    }

    let worker = ExtensionWorker(path: targetedUrl.path, fileName: fileName)
    worker.run()
  }
}

