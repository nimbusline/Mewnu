import XCTest

final class MewnuUITests: XCTestCase {
    @discardableResult
    private func openMenu(_ app: XCUIApplication) -> XCUIElement {
        let statusItem = app.menuBars.statusItems["Mewnu"]
        XCTAssertTrue(statusItem.waitForExistence(timeout: 10))
        let footer = app.buttons["openCalendarButton"]
        if !footer.exists { statusItem.click() }
        if !footer.waitForExistence(timeout: 8) { statusItem.click() }
        XCTAssertTrue(footer.waitForExistence(timeout: 8))
        return statusItem
    }

    private func assertFooterLayout(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let buttons = ["helpButton", "openCalendarButton", "quitButton"].map { app.buttons[$0] }
        let handle = app.descendants(matching: .any)["resizeWindowHandle"]
        for button in buttons {
            XCTAssertTrue(button.isHittable, file: file, line: line)
            XCTAssertEqual(button.frame.width, 28, accuracy: 1, file: file, line: line)
            XCTAssertEqual(button.frame.height, 28, accuracy: 1, file: file, line: line)
            XCTAssertEqual(button.frame.midY, buttons[0].frame.midY, accuracy: 1, file: file, line: line)
            XCTAssertLessThanOrEqual(button.frame.maxY, handle.frame.minY, file: file, line: line)
        }
        for index in 0..<2 {
            XCTAssertEqual(buttons[index + 1].frame.minX - buttons[index].frame.maxX, 8,
                           accuracy: 1, file: file, line: line)
        }
        let filter = app.buttons["calendarFilterButton"]
        if filter.exists {
            XCTAssertEqual(filter.frame.width, buttons[0].frame.width, accuracy: 1, file: file, line: line)
            XCTAssertEqual(filter.frame.height, buttons[0].frame.height, accuracy: 1, file: file, line: line)
            XCTAssertLessThan(filter.frame.maxY, buttons[0].frame.minY, file: file, line: line)
        }
    }

    func testWindowHeightPreferenceResizesMenu() {
        // CI runners do not reliably deliver synthetic drags to a MenuBarExtra window.
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launch()
        openMenu(app)
        XCTAssertTrue(app.staticTexts["monthTitle"].waitForExistence(timeout: 5))

        let handle = app.descendants(matching: .any)["resizeWindowHandle"]
        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        assertFooterLayout(app)
        let originalY = handle.frame.midY
        let originalHeight = handle.label

        app.terminate()
        app.launchArguments.append("-ui-testing-short-window")
        app.launch()
        openMenu(app)

        XCTAssertTrue(handle.waitForExistence(timeout: 5))
        assertFooterLayout(app)
        XCTAssertNotEqual(handle.label, originalHeight)
        XCTAssertLessThan(handle.frame.midY, originalY - 10)
        XCTAssertTrue(app.staticTexts["monthTitle"].exists)
    }

    func testHelpAndEscapeReturnToCalendar() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launch()
        openMenu(app)

        let helpButton = app.buttons["helpButton"]
        assertFooterLayout(app)
        XCTAssertTrue(["Help", "Hilfe"].contains(helpButton.label))
        helpButton.click()
        XCTAssertTrue(app.staticTexts["helpTitle"].waitForExistence(timeout: 5))
        assertFooterLayout(app)
        XCTAssertFalse(app.buttons["calendarFilterButton"].exists)
        XCTAssertTrue(["Back", "Zurück"].contains(helpButton.label))
        helpButton.click()
        XCTAssertTrue(app.staticTexts["monthTitle"].waitForExistence(timeout: 5))

        helpButton.click()
        XCTAssertTrue(app.staticTexts["helpTitle"].waitForExistence(timeout: 5))
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertTrue(app.staticTexts["monthTitle"].waitForExistence(timeout: 5))

        app.buttons["calendarFilterButton"].click()
        XCTAssertTrue(app.staticTexts["calendarPickerTitle"].waitForExistence(timeout: 5))
        assertFooterLayout(app)
        helpButton.click()
        XCTAssertTrue(app.staticTexts["helpTitle"].waitForExistence(timeout: 5))
        helpButton.click()
        XCTAssertTrue(app.staticTexts["monthTitle"].waitForExistence(timeout: 5))

