//
//  ChatBotViewModel.swift
//  Live Voice Chat

import SwiftUI
import Speech
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    
    // MARK: - State
    @Published var text: String = ""
    @Published var isRecording = false
    @Published var error: String?
    
    // MARK: - Dependencies
    private let speechService = SpeechService()
    private var task: Task<Void, Never>?
    
    var onFinalText: ((String) -> Void)?
    
    // MARK: - Actions
    func start() {
        guard task == nil else { return }
        
        text = ""
        error = nil
        
        task = Task {
            defer {
                isRecording = false
                task = nil
            }
            
            guard await hasPermissions() else {
                error = "Permissions required"
                return
            }
            
            isRecording = true
            
            do {
                for try await value in speechService.start() {
                    text = value
                }
                
                finish()
                
            } catch let speechError {
                error = speechError.localizedDescription
            }
        }
    }
    
    func stop() {
        speechService.stop()
    }
}

// MARK: - Helpers
private extension ChatViewModel {
    
    func hasPermissions() async -> Bool {
        let speech = await PermissionManager.requestSpeechPermission()
        let mic = await PermissionManager.requestMicrophonePermission()
        return speech && mic
    }
    
    func finish() {
        let final = text.trimmingCharacters(in: .whitespacesAndNewlines)
        text = ""
        
        if !final.isEmpty {
            onFinalText?(final)
        }
    }
}
