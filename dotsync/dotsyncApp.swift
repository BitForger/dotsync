//
//  dotsyncApp.swift
//  dotsync
//
//  Created by Noah on 2/27/26.
//

import SwiftUI
import AppKit
import UserNotifications

@main
struct DotSyncApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var syncManager: SyncManager!
    var syncTimer: Timer?
    var settingsWindow: NSWindow?
    var windowCloseHandler: WindowCloseHandler?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request notification authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
        
        setupMenuBar()
        syncManager = SyncManager()
        startPeriodicSync()
        
        // Initial sync on launch
        Task {
            await syncManager.sync()
        }
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath.circle", accessibilityDescription: "DotSync")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Sync Now", action: #selector(syncNow), keyEquivalent: "s"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Open iCloud Folder", action: #selector(openICloudFolder), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.syncManager.sync()
            }
        }
    }
    
    @objc func syncNow() {
        Task {
            await syncManager.sync()
            showNotification(title: "DotSync", body: "Sync completed")
        }
    }
    
    @objc func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
        } else {
            let settingsView = SettingsView()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 420),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "DotSync Settings"
            window.contentView = NSHostingView(rootView: settingsView)
            window.center()
            window.isReleasedWhenClosed = false
            
            // Clear our reference when window closes
            let handler = WindowCloseHandler { [weak self] in
                self?.settingsWindow = nil
                self?.windowCloseHandler = nil
            }
            windowCloseHandler = handler
            window.delegate = handler
            
            settingsWindow = window
            window.makeKeyAndOrderFront(nil)
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openICloudFolder() {
        Task {
            if let url = await syncManager.iCloudContainerURL {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    @objc func installLaunchAgent() {
        LaunchAgentManager.install()
        showNotification(title: "DotSync", body: "Launch Agent installed. App will start on login.")
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
}

// Helper class to handle window close events
class WindowCloseHandler: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
        super.init()
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

