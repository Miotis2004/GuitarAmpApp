import SwiftUI

struct NoiseGateView: View {
    @ObservedObject var audioEngine: AudioEngineManager

    var body: some View {
        // Simple 1-knob "Mini Pedal" or Rack Unit style
        VStack(spacing: 8) {
            Text("NOISE GATE")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(4)
                .background(Color.black.opacity(0.5))
                .cornerRadius(4)

            KnobControl(
                title: "THRESH",
                value: $audioEngine.gateThreshold,
                color: .gray
            )
            .scaleEffect(0.8) // Smaller than main pedals
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                .shadow(radius: 2)
        )
    }
}

struct CompressorPedalView: View {
    @ObservedObject var audioEngine: AudioEngineManager

    var body: some View {
        PedalContainer(
            title: "COMPRESSOR",
            isEnabled: $audioEngine.compEnabled,
            color: Color(red: 0.8, green: 0.2, blue: 0.2) // Dyna Red
        ) {
            HStack(spacing: 20) {
                KnobControl(
                    title: "SUSTAIN",
                    value: $audioEngine.compSustain,
                    color: .white
                )

                KnobControl(
                    title: "LEVEL",
                    value: $audioEngine.compLevel,
                    color: .white
                )
            }
            .padding()
        }
    }
}

struct ModulationPedalView: View {
    @ObservedObject var audioEngine: AudioEngineManager

    var body: some View {
        PedalContainer(
            title: "MODULATION",
            isEnabled: $audioEngine.modEnabled,
            color: Color(red: 0.2, green: 0.6, blue: 0.8) // Blue
        ) {
            VStack(spacing: 15) {
                // Type Selector
                Picker("Type", selection: $audioEngine.modType) {
                    ForEach(AudioEngineManager.ModulationType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                HStack(spacing: 20) {
                    KnobControl(
                        title: "RATE",
                        value: $audioEngine.modRate,
                        color: .white
                    )

                    KnobControl(
                        title: "DEPTH",
                        value: $audioEngine.modDepth,
                        color: .white
                    )
                }
            }
            .padding()
        }
    }
}
