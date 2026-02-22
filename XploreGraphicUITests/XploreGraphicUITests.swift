//
//  XploreGraphicUITests.swift
//  XploreGraphicUITests
//
//  Created by John Holt on 8/9/24.
//

import XCTest
import Foundation

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
      let backButton = app.buttons["Back"].firstMatch
      backButton.click()
      backButton.waitForNonExistence(timeout: 5.0)
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
   func testSimmpleShowInfo() throws {
      let app = XCUIApplication()
      app.activate()
      app/*@START_MENU_TOKEN@*/.buttons["GraphNetworkView"]/*[[".groups",".buttons[\"Graph Network\"]",".buttons[\"GraphNetworkView\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.firstMatch.click()
      // pickup grid size from info box elements at top of screen
      XCTAssert(app.staticTexts["GraphNetworkViewGridWidth"].exists)
      let gridWidth : Int
      if let width = Int(app.staticTexts["GraphNetworkViewGridWidth"].value as! String) {
         gridWidth = width
      } else {
         gridWidth = 0
         XCTFail("gridth width value is not an integer value")
      }
      XCTAssert(app.staticTexts["GraphNetworkViewGridHeight"].exists)
      let gridHeight : Int
      if let height = Int(app.staticTexts["GraphNetworkViewGridHeight"].value as! String) {
         gridHeight = height
      } else {
         gridHeight = 0
         XCTFail("grid height value is not an integer value")
      }
      print(" the grid is \(gridHeight)x\(gridWidth) ")
      // now extract the drawing canvas element information
      let canvasElement = app.otherElements.matching(identifier: "GraphNetworkViewCanvas").firstMatch
      let canvasFrame = canvasElement.frame
      print("Canvas is at \(canvasFrame.origin) and is \(canvasFrame.height)x\(canvasFrame.width) with size \(canvasFrame.size)")
      let factor = calcFactor(gridWidth: gridWidth, gridHeight: gridHeight, displaySize: canvasFrame.size)
      print("Factor is \(factor)")
      // now move cursor to upper left tag position and generate the pop over
      let xpos_5 = 5 * factor / canvasFrame.width
      let ypos_5 = 5 * factor / canvasFrame.height
      print("Initial x is \(xpos_5) and initial y is \(ypos_5)" )
      let pos5_5 = canvasElement.coordinate(withNormalizedOffset: CGVector(dx: xpos_5, dy: ypos_5))
      pos5_5.click()
      // Check that the correct position was checked
      XCTAssert(app.staticTexts["GraphNetworkViewPopupTagInfoXpos"].waitForExistence(timeout: 5))
      if let xpos = app.staticTexts["GraphNetworkViewPopupTagInfoXpos"].firstMatch.value as? String {
         XCTAssertEqual(xpos, "5", "Upper left x pos")
      } else {
         XCTFail("Tag Info xpos value not a String")
      }
      XCTAssert(app.staticTexts["GraphNetworkViewPopupTagInfoYpos"].exists)
      if let ypos = app.staticTexts["GraphNetworkViewPopupTagInfoYpos"].firstMatch.value as? String {
         XCTAssertEqual(ypos, "5", "Upper left y pos")
      } else {
         XCTFail("Tag Info ypos value not a String")
      }
   }
   
   // Test drag then tap of upper left object for correct tag info, followed by scale up and same tap
   //
   
   // Test scale followed by drag and then tap of upper left object for correct information
   //
   
   func testLaunchPerformance() throws {
      if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
         // This measures how long it takes to launch your application.
         measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
         }
      }
   }
   
   // Helper copied from project file GraphNetworkView.swift
   // This needs to be replaced.
//   func calcFactor(gridWidth: Int, gridHeight: Int, displaySize: CGSize) -> Double {
//      let minFactor: Double = 10.0
//      let factorWidth = displaySize.width / Double(gridWidth)
//      let factorHeight = displaySize.height / Double(gridHeight)
//      let factor = Double.maximum(minFactor, Double.minimum(factorWidth, factorHeight))
//      return factor
//   }

}
