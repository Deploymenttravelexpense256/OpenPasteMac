import SwiftUI

struct EditItemSheet: View {
    let item: ClipboardItem
    var onSave: (String) -> Void
    var onCancel: () -> Void

    @State private var text: String
    @FocusState private var editorFocused: Bool

    init(item: ClipboardItem, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.item = item
        self.onSave = onSave
        self.onCancel = onCancel
        _text = State(initialValue: item.content.displayText)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") { onCancel() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Edit Clip")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button("Save") { onSave(text) }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .disabled(text.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Editor
            TextEditor(text: $text)
                .font(.system(size: 12.5, design: .monospaced))
                .focused($editorFocused)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color(red: 0.08, green: 0.10, blue: 0.16))
        }
        .frame(width: 520, height: 360)
        .background(Color(red: 0.13, green: 0.16, blue: 0.24))
        .onAppear { editorFocused = true }
    }
}

struct RenameItemSheet: View {
    let item: ClipboardItem
    var onSave: (String) -> Void
    var onCancel: () -> Void

    @State private var name: String
    @FocusState private var fieldFocused: Bool

    init(item: ClipboardItem, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.item = item
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: item.label ?? "")
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Rename Clip")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            TextField(item.content.typeLabel, text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .padding(10)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .focused($fieldFocused)
                .onSubmit { onSave(name) }

            HStack(spacing: 12) {
                Button("Cancel") { onCancel() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("Save") { onSave(name) }
                    .buttonStyle(.plain)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(20)
        .frame(width: 300)
        .background(Color(red: 0.13, green: 0.16, blue: 0.24))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear { fieldFocused = true }
    }
}
