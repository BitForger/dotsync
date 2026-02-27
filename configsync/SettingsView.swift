//
//  SettingsView.swift
//  configsync
//
//  Created by Noah on 2/27/26.
//

import SwiftUI

struct SettingsView: View {
    @State private var filesToSync: [String] = SyncConfig.load().filesToSync
    @State private var newFile: String = ""
    @State private var launchAgentEnabled: Bool = LaunchAgentManager.isInstalled
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Files to Sync")
                .font(.headline)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(filesToSync.enumerated()), id: \.element) { index, file in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            
                            Text(file)
                                .font(.system(.body, design: .monospaced))
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            Spacer()
                            
                            Button(action: { removeFile(file) }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                            .help("Remove file")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        
                        if index < filesToSync.count - 1 {
                            Divider()
                                .padding(.leading, 12)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            }
            .frame(height: CGFloat(filesToSync.count * 37 + 16).clamped(to: 80...200))
            
            HStack {
                TextField("Add file path (e.g., ~/.zshrc)", text: $newFile)
                    .textFieldStyle(.roundedBorder)
                
                Button("Add") {
                    addFile()
                }
                .disabled(newFile.isEmpty)
            }
            
            Divider()
            
            GroupBox("Launch Agent") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Toggle("Start at Login", isOn: $launchAgentEnabled)
                            .toggleStyle(.switch)
                            .onChange(of: launchAgentEnabled) { _, newValue in
                                if newValue {
                                    LaunchAgentManager.install()
                                } else {
                                    LaunchAgentManager.uninstall()
                                }
                            }
                        
                        Spacer()
                        
                        if launchAgentEnabled {
                            Text("Installed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text("When enabled, ConfigSync will run in the background and sync your files automatically when you log in.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(4)
            }
            
            HStack {
                Button("Reset to Defaults") {
                    filesToSync = SyncConfig.defaultFiles
                    saveConfig()
                }
                
                Spacer()
                
                Button("Save") {
                    saveConfig()
                }
                .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 480)
    }
    
    func addFile() {
        guard !newFile.isEmpty else { return }
        filesToSync.append(newFile)
        newFile = ""
        saveConfig()
    }
    
    func removeFile(_ file: String) {
        filesToSync.removeAll { $0 == file }
        saveConfig()
    }
    
    func saveConfig() {
        var config = SyncConfig.load()
        config.filesToSync = filesToSync
        config.save()
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    SettingsView()
}
