import XCTest

final class MonsterFoundryUITests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testDrawingScreenOffersOneClearJudgeAction() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()

        let awakenButton = app.buttons["bringItAliveButton"]
        XCTAssertTrue(awakenButton.waitForExistence(timeout: 4))
        XCTAssertFalse(awakenButton.isEnabled)
    }

    @MainActor
    func testLandscapeKeepsCanvasAndPrimaryActionAvailable() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.otherElements["drawingCanvas"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["bringItAliveButton"].exists)
        XCTAssertTrue(app.buttons["openGalleryButton"].exists)
    }
}
