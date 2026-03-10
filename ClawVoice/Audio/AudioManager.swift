import AVFoundation
import Foundation

/// Handles microphone capture (PCM 16kHz) and speaker playback (PCM 24kHz).
final class AudioManager {

    // MARK: - Types

    typealias AudioChunkHandler = (Data) -> Void

    // MARK: - Properties

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                             sampleRate: 24000,
                                             channels: 1,
                                             interleaved: true)!
    private var inputFormat: AVAudioFormat?
    private var chunkHandler: AudioChunkHandler?
    private var isCapturing = false

    // MARK: - Public API

    func startCapture(onChunk: @escaping AudioChunkHandler) throws {
        guard !isCapturing else { return }
        chunkHandler = onChunk

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord,
                                mode: .voiceChat,
                                options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        let inputNode = engine.inputNode
        let hwFormat  = inputNode.outputFormat(forBus: 0)
        inputFormat   = hwFormat

        // Target capture format: 16kHz mono Int16
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                         sampleRate: 16000,
                                         channels: 1,
                                         interleaved: true)!

        // Install a converter tap
        guard let converter = AVAudioConverter(from: hwFormat, to: targetFormat) else {
            throw AudioError.converterInitFailed
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hwFormat) { [weak self] buffer, _ in
            guard let self else { return }

            let frameCapacity = AVAudioFrameCount(
                Double(buffer.frameLength) * 16000.0 / hwFormat.sampleRate
            )
            guard let converted = AVAudioPCMBuffer(pcmFormat: targetFormat,
                                                   frameCapacity: frameCapacity) else { return }
            var error: NSError?
            converter.convert(to: converted, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            if error == nil, converted.frameLength > 0 {
                let data = Data(bytes: converted.int16ChannelData![0],
                                count: Int(converted.frameLength) * 2)
                self.chunkHandler?(data)
            }
        }

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: outputFormat)
        engine.prepare()
        try engine.start()
        playerNode.play()
        isCapturing = true
    }

    func stopCapture() {
        guard isCapturing else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        playerNode.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
        isCapturing = false
    }

    /// Enqueue a chunk of PCM Int16 24kHz audio for playback.
    func playAudio(_ data: Data) {
        guard let buffer = pcmBuffer(from: data) else { return }
        playerNode.scheduleBuffer(buffer)
        if !playerNode.isPlaying { playerNode.play() }
    }

    // MARK: - Private helpers

    private func pcmBuffer(from data: Data) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(data.count / 2)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCount)
        else { return nil }
        buffer.frameLength = frameCount
        data.withUnsafeBytes { ptr in
            guard let src = ptr.baseAddress else { return }
            memcpy(buffer.int16ChannelData![0], src, data.count)
        }
        return buffer
    }

    // MARK: - Errors

    enum AudioError: Error {
        case converterInitFailed
    }
}
