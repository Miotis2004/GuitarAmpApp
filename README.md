# Guitar Amp & Effects Simulator

A native macOS application built with SwiftUI and AVFoundation that turns your computer into a virtual guitar amplifier and effects processor. Connect your guitar via an audio interface and jam with real-time effects.

## Features

### 🎸 Signal Chain
*   **Overdrive Pedal**: Add grit and sustain with variable Drive control.
*   **Amp Head**: 3-Band EQ (Bass, Mid, Treble) to shape your core tone.
*   **Cabinet Simulator**: Select from various cabinet models (Vintage 4x12, Modern 4x12, Tweed 1x12, Bass 8x10) or use the Custom IR Simulation mode.
*   **Delay Pedal**: Digital delay with Time and Feedback controls.
*   **Reverb Pedal**: Add space with a Room/Hall reverb mix.

### 🛠 Tools
*   **Chromatic Tuner**: Built-in high-precision tuner with visual needle and frequency display.
*   **Device Manager**: Select your specific Input (Guitar) and Output (Speakers/Headphones) devices directly from the app.
*   **Real-time Metering**: Monitor input and output levels to avoid clipping.

## Requirements
*   macOS 12.0 or later
*   Xcode 14.0 or later (for building)
*   Audio Interface (e.g., Focusrite Scarlett, Apogee) recommended for connecting an electric guitar.

## Getting Started

1.  **Clone the repository.**
2.  **Open the project** in Xcode: `GuitarAmpApp/GuitarAmpApp.xcodeproj`.
3.  **Build and Run** (Select "My Mac" as the destination).
4.  **Permissions**: Grant microphone access when prompted (required to process audio input).

## Usage Guide

### 1. Audio Setup
*   Click the **Gear Icon** (Settings) in the top-right corner.
*   Select your audio interface as the **Input Device**.
*   Select your speakers or headphones as the **Output Device**.
*   **Important**: Turn down your speakers before activating to prevent feedback loops!

### 2. The Rig
*   **Power Button**: Top-right corner. Toggles the audio engine on/off.
*   **Pedals**: Click the footswitch (bottom part of the pedal) to bypass/engage an effect. Drag knobs to adjust parameters.
*   **Amp Controls**: Adjust Bass, Mid, and Treble to sculpt your tone.
*   **Cabinet**: Use the dropdown in the Amp section to change the speaker character.

### 3. Tuning
*   Click the **Tuning Fork Icon** to open the Tuner.
*   Play a string. The note name and tuning accuracy (sharp/flat) will be displayed.

## Architecture

*   **UI**: 100% SwiftUI.
*   **Audio Engine**: `AVAudioEngine` based.
    *   **Nodes**: `AVAudioUnitDistortion`, `AVAudioUnitEQ`, `AVAudioUnitDelay`, `AVAudioUnitReverb`.
    *   **Custom DSP**: Input/Output metering via taps, Pitch detection via Accelerate/vDSP.
*   **Device Management**: CoreAudio HAL integration for hardware device enumeration and switching.
