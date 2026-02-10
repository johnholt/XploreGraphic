//
//  XploreGraphicUITests.swift
//  XploreGraphicUITests
//
//  Created by John Holt on 8/9/24.
//

import XCTest

@testable
import XploreGraphic

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
   
   // Test the enabled/disabled state of variable state buttons and menu items
   func testDisabledState() throws {
      // UI tests must launch the application that they test.
      app.launch()
      // Test initial conditions
      XCTAssert(app.buttons["Accept"].exists)
      XCTAssertFalse(app.buttons["Accept"].isEnabled)
      XCTAssert(app.menuBarItems["Graph"].exists)
      // The Graph menu items should only be enabled when viewiing a graph network diagram
      XCTAssertFalse(app.menuItems["Magnify"].isEnabled)
      XCTAssertFalse(app.menuItems["Reduce"].isEnabled)
      XCTAssertFalse(app.menuItems["Reset"].isEnabled)
      // Navigate to graph view and check for being enabled
      app/*@START_MENU_TOKEN@*/.buttons["Graph Network"]/*[[".groups.buttons[\"Graph Network\"]",".buttons[\"Graph Network\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.click()
      XCTAssertTrue(app.menuItems["Magnify"].isEnabled)
      XCTAssertTrue(app.menuItems["Reduce"].isEnabled)
      XCTAssertTrue(app.menuItems["Reset"].isEnabled)
      // Navigate back and verify that they are disabled
      app.buttons["Back"].firstMatch.click()
      XCTAssertFalse(app.menuItems["Magnify"].isEnabled)
      XCTAssertFalse(app.menuItems["Reduce"].isEnabled)
      XCTAssertFalse(app.menuItems["Reset"].isEnabled)
   }
   
   // Test histogram features in Graph Data view
   func testHistogramFeatures() throws {
      app.launch()
      app.buttons["GraphDataView"].firstMatch.click()
      XCTAssert(app.steppers["GraphDataViewNumBinsStepper"].exists)
      XCTAssert(app.staticTexts["GraphDataViewNumBinsStepperText"].exists)
      if let initialBucketsText = app.staticTexts["GraphDataViewNumBinsStepperText"].value as? String {
         XCTAssertEqual(initialBucketsText, "Number of bins: 4", "Wrong initial value for number of buckets")
      } else {
         XCTFail("Number of bins message not a string")
      }
      // initial state of stepper confirmed, now modify
      app.steppers["GraphDataViewNumBinsStepper"].incrementArrows.firstMatch.click()
      app.steppers["GraphDataViewNumBinsStepper"].incrementArrows.firstMatch.click()
      // Now check state of the picker
      if let distanceTypeText = app.popUpButtons["GraphDataViewMeasurePicker"].firstMatch.value as? String {
         XCTAssertEqual(distanceTypeText, "Path Length", "Text for initial distance type incorrect")
      } else {
         XCTFail("Initial picker value not set")
      }
      // Pick Jaccard distance of the TagSet
      app/*@START_MENU_TOKEN@*/.popUpButtons["GraphDataViewMeasurePicker"].firstMatch/*[[".groups",".popUpButtons[\"Path Length\"].firstMatch",".popUpButtons[\"GraphDataViewMeasurePicker\"].firstMatch",".popUpButtons",".containing(.menuItem, identifier: \"menuAction:\").firstMatch",".containing(.menu, identifier: nil).firstMatch",".firstMatch"],[[[-1,2],[-1,1],[-1,3,1],[-1,0,2]],[[-1,6],[-1,5],[-1,4]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.click()
      app/*@START_MENU_TOKEN@*/.menuItems["Tagset Jaccard"]/*[[".menus.menuItems[\"Tagset Jaccard\"]",".menuItems[\"Tagset Jaccard\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.firstMatch.click()
      // Refresh to histogram based on changed parameters
      app/*@START_MENU_TOKEN@*/.buttons["GraphDataViewRefreshButton"]/*[[".groups",".buttons[\"Refresh\"]",".buttons[\"GraphDataViewRefreshButton\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch.click()
      // Now we check the results by looking at the High Bound value
      XCTAssert(app.staticTexts["GraphDataViewHighBound"].exists)
      if let resultHighBound = Double(app.staticTexts["GraphDataViewHighBound"].firstMatch.value as! String) {
         XCTAssertEqual(resultHighBound, 1.144, accuracy: 0.05, "HighBound for the distance incorrect")
      } else {
         XCTFail("No HighBound found")
      }
      // Go back and then re-enter to confirm state is maintained
      app.buttons["Back"].firstMatch.click()
      app.buttons["GraphDataView"].firstMatch.click()
      // first check the bins
      if let reEntryBucketsText = app.staticTexts["GraphDataViewNumBinsStepperText"].value as? String {
         XCTAssertEqual(reEntryBucketsText, "Number of bins: 10", "Wrong re-entry value for number of buckets")
      } else {
         XCTFail("Number of bins message not a string")
      }
      // then check the type of distance measure
      if let distanceTypeText = app.popUpButtons["GraphDataViewMeasurePicker"].firstMatch.value as? String {
         XCTAssertEqual(distanceTypeText, "Tagset Jaccard", "Text for re-entry distance type incorrect")
      } else {
         XCTFail("Re-entry picker value not set")
      }
   }
   
   // Test tap of upper left object for correct tag information
   // *** Test from recording not working.  Need to control click placement
   func testSimmpleShowInfo() throws {
      let app = XCUIApplication()
      app.activate()
      app/*@START_MENU_TOKEN@*/.buttons["GraphNetworkView"]/*[[".groups",".buttons[\"Graph Network\"]",".buttons[\"GraphNetworkView\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch.click()
      
      let element = app.groups/*@START_MENU_TOKEN@*/.containing(.staticText, identifier: "There are 15 tags in the graph").firstMatch/*[[".element(boundBy: 0)",".containing(.staticText, identifier: \"There are 3 islands, and 3 regions\").firstMatch",".containing(.staticText, identifier: \"The working grid is 25 x 17\").firstMatch",".containing(.staticText, identifier: \"There are 15 tags in the graph\").firstMatch"],[[[-1,3],[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
      element.click()
   }
   
   // Test drag then tap of upper left object for correct tag info, followed by scale up and same tap
   // *** same problem as above
   
   // Test scale followed by drag and then tap of upper left object for correct information
   // *** same problem as above
   
   func testLaunchPerformance() throws {
      if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
         // This measures how long it takes to launch your application.
         measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
         }
      }
   }
}
