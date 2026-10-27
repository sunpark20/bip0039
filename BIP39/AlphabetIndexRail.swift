import SwiftUI

struct AlphabetIndexRail: View {
    let availableLetters: [String]
    let onSelect: (String) -> Void

    private static let alphabet = Array("abcdefghijklmnopqrstuvwxyz").map(String.init)
    @State private var draggingLetter: String?
    @State private var lastSelectedLetter: String?
    @State private var selectionRevision = 0

    var body: some View {
        GeometryReader { geometry in
            let cellHeight = geometry.size.height / CGFloat(Self.alphabet.count)
            let compact = cellHeight < 14

            ZStack {
                Capsule()
                    .fill(Color(white: 0.96))
                    .frame(width: 28)

                VStack(spacing: 0) {
                    ForEach(Self.alphabet.indices, id: \.self) { index in
                        let letter = Self.alphabet[index]
                        let selected = draggingLetter == letter
                        ZStack {
                            if selected {
                                Capsule().fill(.black)
                                    .frame(width: 26, height: min(cellHeight, 23))
                            }
                            if !compact || index.isMultiple(of: 2) || index == 25 || selected {
                                Text(letter.uppercased())
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(selected ? .white : letterColor(letter))
                            } else {
                                Circle().fill(letterColor(letter)).frame(width: 2, height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: cellHeight)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = value.location.y / max(geometry.size.height, 1)
                        let index = min(25, max(0, Int(floor(fraction * 26))))
                        let requested = Self.alphabet[index]
                        // Empty initials (including X in the BIP39 list) resolve
                        // to the next available section, or the final section.
                        guard let letter = availableLetters.first(where: { $0 >= requested })
                                ?? availableLetters.last,
                              draggingLetter != letter else { return }
                        draggingLetter = letter
                        select(letter)
                    }
                    .onEnded { _ in draggingLetter = nil }
            )
            .overlay(alignment: .topLeading) {
                if let letter = draggingLetter,
                   let index = Self.alphabet.firstIndex(of: letter) {
                    Text(letter.uppercased())
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 64)
                        .background(.black, in: RoundedRectangle(cornerRadius: 18))
                        .position(x: -38,
                                  y: min(max(32, (CGFloat(index) + 0.5) * cellHeight),
                                         max(32, geometry.size.height - 32)))
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Alphabet index")
        .accessibilityIdentifier("alphabetIndex")
        .accessibilityValue((lastSelectedLetter ?? availableLetters.first ?? "a").uppercased())
        .accessibilityHint("Swipe up or down to move between starting letters.")
        .accessibilityAdjustableAction { direction in
            guard !availableLetters.isEmpty else { return }
            let current = availableLetters.firstIndex(of: lastSelectedLetter ?? "") ?? 0
            switch direction {
            case .increment: select(availableLetters[min(current + 1, availableLetters.count - 1)])
            case .decrement: select(availableLetters[max(current - 1, 0)])
            @unknown default: break
            }
        }
        .sensoryFeedback(.selection, trigger: selectionRevision)
        .onChange(of: availableLetters) {
            draggingLetter = nil
            lastSelectedLetter = nil
        }
    }

    private func letterColor(_ letter: String) -> Color {
        availableLetters.contains(letter) ? .black : Color(white: 0.58)
    }

    private func select(_ letter: String) {
        lastSelectedLetter = letter
        selectionRevision &+= 1
        onSelect(letter)
    }
}
