import SwiftUI
import ChattySDK

// Swap this for your own bot id — find it in the Chatty dashboard under
// Embed & Integrate → iOS SDK. This one is the public demo bot.
private let demoBotID = "c8fa19c8-dd25-43a3-9c55-e8099e6f532e"

struct ContentView: View {
    @State private var showFullScreen = false

    var body: some View {
        ZStack {
            if showFullScreen {
                VStack(spacing: 0) {
                    HStack {
                        Button("← Back") { showFullScreen = false }
                        Spacer()
                        Text("Full-screen chat").font(.headline)
                        Spacer()
                        Color.clear.frame(width: 44)
                    }
                    .padding()
                    ChattyChatView(botId: demoBotID)
                }
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Chatty iOS SDK")
                        .font(.largeTitle.bold())
                    Text("This example shows both integration styles: a floating launcher (bottom-right, tap it) and a full-screen embedded chat.")
                        .foregroundStyle(.secondary)
                    Button("Open full-screen chat") { showFullScreen = true }
                        .buttonStyle(.borderedProminent)
                    Spacer()
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(.systemGroupedBackground))
                .overlay(
                    // Floating launcher — its default color follows whatever
                    // design is selected for this bot in the dashboard; no
                    // manual color config needed here.
                    ChattyLauncher(botId: demoBotID)
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
