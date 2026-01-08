import Foundation
import Accelerate
import AVFoundation

class Tuner: ObservableObject {
    @Published var frequency: Float = 0.0
    @Published var note: String = "--"
    @Published var deviation: Float = 0.0 // Cents
    @Published var isTuning: Bool = false

    // Note frequencies
    private let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    // FFT Configuration
    private let sampleRate: Float = 44100.0
    private let bufferSize: Int = 4096

    func process(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let frames = Int(buffer.frameLength)

        // Use UnsafeBufferPointer to avoid array allocation
        let bufferPointer = UnsafeBufferPointer(start: channelDataValue, count: frames)

        // Find dominant frequency using Zero Crossing
        let freq = detectPitch(data: bufferPointer)

        if freq > 50 { // Filter out low rumble/noise
            let (detectedNote, detectedDeviation) = mapFrequencyToNote(frequency: freq)

            DispatchQueue.main.async {
                self.frequency = freq
                self.note = detectedNote
                self.deviation = detectedDeviation
                self.isTuning = true
            }
        } else {
             // Decay
             DispatchQueue.main.async {
                 self.isTuning = false
             }
        }
    }

    private func detectPitch(data: UnsafeBufferPointer<Float>) -> Float {
        // Simple Zero Crossing for now (Fallback)

        // 1. Simple Zero Crossing
        var zeroCrossings = 0
        var firstIndex: Int?
        var lastIndex: Int?
        var crossingCount = 0

        for i in 1..<data.count {
            if (data[i-1] < 0 && data[i] >= 0) {
                if firstIndex == nil { firstIndex = i }
                lastIndex = i
                crossingCount += 1
            }
        }

        if let first = firstIndex, let last = lastIndex, crossingCount > 1 {
            let distance = last - first
            let avgDistance = Float(distance) / Float(crossingCount - 1)
            return sampleRate / avgDistance
        }

        return 0.0
    }

    private func mapFrequencyToNote(frequency: Float) -> (String, Float) {
        // A4 = 440Hz
        // MIDI Note = 69 + 12 * log2(freq / 440)

        let midiNote = 69 + 12 * log2(frequency / 440.0)
        let roundedNote = Int(round(midiNote))

        let noteIndex = (roundedNote % 12)
        let name = noteNames[noteIndex >= 0 ? noteIndex : noteIndex + 12] // Handle negative wrap if any

        // Deviation in cents
        // 1 semitone = 100 cents
        let deviation = (midiNote - Float(roundedNote)) * 100

        return (name, deviation)
    }
}
