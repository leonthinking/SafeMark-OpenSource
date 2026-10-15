import XCTest

final class SafeMarkUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSettingsAndPrivacyAfterWebPagesRemoved() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        app.buttons["openSettings"].tap()
        XCTAssertTrue(app.buttons["githubFeedback"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["sourceCode"].exists)
        XCTAssertFalse(app.staticTexts["Developer Notes"].exists)
        XCTAssertFalse(app.staticTexts["Feature Introduction"].exists)
        XCTAssertEqual(app.webViews.count, 0)
        app.buttons["Privacy Policy"].tap()
        XCTAssertTrue(app.staticTexts["SafeMark 隐私协议"].waitForExistence(timeout: 5))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Privacy page"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testFeedbackOpensOutsideApp() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["openSettings"].tap()
        let feedback = app.buttons["githubFeedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        feedback.tap()
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 10))
        app.activate()
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertEqual(app.webViews.count, 0)
    }
}
