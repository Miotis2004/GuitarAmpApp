//
//  PedalViews.swift
//  GuitarAmpApp
//
//  Created by Ronald Joubert on 11/14/25.
//

import SwiftUI

struct OverdrivePedalView: View {
    @ObservedObject var audioEngine: AudioEngineManager
    
    var body: some View {
        PedalContainer(
            title: "OVERDRIVE",
            isEnabled: $audioEngine.distortionEnabled,
            color: .orange
        ) {
            VStack(spacing: 15) {
                // Drive knob
                KnobControl(
                    title: "DRIVE",
                    value: $audioEngine.distortionAmount,
                    color: .orange
                )
            }
            .padding()
        }
    }
}

struct DelayPedalView: View {
    @ObservedObject var audioEngine: AudioEngineManager
    
    var body: some View {
        PedalContainer(
            title: "DELAY",
            isEnabled: $audioEngine.delayEnabled,
            color: .blue
        ) {
            HStack(spacing: 20) {
                // Time knob
                KnobControl(
                    title: "TIME",
                    value: $audioEngine.delayTime,
                    color: .blue
                )
                
                // Feedback knob
                KnobControl(
                    title: "FEEDBACK",
                    value: $audioEngine.delayFeedback,
                    color: .blue
                )
            }
            .padding()
        }
    }
}

struct ReverbPedalView: View {
    @ObservedObject var audioEngine: AudioEngineManager
    
    var body: some View {
        PedalContainer(
            title: "REVERB",
            isEnabled: $audioEngine.reverbEnabled,
            color: .purple
        ) {
            VStack(spacing: 15) {
                // Mix knob
                KnobControl(
                    title: "MIX",
                    value: $audioEngine.reverbAmount,
                    color: .purple
                )
            }
            .padding()
        }
    }
}

// MARK: - Pedal Container
struct PedalContainer<Content: View>: View {
    let title: String
    @Binding var isEnabled: Bool
    let color: Color
    let content: Content
    
    init(title: String, isEnabled: Binding<Bool>, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self._isEnabled = isEnabled
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Pedal body
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color.opacity(0.8),
                                color.opacity(0.6)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                
                VStack {
                    // Title
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    
                    // Content (knobs, etc.)
                    content
                    
                    Spacer()
                    
                    // Status LED
                    Circle()
                        .fill(isEnabled ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                        .shadow(color: isEnabled ? .green : .clear, radius: 5)
                        .padding(.bottom, 8)
                }
            }
            .frame(width: 180, height: 200)
            
            // Footswitch
            Button(action: {
                isEnabled.toggle()
            }) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.8),
                                Color.gray.opacity(0.6)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.3), lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Knob Control
struct KnobControl: View {
    let title: String
    @Binding var value: Float
    let color: Color
    
    @State private var isDragging = false
    @State private var dragStartValue: Float = 0
    @State private var dragStartLocation: CGPoint = .zero
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
            
            ZStack {
                // Knob body
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.8),
                                Color.black.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 2, y: 2)
                
                // Indicator line
                Rectangle()
                    .fill(color)
                    .frame(width: 3, height: 20)
                    .offset(y: -15)
                    .rotationEffect(.degrees(Double(value) * 270 - 135))
                
                // Center dot
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if !isDragging {
                            isDragging = true
                            dragStartValue = value
                            dragStartLocation = gesture.startLocation
                        }
                        
                        let delta = Float(gesture.location.y - dragStartLocation.y)
                        let sensitivity: Float = 0.005
                        let newValue = dragStartValue - (delta * sensitivity)
                        value = max(0, min(1, newValue))
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            
            // Value display
            Text(String(format: "%.0f", value * 100))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 40)
        }
    }
}

#Preview {
    HStack(spacing: 30) {
        OverdrivePedalView(audioEngine: AudioEngineManager())
        DelayPedalView(audioEngine: AudioEngineManager())
        ReverbPedalView(audioEngine: AudioEngineManager())
    }
    .padding(40)
    .background(Color.black)
}
