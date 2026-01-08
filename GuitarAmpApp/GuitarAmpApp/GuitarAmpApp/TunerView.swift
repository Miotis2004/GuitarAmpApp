import SwiftUI

struct TunerView: View {
    @ObservedObject var tuner: Tuner
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                // Header
                HStack {
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding()

                Text("TUNER")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .tracking(5)

                // Note Display
                ZStack {
                    Circle()
                        .stroke(
                            tuner.isTuning ? (abs(tuner.deviation) < 5 ? Color.green : Color.orange) : Color.gray.opacity(0.3),
                            lineWidth: 4
                        )
                        .frame(width: 200, height: 200)

                    Text(tuner.note)
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(tuner.isTuning ? .white : .gray)
                }

                // Deviation Bar
                VStack(spacing: 10) {
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 300, height: 4)

                        // Center mark
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 20)
                            .offset(x: 150 - 1)

                        // Indicator
                        if tuner.isTuning {
                            Circle()
                                .fill(abs(tuner.deviation) < 5 ? Color.green : Color.orange)
                                .frame(width: 16, height: 16)
                                .offset(x: 150 + (CGFloat(tuner.deviation) * 3) - 8) // Scale deviation
                                .animation(.spring(), value: tuner.deviation)
                        }
                    }
                    .frame(width: 300)
                    .clipped()

                    HStack {
                        Text("FLAT")
                        Spacer()
                        Text("SHARP")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 300)

                    if tuner.isTuning {
                        Text(String(format: "%.1f Hz", tuner.frequency))
                            .font(.title3)
                            .foregroundColor(.gray)
                            .padding(.top)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .frame(width: 500, height: 600)
    }
}
