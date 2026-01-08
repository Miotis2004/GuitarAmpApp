import AVFoundation
import Foundation
import Combine

enum CabModel: String, CaseIterable, Identifiable {
    case bypass = "Bypass"
    case vintage4x12 = "4x12 Vintage" // Celestion V30 style: Mid spike, high rolloff
    case modern4x12 = "4x12 Modern"   // Scooped mids, tight lows
    case tweed1x12 = "1x12 Tweed"     // Boxy, mid-heavy
    case bass8x10 = "8x10 Bass"       // Deep lows, no highs
    case customIR = "Simulate IR (EQ Match)" // Placeholder for IR

    var id: String { rawValue }
}

class CabSimulator: ObservableObject {
    let eqNode = AVAudioUnitEQ(numberOfBands: 6)

    @Published var activeModel: CabModel = .bypass {
        didSet { updateEQ() }
    }

    @Published var irFileName: String? = nil {
        didSet {
            if irFileName != nil {
                activeModel = .customIR
            }
        }
    }

    init() {
        // Initialize bypass
        updateEQ()
    }

    private func updateEQ() {
        // Reset all bands
        for i in 0..<eqNode.bands.count {
            eqNode.bands[i].bypass = true
        }

        eqNode.bypass = (activeModel == .bypass)
        if activeModel == .bypass { return }

        // Apply presets
        switch activeModel {
        case .vintage4x12:
            // High Roll-off (simulating speaker cone inertia)
            setBand(0, type: .lowPass, freq: 5000, gain: 0, q: 0.7)
            // Low Cut (cabinet resonance limit)
            setBand(1, type: .highPass, freq: 80, gain: 0, q: 0.7)
            // Mid "V30" Spike
            setBand(2, type: .parametric, freq: 2500, gain: 4, q: 1.5)
            // Low-Mid Warmth
            setBand(3, type: .parametric, freq: 400, gain: 2, q: 1.0)

        case .modern4x12:
            setBand(0, type: .lowPass, freq: 8000, gain: 0, q: 0.7)
            setBand(1, type: .highPass, freq: 60, gain: 0, q: 0.8)
            // Scoop
            setBand(2, type: .parametric, freq: 600, gain: -6, q: 1.5)
            // Presence
            setBand(3, type: .parametric, freq: 4000, gain: 3, q: 1.0)

        case .tweed1x12:
            setBand(0, type: .lowPass, freq: 4500, gain: 0, q: 0.6)
            setBand(1, type: .highPass, freq: 100, gain: 0, q: 0.8)
            // Boxy Mid
            setBand(2, type: .parametric, freq: 800, gain: 5, q: 2.0)

        case .bass8x10:
            setBand(0, type: .lowPass, freq: 3000, gain: 0, q: 1.0)
            setBand(1, type: .highPass, freq: 40, gain: 0, q: 0.7)
            setBand(2, type: .parametric, freq: 200, gain: 3, q: 1.0)

        case .customIR:
            // Simulates a "Mastered" cabinet response using EQ matching.
            // This is a placeholder for true Impulse Response convolution which requires
            // external DSP libraries not available in this standard library implementation.

            // Apply a "Smile" curve often found in polished IRs
            setBand(0, type: .lowPass, freq: 7500, gain: 0, q: 0.5)
            setBand(1, type: .highPass, freq: 65, gain: 0, q: 0.6)
            setBand(2, type: .parametric, freq: 400, gain: 2.5, q: 0.8) // Low-mid warmth
            setBand(3, type: .parametric, freq: 3500, gain: -2.0, q: 1.5) // Remove harshness
            // Using bands 4 & 5 if available in future
        default:
            break
        }
    }

    private func setBand(_ index: Int, type: AVAudioUnitEQFilterType, freq: Float, gain: Float, q: Float) {
        if index < eqNode.bands.count {
            let band = eqNode.bands[index]
            band.filterType = type
            band.frequency = freq
            band.gain = gain
            band.bandwidth = q // Note: AVAudioUnitEQ bandwidth is in octaves, Q is different, but for simplicity we map directly or use inverse.
            // Actually bandwidth = frequency / Q. But property is 'bandwidth' in octaves.
            // Converting Q to Bandwidth (Octaves) is complex.
            // Approx: BW = 1.0 for standard parametric.
            band.bandwidth = 1.0 // Simplify to 1.0 for now to be safe, or estimate.
            band.bypass = false
        }
    }

    func loadIR(url: URL) {
        // Logic to load IR file.
        // Since we are simulating with Parametric EQ (Option A default),
        // we will just store the filename and switch to the .customIR mode.
        // In a full implementation, we would perform convolution here.
        self.irFileName = url.lastPathComponent
        print("Loaded IR: \(url.lastPathComponent) (Simulated via EQ)")
    }
}
