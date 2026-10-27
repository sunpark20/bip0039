import SwiftUI

struct LetterKeyboard: View {
    let bottomInset: CGFloat
    let onLetter: (String) -> Void
    let onDelete: () -> Void
    let onClose: () -> Void

    private var hasHomeIndicator: Bool { bottomInset > 0 }
    private var keyHeight: CGFloat { hasHomeIndicator ? 43 : 42 }
    private var rowSpacing: CGFloat { hasHomeIndicator ? 11 : 12 }
    private var topPadding: CGFloat { hasHomeIndicator ? 25 : 6 }
    private var footerHeight: CGFloat { hasHomeIndicator ? 37 : 6 }

    // Measured from the supplied 390 × 844 pt iPhone keyboard: 301 pt
    // including its 34 pt bottom safe area. Keep the system's unused key
    // positions reserved so Z–M and delete stay under the user's fingers.
    private var contentHeight: CGFloat {
        topPadding + keyHeight * 4 + rowSpacing * 3 + footerHeight
    }

    var body: some View {
        GeometryReader { geometry in
            let keyWidth = (geometry.size.width - 12 - 9 * 6) / 10
            let actionWidth: CGFloat = geometry.size.width * 0.23

            VStack(spacing: rowSpacing) {
                row("qwertyuiop", keyWidth: keyWidth)
                row("asdfghjkl", keyWidth: keyWidth)

                ZStack(alignment: .trailing) {
                    row("zxcvbnm", keyWidth: keyWidth)
                    Button(action: onDelete) {
                        Image(systemName: "delete.left")
                            .font(.system(size: 22))
                            .frame(width: 42, height: keyHeight)
                            .background(.white, in: RoundedRectangle(cornerRadius: 9))
                    }
                    .accessibilityLabel("Delete last letter")
                    .accessibilityIdentifier("deleteLetter")
                }

                HStack(spacing: 6) {
                    Text("ABC")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: actionWidth)
                        .accessibilityHidden(true)

                    Text("English")
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("English letters only")

                    Button(action: onClose) {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 24))
                            .frame(width: actionWidth, height: keyHeight)
                            .background(.white, in: RoundedRectangle(cornerRadius: 9))
                    }
                    .accessibilityLabel("Close search and clear")
                    .accessibilityIdentifier("keyboardClose")
                }
                .foregroundStyle(Color(white: 0.32))
                .frame(height: keyHeight)
            }
            .buttonStyle(KeyStyle())
            .padding(.horizontal, 6)
            .padding(.top, topPadding)
        }
        .frame(height: contentHeight)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: hasHomeIndicator ? 28 : 0,
                                   topTrailingRadius: hasHomeIndicator ? 28 : 0)
                .fill(Color(red: 0.89, green: 0.895, blue: 0.91))
                .ignoresSafeArea(.container, edges: .bottom)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("letterKeyboard")
    }

    private func row(_ letters: String, keyWidth: CGFloat) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(letters), id: \.self) { letter in
                Button { onLetter(String(letter)) } label: {
                    Text(String(letter))
                        .font(.system(size: 28))
                        .frame(width: keyWidth, height: keyHeight)
                        .background(.white, in: RoundedRectangle(cornerRadius: 9))
                }
                .accessibilityLabel(String(letter))
                .accessibilityIdentifier("key_\(letter)")
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct KeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.black)
            .opacity(configuration.isPressed ? 0.55 : 1)
            .contentShape(Rectangle())
    }
}
