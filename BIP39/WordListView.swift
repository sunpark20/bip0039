import SwiftUI

struct WordListView: View {
    @ObservedObject var session: SearchSession

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Text("english")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
                    .accessibilityAddTraits(.isHeader)

                if session.wordList == nil {
                    Text("Word list unavailable")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    wordList
                }
            }
            .foregroundStyle(.black)
            .background(.white)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if session.isKeyboardVisible {
                    searchPanel(bottomInset: geometry.safeAreaInsets.bottom)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !session.isKeyboardVisible, session.wordList != nil {
                    searchButton
                }
            }
        }
        .preferredColorScheme(.light)
    }

    private var searchButton: some View {
        Button(action: session.openSearch) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 25, weight: .regular))
                .frame(width: 56, height: 56)
                .background(.white.opacity(0.96), in: Circle())
                .overlay(Circle().stroke(.black.opacity(0.1), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search words")
        .accessibilityIdentifier("openSearch")
        .padding(.trailing, 20)
        .padding(.bottom, 16)
    }

    private var wordList: some View {
        let results = session.results
        let firstWords = results.reduce(into: [String: String]()) { initials, word in
            let letter = String(word.prefix(1))
            if initials[letter] == nil { initials[letter] = word }
        }

        return ScrollViewReader { proxy in
            GeometryReader { geometry in
                ZStack(alignment: .trailing) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            Color.clear.frame(height: 0).id("top")
                            if results.isEmpty {
                                Text("No matches")
                                    .foregroundStyle(.secondary)
                                    .accessibilityIdentifier("noMatches")
                                    .padding(.top, 8)
                            } else {
                                ForEach(results, id: \.self) { word in
                                    Text(word)
                                        .font(.body)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .accessibilityIdentifier("word_\(word)")
                                }
                            }
                        }
                        .padding(.leading, 16)
                        .padding(.trailing, 50)
                        .padding(.top, 6)
                        .padding(.bottom, session.isKeyboardVisible ? 16 : 96)
                    }
                    .scrollIndicators(.hidden)
                    .clipped()
                    .accessibilityIdentifier("wordList")

                    if !results.isEmpty {
                        AlphabetIndexRail(availableLetters: firstWords.keys.sorted()) { letter in
                            guard let word = firstWords[letter] else { return }
                            // Track the finger immediately. Animated scrolls would
                            // queue up and overshoot when crossing several initials.
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                proxy.scrollTo(word, anchor: .top)
                            }
                        }
                        .frame(width: 44,
                               height: min(572, max(1, geometry.size.height -
                                                   (session.isKeyboardVisible ? 12 : 100))))
                        .padding(.trailing, 2)
                        .padding(.bottom, session.isKeyboardVisible ? 0 : 84)
                    }
                }
            }
            .onChange(of: session.scrollRevision) {
                proxy.scrollTo("top", anchor: .top)
            }
        }
    }

    private func searchPanel(bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                // Deliberately not a TextField: no OS input service, edit menu,
                // predictive learning, dictation, or pasteboard integration.
                Text(session.query.isEmpty ? "Search words" : session.query)
                    .foregroundStyle(session.query.isEmpty ? .gray : .black)
                    .font(.body)
                    .lineLimit(1)
                    .minimumScaleFactor(0.35)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("searchQuery")
                    .accessibilityLabel("Search")
                    .accessibilityValue(session.query.isEmpty ? "Empty" : session.query)
                    .padding(.leading, 8)

                Button(action: session.clear) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(.gray)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Clear search")
                .accessibilityIdentifier("clearSearch")
                .disabled(session.query.isEmpty)

                Button(action: session.reset) {
                    Image(systemName: "keyboard.chevron.compact.down")
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close search and clear")
                .accessibilityIdentifier("closeSearch")
            }
            .buttonStyle(.plain)
            .padding(.leading, 16)
            .padding(.trailing, 6)
            .frame(minHeight: 56)
            .background(.white)

            LetterKeyboard(bottomInset: bottomInset,
                           onLetter: session.append,
                           onDelete: session.deleteLast,
                           onClose: session.reset)
        }
        .background(.white)
    }
}
