//
//  ChatBotViewModel.swift
//  Live Voice Chat

import SwiftUI
import Speech
import Combine

@MainActor
class ChatBotViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let speechService = SpeechToTextService()
    
    // MARK: - UI State
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Task
    private var transcriptionTask: Task<Void, Never>?
    
    // MARK: - Actions
    func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        transcript = ""
        errorMessage = nil
        
        transcriptionTask = Task {
            do {
                let isAuthorized = await PermissionManager.requestSpeechPermission()
                guard isAuthorized else {
                    throw RecognizerError.recognizerUnavailable
                }
                
                for try await text in speechService.startStreaming() {
                    self.transcript = text
                }
                
                // stream finished normally
                self.isRecording = false
                
            } catch is CancellationError {
                // ignore cancellation (user tapped stop)
                
            } catch {
                self.errorMessage = error.localizedDescription
                self.isRecording = false
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        transcriptionTask?.cancel()
        transcriptionTask = nil
        
        speechService.stopStreaming()
    }
}
