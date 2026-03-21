import SwiftUI

struct StickyNoteView: View {
    let noteID: UUID

    @EnvironmentObject private var store: NoteStore

    @State private var draftTitle = ""
    @State private var draftBody = ""

    private var note: Note? {
        store.note(with: noteID)
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 10) {
                TextField(
                    "",
                    text: $draftTitle,
                    prompt: Text("Title").foregroundColor(.white.opacity(0.72))
                )
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .textFieldStyle(.plain)
                .foregroundStyle(.white.opacity(0.98))
                .onChange(of: draftTitle) { _ in persist() }

                Divider().overlay(.white.opacity(0.2))

                ZStack(alignment: .topLeading) {
                    if draftBody.isEmpty {
                        Text("Type anything here...")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }

                    TextEditor(text: $draftBody)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.98))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .onChange(of: draftBody) { _ in persist() }
                }
            }
            .padding(14)
        }
        .frame(minWidth: 260, minHeight: 220)
        .onAppear {
            guard let note else { return }
            draftTitle = note.title
            draftBody = note.body
        }
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(note.map { Color(hex: $0.colorHex) } ?? Color(hex: "#2F5B8A"))
            .overlay(
                LinearGradient(
                    colors: [.white.opacity(0.08), .clear, .black.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 8)
            .overlay(alignment: .topTrailing) {
                HStack(spacing: 8) {
                    if note?.isPinned == true {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Circle()
                        .fill(.white.opacity(0.65))
                        .frame(width: 12, height: 12)
                }
                .padding(10)
            }
    }

    private func persist() {
        store.update(id: noteID, title: draftTitle, body: draftBody)
    }
}
