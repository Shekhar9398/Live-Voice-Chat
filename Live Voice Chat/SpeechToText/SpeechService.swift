//
//  SpeechService.swift
//

import AVFoundation
import Speech

final class SpeechService {
    private let speechRecognizer: SFSpeechRecognizer?

    init(language: String = Locale.current.identifier) {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: language))
    }

    // MARK: - State
    private var audioEngine: AVAudioEngine?
    private var audioRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
}

// MARK: - Public API
extension SpeechService {

    /// Start listening and get text updates as a stream
    func start() -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in

            continuation.onTermination = { [weak self] _ in
                self?.stopAndReset()
            }

            do {
                try startListening { text, isFinal in
                    continuation.yield(text)

                    if isFinal {
                        continuation.finish()
                    }
                }

            } catch {
                continuation.finish(throwing: error)
            }
        }
    }

    /// Stop listening manually
    func stop() {
        audioRequest?.endAudio()
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
    }
}

// MARK: - Core Logic
private extension SpeechService {

    func startListening(onUpdate: @escaping (String, Bool) -> Void) throws {

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechError.notAvailable
        }

        try setupAudioSession()

        let (engine, request) = try Self.createAudioSetup()
        self.audioEngine = engine
        self.audioRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                onUpdate(text, result.isFinal)

                if result.isFinal {
                    self.stopAndReset()
                }
            }

            if let error {
                print("Speech error:", error)
                self.stopAndReset()
            }
        }
    }

    func stopAndReset() {
        recognitionTask?.cancel()
        recognitionTask = nil

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        audioRequest = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Audio Setup
private extension SpeechService {

    func setupAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    static func createAudioSetup() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()

        request.shouldReportPartialResults = true

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        try engine.start()

        return (engine, request)
    }
}

// MARK: - Errors
enum SpeechError: Error {
    case notAvailable
}
