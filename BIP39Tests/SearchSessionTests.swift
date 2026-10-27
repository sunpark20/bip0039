import XCTest
@testable import BIP39

@MainActor
final class SearchSessionTests: XCTestCase {
    func testBundledWordListIntegrityAndSubstringSearch() throws {
        let list = try WordList()
        XCTAssertEqual(list.words.count, 2048)
        XCTAssertEqual(Set(list.words).count, 2048)
        XCTAssertEqual(list.words, list.words.sorted())
        XCTAssertEqual(list.words.first, "abandon")
        XCTAssertEqual(list.words.last, "zoo")
        XCTAssertEqual(list.words.map(\.count).max(), 8)
        XCTAssertEqual(list.matches("").count, 2048)
        XCTAssertEqual(list.matches("a").count, 840)
        XCTAssertEqual(list.matches("act"), [
            "abstract", "act", "action", "actor", "actress", "actual", "artefact",
            "attract", "cactus", "enact", "exact", "impact", "intact", "pact", "practice"
        ])
        XCTAssertTrue(list.matches("zzzz").isEmpty)
    }

    func testInputBoundaryAndDeletion() {
        let session = SearchSession()
        session.append("a")
        XCTAssertEqual(session.query, "")
        session.openSearch()
        for invalid in ["A", "1", " ", "\n", "ab", "한", "é", "😀"] {
            session.append(invalid)
        }
        XCTAssertEqual(session.query, "")
        for letter in "abandonzz" { session.append(String(letter)) }
        XCTAssertEqual(session.query, "abandonz")
        session.deleteLast()
        XCTAssertEqual(session.query, "abandon")
        XCTAssertEqual(session.results, ["abandon"])
    }

    func testClearKeepsKeyboardAndResetDiscardsSession() {
        let session = SearchSession()
        session.openSearch()
        session.append("a")
        session.clear()
        XCTAssertTrue(session.query.isEmpty)
        XCTAssertTrue(session.isKeyboardVisible)
        XCTAssertEqual(session.results.count, 2048)
        session.append("b")
        let revision = session.scrollRevision
        session.reset()
        XCTAssertTrue(session.query.isEmpty)
        XCTAssertFalse(session.isKeyboardVisible)
        XCTAssertEqual(session.results.count, 2048)
        XCTAssertGreaterThan(session.scrollRevision, revision)
        session.reset()
        session.deleteLast()
        XCTAssertTrue(session.query.isEmpty)
        let freshSession = SearchSession()
        XCTAssertTrue(freshSession.query.isEmpty)
        XCTAssertFalse(freshSession.isKeyboardVisible)
    }
}
