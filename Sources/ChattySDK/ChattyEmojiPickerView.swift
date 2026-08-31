import SwiftUI

/// Search field + category tabs + scrollable grid over `ChattyEmojiData`'s full
/// set — the "real emoji library" experience (matching the web widget's
/// emoji-picker-react and the Android SDK's androidx.emoji2 EmojiPickerView),
/// not the old fixed ~60-emoji grid. All data is a compiled-in constant
/// (`ChattyEmojiData.swift`), so there's nothing to fetch — this view renders
/// synchronously the moment its parent shows it.
struct ChattyEmojiPickerView: View {
    let onPick: (String) -> Void

    @State private var query: String = ""
    @State private var selectedCategory: String = ChattyEmojiData.categoryOrder.first ?? ""

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var visibleEmoji: [ChattyEmojiEntry] {
        if isSearching {
            let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return ChattyEmojiData.all.filter {
                $0.name.lowercased().contains(q) || $0.tags.contains { $0.lowercased().contains(q) }
            }
        }
        return ChattyEmojiData.all.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.61, green: 0.64, blue: 0.69))
                TextField("Search emoji…", text: $query)
                    .font(.system(size: 12))
                    .autocorrectionDisabled(true)
                #if os(iOS)
                    .textInputAutocapitalization(.never)
                #endif
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(red: 0.97, green: 0.97, blue: 0.98))

            if !isSearching {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(ChattyEmojiData.categoryOrder, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Image(systemName: chattyEmojiCategorySymbol(category))
                                    .font(.system(size: 14))
                                    .foregroundColor(
                                        selectedCategory == category
                                            ? Color(red: 0.2, green: 0.2, blue: 0.22)
                                            : Color(red: 0.61, green: 0.64, blue: 0.69)
                                    )
                                    .frame(width: 32, height: 32)
                                    .background(
                                        selectedCategory == category
                                            ? Color(red: 0.93, green: 0.94, blue: 0.95)
                                            : Color.clear
                                    )
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                }
                .background(Color.white)
                Divider()
            }

            ScrollView {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 8)
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(visibleEmoji, id: \.emoji) { entry in
                        Text(entry.emoji)
                            .font(.system(size: 20))
                            .frame(width: 32, height: 32)
                            .onTapGesture { onPick(entry.emoji) }
                    }
                }
                .padding(6)
            }
        }
        .frame(height: 320)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.9, green: 0.91, blue: 0.92)))
        .shadow(color: Color.black.opacity(0.18), radius: 12, y: 4)
    }
}

private func chattyEmojiCategorySymbol(_ category: String) -> String {
    switch category {
    case "Smileys & Emotion": return "face.smiling"
    case "People & Body": return "hand.wave"
    case "Animals & Nature": return "pawprint"
    case "Food & Drink": return "fork.knife"
    case "Travel & Places": return "airplane"
    case "Activities": return "gamecontroller"
    case "Objects": return "lightbulb"
    case "Symbols": return "number"
    case "Flags": return "flag"
    default: return "circle"
    }
}
