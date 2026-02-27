//
//  LaunchAgentManager.swift
//  configsync
//
//  Created by Noah on 2/27/26.
//

import Foundation

struct LaunchAgentManager {
    static let plistName = "com.configsync.agent.plist"
    
    static var launchAgentsURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
    }
    
    static var plistURL: URL {
        launchAgentsURL.appendingPathComponent(plistName)
    }
    
    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }
    
    static func install() {
        let appPath = Bundle.main.bundlePath
        
        let plistContent: [String: Any] = [
            "Label": "com.configsync.agent",
            "ProgramArguments": ["\(appPath)/Contents/MacOS/ConfigSync"],
            "RunAtLoad": true,
            "KeepAlive": false,
            "StandardOutPath": "/tmp/configsync.log",
            "StandardErrorPath": "/tmp/configsync.error.log"
        ]
        
        try? FileManager.default.createDirectory(at: launchAgentsURL, withIntermediateDirectories: true)
        
        let plistData = try? PropertyListSerialization.data(fromPropertyList: plistContent, format: .xml, options: 0)
        try? plistData?.write(to: plistURL)
        
        // Load the agent
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["load", plistURL.path]
        try? process.run()
    }
    
    static func uninstall() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["unload", plistURL.path]
        try? process.run()
        process.waitUntilExit()
        
        try? FileManager.default.removeItem(at: plistURL)
    }
}
