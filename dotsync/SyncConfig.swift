//
//  SyncConfig.swift
//  dotsync
//
//  Created by Noah on 2/27/26.
//


import Foundation

struct SyncConfig: Sendable {
    var filesToSync: [String]
    var syncIntervalMinutes: Int
    
    nonisolated static let defaultFiles = [
        "~/.zshrc",
        "~/.zprofile",
        "~/.gitconfig",
        "~/.vimrc",
        "~/.ssh/config"
    ]
    
    nonisolated static var configURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("DotSync")
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder.appendingPathComponent("config.json")
    }
    
    nonisolated static func load() -> SyncConfig {
        if let data = try? Data(contentsOf: configURL),
           let config = try? JSONDecoder().decode(SyncConfig.self, from: data) {
            return config
        }
        let defaultConfig = SyncConfig(filesToSync: self.defaultFiles, syncIntervalMinutes: 5)
        defaultConfig.save()
        return defaultConfig
    }
    
    nonisolated func save() {
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: SyncConfig.configURL)
        }
    }
}

// MARK: - Codable

nonisolated extension SyncConfig: Codable {}

