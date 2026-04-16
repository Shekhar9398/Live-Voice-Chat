//  PermissionManager.swift
//  Live Voice Chat
//  Created by Mac on 16/04/26.

import AVFoundation
import Speech

final class PermissionManager {
    
    // MARK: - Speech Recognition Permission
    static func requestSpeechPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                switch status {
                case .authorized:
                    print("[PermissionManager]: Speech recognition authorized")
                    continuation.resume(returning: true)
                    
                case .denied, .restricted, .notDetermined:
                    print("[PermissionManager]: Speech recognition denied")
                    continuation.resume(returning: false)
                    
                @unknown default:
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    // MARK: - Microphone Permission
    static func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    print("[PermissionManager]: Microphone access granted")
                } else {
                    print("[PermissionManager]: Microphone access denied")
                }
                continuation.resume(returning: granted)
            }
        }
    }
    
}
