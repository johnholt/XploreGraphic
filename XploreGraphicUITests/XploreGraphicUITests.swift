//
//  XploreGraphicUITests.swift
//  XploreGraphicUITests
//
//  Created by John Holt on 8/9/24.
//

import XCTest

final class XploreGraphicUITests: XCTestCase {
   let app = XCUIApplication()
   
   override func setUpWithError() throws {
      // Put setup code here. This method is called before the invocation of each test method in the class.
      
      // In UI tests it is usually best to stop immediately when a failure occurs.
      continueAfterFailure = false
      
      // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
   }
   
   override func tearDownWithError() throws {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
   }
   
   func testDisabledState() throws {
      // UI tests must launch the application that they test.
      app.launch()
      // Test initial conditions
      XCTAssert(app.buttons["Accept"].exists)
      XCTAssertFalse(app.buttons["Accept"].isEnabled)
      XCTAssert(app.menuBarItems["Graph"].exists)
      XCTAssertFalse(app.menuItems["Magnify"].isEnabled)
      XCTAssertFalse(app.menuItems["Reduce"].isEnabled)
      XCTAssertFalse(app.menuItems["Reset"].isEnabled)
      // Navigate to graph view and check for being enabled
      let app = XCUIApplication()
      app.activate()
      app/*@START_MENU_TOKEN@*/.buttons["Graph Network"]/*[[".groups.buttons[\"Graph Network\"]",".buttons[\"Graph Network\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.click()
      XCTAssertTrue(app.menuItems["Magnify"].isEnabled)
      XCTAssertTrue(app.menuItems["Reduce"].isEnabled)
      XCTAssertTrue(app.menuItems["Reset"].isEnabled)
     }
   
   // Test histogram features in Graph Data view
   
   // Test tap of upper left object for correct tag information
   
   // Test drag then tap of upper left object for correct tag info, followed by scale up and same tap
   
   // Test scale followed by drag and then tap of upper left object for correct information
   
   func testLaunchPerformance() throws {
      if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
         // This measures how long it takes to launch your application.
         measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
         }
      }
   }
}
