import SwiftUI
import UniformTypeIdentifiers

struct CabSimView: View {
    @ObservedObject var cabSim: CabSimulator
    @State private var showingFileImporter = false

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.yellow)
                Text("CABINET")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()

                // Active Indicator
                Circle()
                    .fill(cabSim.activeModel != .bypass ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
            .padding(.bottom, 4)

            // Model Selector
            Menu {
                Picker("Cab Model", selection: $cabSim.activeModel) {
                    ForEach(CabModel.allCases) { model in
                        Text(model.rawValue).tag(model)
                    }
                }
            } label: {
                HStack {
                    Text(cabSim.activeModel.rawValue)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(6)
            }
            .menuStyle(.borderlessButton)

            // IR Loader Button (Only visible if Custom IR or general access)
            Button(action: {
                showingFileImporter = true
            }) {
                HStack {
                    Image(systemName: "folder")
                    Text(cabSim.irFileName ?? "Load IR...")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [UTType.audio],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        cabSim.loadIR(url: url)
                    }
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.2, green: 0.2, blue: 0.22))
                .shadow(radius: 4)
        )
        .frame(width: 160)
    }
}
