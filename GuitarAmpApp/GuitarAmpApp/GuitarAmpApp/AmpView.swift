//
//  AmpView.swift
//  GuitarAmpApp
//
//  Created by Ronald Joubert on 11/14/25.
//

import SwiftUI

struct AmpView: View {
    @ObservedObject var audioEngine: AudioEngineManager
    
    var body: some View {
        VStack(spacing: 15) {
            // Amp header
            HStack {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("AMP SIMULATOR")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 10)
            
            // Tone controls
            HStack(spacing: 40) {
                // Bass
                VStack(spacing: 10) {
                    Text("BASS")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    ZStack {
                        // Knob background
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.3, green: 0.3, blue: 0.35),
                                        Color(red: 0.2, green: 0.2, blue: 0.25)
                                    ]),
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 35
                                )
                            )
                            .frame(width: 70, height: 70)
                            .shadow(color: .black.opacity(0.5), radius: 5, x: 2, y: 2)
                        
                        // Indicator
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 4, height: 25)
                            .offset(y: -17)
                            .rotationEffect(.degrees(Double(audioEngine.bassLevel) * 270 - 135))
                        
                        // Center cap
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                    .gesture(createKnobGesture(binding: $audioEngine.bassLevel))
                    
                    Text(String(format: "%.0f", (audioEngine.bassLevel - 0.5) * 24))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Mid
                VStack(spacing: 10) {
                    Text("MID")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.3, green: 0.3, blue: 0.35),
                                        Color(red: 0.2, green: 0.2, blue: 0.25)
                                    ]),
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 35
                                )
                            )
                            .frame(width: 70, height: 70)
                            .shadow(color: .black.opacity(0.5), radius: 5, x: 2, y: 2)
                        
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 4, height: 25)
                            .offset(y: -17)
                            .rotationEffect(.degrees(Double(audioEngine.midLevel) * 270 - 135))
                        
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                    .gesture(createKnobGesture(binding: $audioEngine.midLevel))
                    
                    Text(String(format: "%.0f", (audioEngine.midLevel - 0.5) * 24))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Treble
                VStack(spacing: 10) {
                    Text("TREBLE")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.3, green: 0.3, blue: 0.35),
                                        Color(red: 0.2, green: 0.2, blue: 0.25)
                                    ]),
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 35
                                )
                            )
                            .frame(width: 70, height: 70)
                            .shadow(color: .black.opacity(0.5), radius: 5, x: 2, y: 2)
                        
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 4, height: 25)
                            .offset(y: -17)
                            .rotationEffect(.degrees(Double(audioEngine.trebleLevel) * 270 - 135))
                        
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                    .gesture(createKnobGesture(binding: $audioEngine.trebleLevel))
                    
                    Text(String(format: "%.0f", (audioEngine.trebleLevel - 0.5) * 24))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.vertical, 10)
            
            // Amp model selector (placeholder for future expansion)
            HStack(spacing: 15) {
                Text("MODEL:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                
                Text("Classic Crunch")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)

                Spacer()

                // Cab Sim Integration
                CabSimView(cabSim: audioEngine.cabSim)
                    .scaleEffect(0.9)
            }
            .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.15, green: 0.15, blue: 0.17),
                            Color(red: 0.12, green: 0.12, blue: 0.14)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 40)
    }
    
    private func createKnobGesture(binding: Binding<Float>) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                let delta = Float(gesture.translation.height)
                let sensitivity: Float = -0.003
                let newValue = binding.wrappedValue + (delta * sensitivity)
                binding.wrappedValue = max(0, min(1, newValue))
            }
    }
}

#Preview {
    AmpView(audioEngine: AudioEngineManager())
        .frame(width: 800)
        .background(Color.black)
}
