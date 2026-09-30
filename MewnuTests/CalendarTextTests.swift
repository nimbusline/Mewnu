import XCTest
@testable import Mewnu

final class CalendarTextTests: XCTestCase {
    func testDecodesNamedAndNumericEntities() {
        XCTAssertEqual(CalendarText.decoded("Michi &amp; Michi"), "Michi & Michi")
        XCTAssertEqual(CalendarText.decoded("Meeting &#38; notes &#x1F431;"), "Meeting & notes 🐱")
    }

    func testLeavesPlainTextAndInvalidEntitiesUntouched() {
        XCTAssertEqual(CalendarText.decoded("Research & Development"), "Research & Development")
        XCTAssertEqual(CalendarText.decoded("Unknown &mystery; &#99999999;"), "Unknown &mystery; &#99999999;")
    }
}
