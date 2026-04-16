//
//  SpeechToTextService.swift
//  Live Voice Chat
//

import AVFoundation
import Speech

final class SpeechToTextService {
    
    // MARK: - Dependencies
    private let recognizer: SFSpeechRecognizer?
    
    // MARK: - State
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    
    private var accumulatedText: String = ""
    
    // MARK: - To Auto Detect Device Language
    init(localeIdentifier: String = Locale.current.identifier) {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }
}

// MARK: - Public API (Exposed Methods)
extension SpeechToTextService {
    
    func startStreaming() -> AsyncThrowingStream<String, Error> {
        transcribe()
    }
    
    func stopStreaming() {
        reset()
    }
}

// MARK: - Core Logic for Streaming
private extension SpeechToTextService {
    
    func transcribe() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let (audioEngine, request) = try Self.prepareEngine()
                    self.audioEngine = audioEngine
                    self.request = request
                    
                    guard let recognizer = self.recognizer,
                          recognizer.isAvailable else {
                        throw RecognizerError.recognizerUnavailable
                    }
                    
                    self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                        guard let self else { return }
                        
                        if let error {
                            continuation.finish(throwing: error)
                            self.reset()
                            return
                        }
                        
                        if let result {
                            let newText = result.bestTranscription.formattedString
                            
                            continuation.yield(self.accumulatedText + newText)
                            
                            if result.isFinal {
                                self.accumulatedText += newText + " "
                                continuation.finish()
                                self.reset()
                            }
                        }
                    }
                    
                } catch {
                    continuation.finish(throwing: error)
                    self.reset()
                }
            }
        }
    }
    
    func reset() {
        task?.cancel()
        task = nil
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        request = nil
        accumulatedText = ""
    }
}

// MARK: - Audio Setup
private extension SpeechToTextService {
    
    static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        
        request.shouldReportPartialResults = true
        
        let node = audioEngine.inputNode
        let format = node.outputFormat(forBus: 0)
        
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
}

// MARK: - Errors
enum RecognizerError: Error {
    case recognizerUnavailable
}
