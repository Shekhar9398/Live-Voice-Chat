//
//  PermissionManager.swift
//  Live Voice Chat
//
//  Created by Mac on 16/04/26.
//

import Foundation
import Speech

final class PermissionManager {
    
    static func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    print("[PermissionManager]: User granted access for speech recognition")
                    continuation.resume(returning: true)
                    
                case .denied, .restricted, .notDetermined:
                    print("[PermissionManager]: Speech recognition not available")
                    continuation.resume(returning: false)
                    
                @unknown default:
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
}