        app.buttons["eventRow_demo-1"].click()
        XCTAssertTrue(app.buttons["closeEventDetailsButton"].waitForExistence(timeout: 5))
        assertFooterLayout(app)
        helpButton.click()
        XCTAssertTrue(app.staticTexts["helpTitle"].waitForExistence(timeout: 5))
        helpButton.click()
        XCTAssertTrue(app.staticTexts["monthTitle"].waitForExistence(timeout: 5))
        app.buttons["eventRow_demo-1"].click()
        XCTAssertTrue(app.buttons["closeEventDetailsButton"].waitForExistence(timeout: 5))
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        XCTAssertTrue(app.staticTexts["monthTitle"].waitForExistence(timeout: 5))
    }

    func testTodayRemainsIdentifiableWhenAnotherDayIsSelected() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launch()
        openMenu(app)

        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let todayID = String(format: "day_%04d-%02d-%02d", components.year!, components.month!, components.day!)
        let today = app.buttons[todayID]
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        XCTAssertTrue(today.isSelected)
        let otherDay = components.day == 1 ? 2 : components.day! - 1
        let otherID = String(format: "day_%04d-%02d-%02d", components.year!, components.month!, otherDay)
        let anotherDay = app.buttons[otherID]
        XCTAssertTrue(anotherDay.exists)
        anotherDay.click()
        XCTAssertTrue(today.exists)
        XCTAssertFalse(today.isSelected)
    }

    func testFiftyCalendarsUseCompactDayIndicators() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-ui-testing-many-calendars"]
        app.launch()
        openMenu(app)

        let busyDay = app.buttons.matching(NSPredicate(format: "value CONTAINS %@", "50")).firstMatch
        XCTAssertTrue(busyDay.waitForExistence(timeout: 5))
        busyDay.click()
        XCTAssertTrue(app.staticTexts["50"].exists)
    }

    func testDeniedPermissionShowsRecoveryActions() {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-ui-testing-denied", "-AppleLanguages", "(de)"]
        app.launch()
        openMenu(app)

        let calendarButton = app.buttons["openCalendarButton"]
        let quitButton = app.buttons["quitButton"]
        assertFooterLayout(app)
        XCTAssertEqual(app.buttons["helpButton"].label, "Hilfe")
        XCTAssertEqual(calendarButton.label, "Kalender öffnen")
        XCTAssertEqual(quitButton.label, "Beenden")
        XCTAssertEqual(calendarButton.frame.width, 28, accuracy: 1)
        XCTAssertEqual(quitButton.frame.width, 28, accuracy: 1)

        let settingsButton = app.buttons["openCalendarSettingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        let checkButton = app.buttons["checkCalendarAccessButton"]
        XCTAssertTrue(checkButton.exists)
        XCTAssertEqual(settingsButton.label, "Kalendereinstellungen öffnen")
        XCTAssertEqual(checkButton.label, "Zugriff erneut prüfen")
        for button in [settingsButton, checkButton] {
            XCTAssertLessThanOrEqual(button.frame.width, 280)
            XCTAssertTrue(button.isHittable)
        }
        XCTAssertEqual(settingsButton.frame.minX, checkButton.frame.minX, accuracy: 1)
        XCTAssertFalse(settingsButton.frame.intersects(checkButton.frame))
        checkButton.click()
        XCTAssertTrue(app.buttons["openCalendarSettingsButton"].exists)
        app.buttons["helpButton"].click()
        XCTAssertTrue(app.staticTexts["helpTitle"].waitForExistence(timeout: 5))
        app.buttons["helpButton"].click()
        XCTAssertTrue(app.buttons["openCalendarSettingsButton"].waitForExistence(timeout: 5))
    }

    func testEventDetails() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launch()
        openMenu(app)

        let event = app.buttons["eventRow_demo-1"]
        XCTAssertTrue(event.waitForExistence(timeout: 5))
        XCTAssertTrue(event.label.contains("Demo"))
        event.click()
        XCTAssertTrue(app.staticTexts["Demo"].exists)
        XCTAssertTrue(app.staticTexts["Example location"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Example notes"].exists)
        app.buttons["closeEventDetailsButton"].click()
        XCTAssertTrue(app.staticTexts["monthTitle"].waitForExistence(timeout: 5))
        XCTAssertTrue(["Choose calendars", "Kalender auswählen"].contains(app.buttons["calendarFilterButton"].label))
        XCTAssertTrue(event.exists)
        event.click()
        XCTAssertTrue(app.staticTexts["Example location"].waitForExistence(timeout: 5))
        app.buttons["closeEventDetailsButton"].click()
        XCTAssertTrue(app.staticTexts["monthTitle"].waitForExistence(timeout: 5))
    }

    func testMenuCalendarAndFilter() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launch()
        let statusItem = openMenu(app)
        let monthTitle = app.staticTexts["monthTitle"]
        if !monthTitle.waitForExistence(timeout: 5) { statusItem.click() }
        XCTAssertTrue(monthTitle.waitForExistence(timeout: 5))
        app.buttons["nextMonthButton"].click()
        app.buttons["todayButton"].click()
        app.buttons["calendarFilterButton"].click()
        if !app.staticTexts["calendarPickerTitle"].exists {
            statusItem.click()
        }
        XCTAssertTrue(app.staticTexts["calendarPickerTitle"].waitForExistence(timeout: 5))
        let first = app.descendants(matching: .any)["calendarToggle_demo"]
        let second = app.descendants(matching: .any)["calendarToggle_long"]
        let third = app.descendants(matching: .any)["calendarToggle_third"]
        XCTAssertTrue(first.exists && second.exists && third.exists)
        XCTAssertEqual(first.frame.minX, second.frame.minX, accuracy: 1)
        XCTAssertEqual(first.frame.minX, third.frame.minX, accuracy: 1)
    }
}
