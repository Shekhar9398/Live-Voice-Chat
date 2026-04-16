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
    private var continuation: AsyncThrowingStream<String, Error>.Continuation?

    // MARK: - To Auto Detect Device Language
    init(localeIdentifier: String = Locale.current.identifier) {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }
}

// MARK: - Public API (Exposed Methods)
extension SpeechToTextService {

    func startStreaming() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation

            continuation.onTermination = { [weak self] _ in
                self?.reset()
            }

            do {
                try startRecognition(continuation: continuation)
            } catch {
                continuation.finish(throwing: error)
                reset()
            }
        }
    }

    /// Signals the end of user speech. The recognizer delivers the final
    /// result, after which the stream finishes naturally.
    func stopStreaming() {
        request?.endAudio()
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
    }
}

// MARK: - Core Logic for Streaming
private extension SpeechToTextService {

    func startRecognition(continuation: AsyncThrowingStream<String, Error>.Continuation) throws {
        guard let recognizer, recognizer.isAvailable else {
            throw RecognizerError.recognizerUnavailable
        }

        try configureAudioSession()

        let (audioEngine, request) = try Self.prepareEngine()
        self.audioEngine = audioEngine
        self.request = request

        self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                continuation.yield(result.bestTranscription.formattedString)

                if result.isFinal {
                    continuation.finish()
                    self.reset()
                    return
                }
            }

            if let error {
                continuation.finish(throwing: error)
                self.reset()
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
        continuation = nil

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}

// MARK: - Audio Setup
private extension SpeechToTextService {

    func configureAudioSession() throws {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
    }

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
    case permissionDenied
}
