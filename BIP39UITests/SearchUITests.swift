import XCTest

@MainActor
final class SearchUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["openSearch"].waitForExistence(timeout: 10))
    }

    func testSearchClearCloseAndNoSystemKeyboard() {
        capture("01-word-list")
        app.buttons["openSearch"].tap()
        type("act")
        XCTAssertEqual(app.staticTexts["searchQuery"].value as? String, "act")
        XCTAssertTrue(app.staticTexts["word_abstract"].exists)
        XCTAssertTrue(app.staticTexts["word_action"].exists)
        XCTAssertFalse(app.staticTexts["word_ability"].exists)
        XCTAssertEqual(app.keyboards.count, 0)
        XCTAssertEqual(app.textFields.count, 0)
        capture("02-search-act")

        app.buttons["clearSearch"].tap()
        XCTAssertEqual(app.staticTexts["searchQuery"].value as? String, "Empty")
        XCTAssertTrue(app.buttons["key_a"].exists)
        type("zzzz")
        XCTAssertTrue(app.staticTexts["noMatches"].exists)
        app.buttons["deleteLetter"].tap()
        XCTAssertEqual(app.staticTexts["searchQuery"].value as? String, "zzz")
        app.buttons["closeSearch"].tap()
        XCTAssertTrue(app.buttons["openSearch"].exists)
        XCTAssertFalse(app.buttons["key_a"].exists)
        XCTAssertTrue(app.staticTexts["word_abandon"].exists)
        app.buttons["openSearch"].tap()
        XCTAssertEqual(app.staticTexts["searchQuery"].value as? String, "Empty")
    }

    func testBackgroundAndRelaunchDiscardSearch() {
        app.buttons["openSearch"].tap()
        type("qxjzvkwp") // Public synthetic canary for the sandbox/log audit.
        XCTAssertTrue(app.staticTexts["noMatches"].exists)
        XCUIDevice.shared.press(.home)
        app.activate()
        assertReset()
        app.buttons["openSearch"].tap()
        type("act")
        app.terminate()
        app.launch()
        assertReset()
        app.buttons["openSearch"].tap()
        XCTAssertEqual(app.staticTexts["searchQuery"].value as? String, "Empty")
    }

    func testControlCenterDiscardsSearch() {
        app.buttons["openSearch"].tap()
        type("act")
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.01))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.7))
        start.press(forDuration: 0.1, thenDragTo: end)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // Control Center is a system surface, not an app-owned overlay.
        XCTAssertTrue(springboard.wait(for: .runningForeground, timeout: 5))
        let bottom = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98))
        let middle = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
        bottom.press(forDuration: 0.1, thenDragTo: middle)
        app.activate()
        assertReset()
    }

    func testScrollAndInputLimit() {
        app.scrollViews["wordList"].swipeUp()
        app.buttons["openSearch"].tap()
        type("abandonzz")
        XCTAssertEqual(app.staticTexts["searchQuery"].value as? String, "abandonz")
        app.buttons["deleteLetter"].tap()
        XCTAssertTrue(app.staticTexts["word_abandon"].isHittable)
        app.buttons["clearSearch"].tap()
        XCTAssertTrue(app.staticTexts["word_abandon"].isHittable)
    }

    func testKeyboardUsesNativeLetterPositions() {
        app.buttons["openSearch"].tap()
        let q = app.buttons["key_q"].frame
        let w = app.buttons["key_w"].frame
        let a = app.buttons["key_a"].frame
        let z = app.buttons["key_z"].frame
        let m = app.buttons["key_m"].frame
        let delete = app.buttons["deleteLetter"].frame
        let close = app.buttons["keyboardClose"].frame
        let pitch = w.midX - q.midX

        XCTAssertEqual(q.minX, 6, accuracy: 1)
        XCTAssertEqual(a.midX, q.midX + pitch / 2, accuracy: 1)
        XCTAssertEqual(z.midX, q.midX + pitch * 1.5, accuracy: 1)
        XCTAssertEqual(m.width, q.width, accuracy: 1)
        XCTAssertEqual(delete.maxX, app.frame.width - 6, accuracy: 1)
        XCTAssertGreaterThan(delete.minX, m.maxX)
        XCTAssertEqual(z.minY - a.minY, a.minY - q.minY, accuracy: 1)
        XCTAssertEqual(close.minY - z.minY, a.minY - q.minY, accuracy: 1)

        // Reference screenshot is a 390 × 844 pt iPhone, with Q at y = 568.
        if abs(app.frame.width - 390) < 1, abs(app.frame.height - 844) < 1 {
            XCTAssertEqual(q.minY, 568, accuracy: 2)
            XCTAssertEqual(q.height, 43, accuracy: 1)
        }
        XCTAssertEqual(app.keyboards.count, 0)
        XCTAssertEqual(app.textFields.count, 0)
        capture("03-native-key-positions")
        type("qaz")
        XCTAssertEqual(app.staticTexts["searchQuery"].value as? String, "qaz")
        app.buttons["keyboardClose"].tap()
        assertReset()
    }

    func testAlphabetDragAndFilteredIndex() {
        let index = app.otherElements["alphabetIndex"]
        XCTAssertTrue(index.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(index.frame.width, 44)
        let top = index.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.01))
        let bottom = index.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.99))

        top.press(forDuration: 0.05, thenDragTo: bottom)
        waitUntilVisible("word_zoo")
        XCTAssertEqual(index.value as? String, "Z")
        capture("04-index-z")
        bottom.press(forDuration: 0.05, thenDragTo: top)
        waitUntilVisible("word_abandon")
        XCTAssertEqual(index.value as? String, "A")

        // No BIP39 word begins with X; the index should land on Y.
        index.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 23.5 / 26)).tap()
        waitUntilVisible("word_yard")
        XCTAssertEqual(index.value as? String, "Y")

        app.buttons["openSearch"].tap()
        type("act")
        index.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.99)).tap()
        waitUntilVisible("word_practice")
        XCTAssertEqual(index.value as? String, "P")
        XCTAssertEqual(app.staticTexts["searchQuery"].value as? String, "act")
        capture("05-filtered-index")

        app.buttons["clearSearch"].tap()
        waitUntilVisible("word_abandon")
        type("zzzz")
        XCTAssertTrue(app.staticTexts["noMatches"].exists)
        XCTAssertFalse(index.exists)
    }

    private func waitUntilVisible(_ identifier: String) {
        let element = app.staticTexts[identifier]
        let visible = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"),
            object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 5), .completed)
    }

    private func assertReset() {
        XCTAssertTrue(app.buttons["openSearch"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["key_a"].exists)
        XCTAssertFalse(app.staticTexts["searchQuery"].exists)
        XCTAssertTrue(app.staticTexts["word_abandon"].isHittable)
    }

    private func type(_ text: String) {
        for letter in text { app.buttons["key_\(letter)"].tap() }
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
