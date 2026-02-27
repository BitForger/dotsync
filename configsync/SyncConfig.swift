//
//  SyncConfig.swift
//  configsync
//
//  Created by Noah on 2/27/26.
//


import Foundation

struct SyncConfig: Codable {
    var filesToSync: [String]
    var syncIntervalMinutes: Int
    
    static let defaultFiles = [
        "~/.zshrc",
        "~/.zprofile",
        "~/.gitconfig",
        "~/.vimrc",
        "~/.ssh/config"
    ]
    
    static var configURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("ConfigSync")
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder.appendingPathComponent("config.json")
    }
    
    static func load() -> SyncConfig {
        if let data = try? Data(contentsOf: configURL),
           let config = try? JSONDecoder().decode(SyncConfig.self, from: data) {
            return config
        }
        let defaultConfig = SyncConfig(filesToSync: defaultFiles, syncIntervalMinutes: 5)
        defaultConfig.save()
        return defaultConfig
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: SyncConfig.configURL)
        }
    }
}
