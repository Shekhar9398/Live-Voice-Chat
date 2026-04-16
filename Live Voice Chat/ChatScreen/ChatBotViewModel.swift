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

    // MARK: - Callbacks
    /// Fired once the recognizer delivers its final result after `stopRecording()`.
    var onFinalTranscript: ((String) -> Void)?

    // MARK: - Actions
    func startRecording() {
        guard transcriptionTask == nil else { return }

        transcript = ""
        errorMessage = nil

        transcriptionTask = Task { [weak self] in
            guard let self else { return }

            defer {
                self.isRecording = false
                self.transcriptionTask = nil
            }

            let speechAuthorized = await PermissionManager.requestSpeechPermission()
            let micAuthorized = await PermissionManager.requestMicrophonePermission()

            guard speechAuthorized, micAuthorized else {
                self.errorMessage = "Microphone and speech permissions are required."
                return
            }

            self.isRecording = true

            do {
                for try await text in self.speechService.startStreaming() {
                    self.transcript = text
                }
            } catch is CancellationError {
                // user cancelled — nothing to report
            } catch {
                self.errorMessage = error.localizedDescription
            }

            let finalText = self.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            self.transcript = ""
            if !finalText.isEmpty {
                self.onFinalTranscript?(finalText)
            }
        }
    }

    /// Tells the recognizer the user has stopped speaking. The task continues
    /// until the recognizer delivers its final result, then fires
    /// `onFinalTranscript`.
    func stopRecording() {
        guard isRecording else { return }
        speechService.stopStreaming()
    }
}
