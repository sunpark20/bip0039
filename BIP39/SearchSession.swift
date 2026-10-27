import SwiftUI

/// Ephemeral UI state only. Never serialize, restore, or log this object.
@MainActor
final class SearchSession: ObservableObject {
    @Published private(set) var query = ""
    @Published private(set) var isKeyboardVisible = false
    @Published private(set) var scrollRevision = 0
    let wordList: WordList?

    init() {
        wordList = try? WordList()
    }

    var results: [String] { wordList?.matches(query) ?? [] }

    func openSearch() {
        guard wordList != nil else { return }
        isKeyboardVisible = true
    }

    func append(_ letter: String) {
        guard isKeyboardVisible, query.count < 8, letter.utf8.count == 1,
              let byte = letter.utf8.first, (97...122).contains(byte) else { return }
        query.append(contentsOf: letter)
        scrollRevision &+= 1
    }

    func deleteLast() {
        guard !query.isEmpty else { return }
        query.removeLast()
        scrollRevision &+= 1
    }

    func clear() {
        query = ""
        scrollRevision &+= 1
    }

    func reset() {
        clear()
        isKeyboardVisible = false
    }
}
