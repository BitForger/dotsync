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
        SMAppService.mainApp.status == .enabled
    }
    
    static func enable() {
        do {
            try SMAppService.mainApp.register()
        } catch {
            print("Failed to enable login item: \(error)")
        }
    }
    
    static func disable() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            print("Failed to disable login item: \(error)")
        }
    }
}
