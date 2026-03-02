//
//  LaunchAgentManager.swift
//  dotsync
//
//  Created by Noah on 2/27/26.
//

import Foundation
import ServiceManagement

struct LaunchAgentManager {
    
    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return legacyIsEnabled()
        }
    }
    
    static func enable() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
            } catch {
                print("Failed to enable login item: \(error)")
            }
        } else {
            legacyEnable()
        }
    }
    
    static func disable() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                print("Failed to disable login item: \(error)")
            }
        } else {
            legacyDisable()
        }
    }
    
    // MARK: - Legacy (macOS 12 and earlier)
    
    private static let plistName = "com.configsync.agent.plist"
    
    private static var launchAgentsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
    }
    
    private static var plistURL: URL {
        launchAgentsURL.appendingPathComponent(plistName)
    }
    
    private static func legacyIsEnabled() -> Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }
    
    private static func legacyEnable() {
        let appPath = Bundle.main.bundlePath
        
        let plistContent: [String: Any] = [
            "Label": "com.configsync.agent",
            "ProgramArguments": ["\(appPath)/Contents/MacOS/ConfigSync"],
            "RunAtLoad": true,
            "KeepAlive": false
        ]
        
        try? FileManager.default.createDirectory(at: launchAgentsURL, withIntermediateDirectories: true)
        
        if let plistData = try? PropertyListSerialization.data(fromPropertyList: plistContent, format: .xml, options: 0) {
            try? plistData.write(to: plistURL)
        }
        
        Process.launchedProcess(launchPath: "/bin/launchctl", arguments: ["load", plistURL.path])
    }
    
    private static func legacyDisable() {
        Process.launchedProcess(launchPath: "/bin/launchctl", arguments: ["unload", plistURL.path])
        try? FileManager.default.removeItem(at: plistURL)
    }
}
