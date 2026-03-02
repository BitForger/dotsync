//
//  SyncManager.swift
//  dotsync
//
//  Created by Noah on 2/27/26.
//

import Foundation
import UserNotifications

actor SyncManager {
    let fileManager = FileManager.default
    var iCloudContainerURL: URL?
    
    private var config: SyncConfig
    private var hasCompletedFirstSync = false
    
    init() {
        self.config = SyncConfig.load()
        
        let home = fileManager.homeDirectoryForCurrentUser
        let iCloudDrive = home
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
            .appendingPathComponent("DotSync")
        
        self.iCloudContainerURL = iCloudDrive
        
        if !fileManager.fileExists(atPath: iCloudDrive.path) {
            try? fileManager.createDirectory(at: iCloudDrive, withIntermediateDirectories: true)
        }
    }
    
    func sync() async {
        self.config = SyncConfig.load()
        guard let cloudURL = iCloudContainerURL else {
            print("iCloud not available")
            return
        }
        
        var downloadedFiles: [String] = []
        
        for filePath in config.filesToSync {
            let expandedPath = NSString(string: filePath).expandingTildeInPath
            let localURL = URL(fileURLWithPath: expandedPath)
            let fileName = localURL.lastPathComponent
            let cloudFileURL = cloudURL.appendingPathComponent(fileName)
            
            let didDownload = await syncFile(localURL: localURL, cloudURL: cloudFileURL)
            if didDownload {
                downloadedFiles.append(fileName)
            }
        }
        
        // Notify on first sync completion or when downloads occur
        if !hasCompletedFirstSync {
            hasCompletedFirstSync = true
            await postNotification(body: "Initial sync complete")
        } else if !downloadedFiles.isEmpty {
            let body = downloadedFiles.count == 1
                ? "Downloaded \(downloadedFiles[0])"
                : "Downloaded \(downloadedFiles.count) files"
            await postNotification(body: body)
        }
    }
    
    private func syncFile(localURL: URL, cloudURL: URL) async -> Bool {
        print("Syncing file: \(localURL.path) -> \(cloudURL.path)")
        let localExists = fileManager.fileExists(atPath: localURL.path)
        let cloudExists = fileManager.fileExists(atPath: cloudURL.path)
        
        // Get file sizes - NEVER overwrite with empty file
        let localSize = (try? fileManager.attributesOfItem(atPath: localURL.path)[.size] as? Int) ?? 0
        let cloudSize = (try? fileManager.attributesOfItem(atPath: cloudURL.path)[.size] as? Int) ?? 0
        
        let localDate = (try? fileManager.attributesOfItem(atPath: localURL.path)[.modificationDate] as? Date) ?? Date.distantPast
        let cloudDate = (try? fileManager.attributesOfItem(atPath: cloudURL.path)[.modificationDate] as? Date) ?? Date.distantPast
        
        // SAFETY: Never overwrite a file with an empty one
        if localExists && localSize > 0 && (!cloudExists || cloudSize == 0) {
            // Local has content, cloud is empty/missing → Upload
            do {
                if cloudExists {
                    try fileManager.removeItem(at: cloudURL)
                }
                try fileManager.copyItem(at: localURL, to: cloudURL)
                print("✅ Uploaded: \(localURL.lastPathComponent)")
            } catch {
                print("❌ Upload failed: \(error.localizedDescription)")
            }
            return false
            
        } else if cloudExists && cloudSize > 0 && (!localExists || localSize == 0) {
            // Cloud has content, local is empty/missing → Download
            do {
                if localExists {
                    try fileManager.removeItem(at: localURL)
                }
                try fileManager.copyItem(at: cloudURL, to: localURL)
                print("✅ Downloaded: \(localURL.lastPathComponent)")
                return true
            } catch {
                print("❌ Download failed: \(error.localizedDescription)")
                return false
            }
            
        } else if localExists && cloudExists && localSize > 0 && cloudSize > 0 {
            // Both exist with content - compare dates
            if localDate > cloudDate {
                // Local is newer → Upload (backup cloud first)
                do {
                    let backupURL = cloudURL.appendingPathExtension("backup")
                    try? fileManager.removeItem(at: backupURL)
                    try fileManager.moveItem(at: cloudURL, to: backupURL)
                    try fileManager.copyItem(at: localURL, to: cloudURL)
                    print("✅ Updated cloud: \(localURL.lastPathComponent)")
                } catch {
                    print("❌ Cloud update failed: \(error.localizedDescription)")
                }
                return false
                
            } else if cloudDate > localDate {
                // Cloud is newer → Download (backup local first)
                var success = false
                do {
                    let backupURL = localURL.appendingPathExtension("backup")
                    try? fileManager.removeItem(at: backupURL)
                    try fileManager.moveItem(at: localURL, to: backupURL)
                    try fileManager.copyItem(at: cloudURL, to: localURL)
                    print("✅ Updated local: \(localURL.lastPathComponent)")
                    success = true
                } catch {
                    print("❌ Local update failed: \(error.localizedDescription)")
                    // Restore from backup if copy failed
                    let backupURL = localURL.appendingPathExtension("backup")
                    try? fileManager.moveItem(at: backupURL, to: localURL)
                }
                return success
            } else {
                print("⏭️ Skipped (same date): \(localURL.lastPathComponent)")
            }
        } else {
            print("⚠️ Skipped (both empty or missing): \(localURL.lastPathComponent)")
        }
        return false
    }
    
    private func postNotification(body: String) async {
        let content = UNMutableNotificationContent()
        content.title = "DotSync"
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
}
