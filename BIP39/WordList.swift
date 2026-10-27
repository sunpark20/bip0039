import Foundation
import CryptoKit

struct WordList {
    static let expectedSHA256 = "2f5eed53a4727b4bf8880d8f3f199efc90e58503646d9ff8eff3a2ed3b24dbda"
    let words: [String]

    enum LoadError: Error {
        case invalidResource
    }

    init(bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: "english", withExtension: "txt") else {
            throw LoadError.invalidResource
        }
        let data = try Data(contentsOf: url)
        let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard digest == Self.expectedSHA256,
              let text = String(data: data, encoding: .utf8) else {
            throw LoadError.invalidResource
        }
        words = text.split(separator: "\n").map(String.init)
        guard words.count == 2048, Set(words).count == 2048,
              words == words.sorted(), words.first == "abandon", words.last == "zoo" else {
            throw LoadError.invalidResource
        }
    }

    func matches(_ query: String) -> [String] {
        query.isEmpty ? words : words.filter { $0.contains(query) }
    }
}
