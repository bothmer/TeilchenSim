//
//  Teilchensimulation_iPhoneUITestsLaunchTests.swift
//  Teilchensimulation_iPhoneUITests
//
//  Created by Hans-Christian v. Bothmer on 09.01.24.
//

import XCTest

final class Teilchensimulation_iPhoneUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
