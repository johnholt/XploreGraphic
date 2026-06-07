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

let margin = 5 // tagnetworkDisplayMargin

final class XploreGraphicUITests: XCTestCase {
   let app = XCUIApplication()
   let topLeftGridPoint = CGPoint(x: margin, y: margin)
   
   override func setUpWithError() throws {
      // Put setup code here. This method is called before the invocation of each test method in the class.
#if os(iOS)
      XCUIDevice.shared.orientation = UIDeviceOrientation.landscapeLeft
#endif
      // In UI tests it is usually best to stop immediately when a failure occurs.
      continueAfterFailure = false
      
      // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
   }
   
   override func tearDownWithError() throws {
      // Put teardown code here. This method is called after the invocation of each test method in the class.
   }
   
   // Test the enabled/disabled state of variable state buttons and menu items
   func testDisabledState() throws {
      app.launch()
      // Try to bring up menu bar for iPad
#if os(iOS)
      print("Unable to activate menu bar")
#endif // os(iOS)
      // Test initial conditions
      XCTAssert(app.buttons["Accept"].waitForExistence(timeout: 5))
      XCTAssertFalse(app.buttons["Accept"].isEnabled)
     // Now test the menuBar if available
      if app.menuBarItems["Graph"].exists {  // Q. Is the Graph menu is present
         // The Graph menu items should only be enabled when viewiing a graph network diagram
         XCTAssertFalse(app.menuItems["Magnify"].isEnabled)
         XCTAssertFalse(app.menuItems["Reduce"].isEnabled)
         XCTAssertFalse(app.menuItems["Reset"].isEnabled)
         // Navigate to graph view and check for being enabled
         app.buttons["GraphNetworkView"].firstMatch.click()
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
      } else {
#if os(macOS)
         XCTFail("menu bar element not located")
#endif
         print("No menu bar element found")
      }
   }
   
   // Test production of 2nd level screens and the navigation back button
   func testNavigation() throws {
      app.launch()
      app.buttons["TagList"].firstMatch.click()
      XCTAssertTrue(app.scrollViews["TagListScroll"].exists)
      app.buttons["Back"].firstMatch.click()
      app.buttons["ItemList"].firstMatch.click()
      XCTAssertTrue(app.scrollViews["ItemListScroll"].exists)
      app.buttons["Back"].firstMatch.click()
      app.buttons["GraphDataView"].firstMatch.click()
      XCTAssertTrue(app.buttons["GraphDataViewRefreshButton"].exists)
      app.buttons["Back"].firstMatch.click()
      app.buttons["GraphNetworkView"].firstMatch.click()
      XCTAssertTrue(app.otherElements["GraphNetworkViewCanvas"].exists)
      app.buttons["Back"].firstMatch.click()
   }
   
   // Test histogram features in Graph Data view
   func testHistogramFeatures() throws {
      app.launch()
      app.buttons["GraphDataView"].firstMatch.click()
      XCTAssert(app.steppers["GraphDataViewNumBinsStepper"].exists)
      XCTAssert(app.staticTexts["GraphDataViewNumBinsStepperText"].exists)
      if let initialBucketsText = staticText("GraphDataViewNumBinsStepperText") {
         XCTAssertEqual(initialBucketsText, "Number of bins: 4", "Wrong initial value for number of buckets")
      } else {
         XCTFail("Number of bins message not a string")
      }
      // initial state of stepper confirmed, now modify
      //app.steppers["GraphDataViewNumBinsStepper"].incrementArrows.firstMatch.click()
      stepperAction(name: "GraphDataViewNumBinsStepper", action: StepperAction.incr)
      //app.steppers["GraphDataViewNumBinsStepper"].incrementArrows.firstMatch.click()
      stepperAction(name: "GraphDataViewNumBinsStepper", action: StepperAction.incr)
      // Now check state of the picker.  Approach varies by platform
#if os(macOS)
      XCTAssertTrue(app.popUpButtons["GraphDataViewDistPickPathLength"].exists)
#else
      XCTAssertTrue(app.buttons["GraphDataViewDistancePicker"].exists)
      XCTAssertTrue(app.staticTexts["Path Length"].exists)     // accessibilityIdentifier is not in the objects
#endif
      // Pick Jaccard distance of the TagSet.  Varies by platform
#if os(macOS)
      app.popUpButtons["GraphDataViewDistPickPathLength"].firstMatch.click()
      app.menuItems["GraphDataViewDistPickTagsetJaccard"].firstMatch.click()
#else
      app.buttons["GraphDataViewDistancePicker"].firstMatch.click()
      app.buttons["GraphDataViewDistPickTagsetJaccard"].firstMatch.click()
#endif
      // Refresh to histogram based on changed parameters
      app.buttons["GraphDataViewRefreshButton"].firstMatch.click()
      // Now we check the results by looking at the High Bound value
      XCTAssertTrue(app.staticTexts["GraphDataViewHighBound"].exists)
      if let resultHighBound = Double(staticText("GraphDataViewHighBound") ?? "") {
         XCTAssertEqual(resultHighBound, 1.144, accuracy: 0.05, "HighBound for the distance incorrect")
      } else {
         XCTFail("No HighBound found")
      }
      // Go back and then re-enter to confirm state is maintained
      app.buttons["Back"].firstMatch.click()
      app.buttons["GraphDataView"].firstMatch.click()
      // first check the bins
      if let reEntryBucketsText = staticText("GraphDataViewNumBinsStepperText") {
         XCTAssertEqual(reEntryBucketsText, "Number of bins: 10", "Wrong re-entry value for number of buckets")
      } else {
         XCTFail("Number of bins message not a string")
      }
      // then check the type of distance measure.  Steps vary by platform
#if os(macOS)
      if let reEntryPickerLabel = app.popUpButtons["GraphDataViewDistancePicker"].firstMatch.value as? String {
         XCTAssertEqual(reEntryPickerLabel, "Tagset Jaccard")
      } else {
         XCTFail("Picker label is not text")
      }
#elseif os(iOS)
      let pickerButton = app.buttons["GraphDataViewDistancePicker"].firstMatch
      XCTAssertEqual(pickerButton.children(matching: .staticText).firstMatch.label, "Tagset Jaccard")
#else
      XCTFail("Unknown platform")
#endif
   }
   
   // Test tap of upper left object for correct tag information
   func testSimpleShowInfo() throws {
      app.launch()
      app.buttons["GraphNetworkView"].firstMatch.click()
      // pickup grid size from info box elements at top of screen
      let gridSize = extractSize(nameHeight: "GraphNetworkViewGridHeight", nameWidth: "GraphNetworkViewGridWidth")
      print("The grid height and width is \(gridSize.height)x\(gridSize.width) ")
      // now extract the drawing canvas element information
      let canvasElement = app.otherElements.matching(identifier: "GraphNetworkViewCanvas").firstMatch
      let canvasFrame = canvasElement.frame
      print("Canvas is at \(canvasFrame.origin) and height and width is \(canvasFrame.height)x\(canvasFrame.width) with size \(canvasFrame.size)")
      let factor = calcFactor(gridSize: gridSize, displaySize: canvasFrame.size)
      print("Factor is \(factor)")
      // now move cursor to upper left tag position and generate the pop over
      let xTopLeftOffset = topLeftGridPoint.x * factor / canvasFrame.width
      let yTopLeftOffset = topLeftGridPoint.y * factor / canvasFrame.height
      print("Initial x is \(xTopLeftOffset) and initial y is \(yTopLeftOffset)" )
      let coordinate = canvasElement.coordinate(withNormalizedOffset: CGVector(dx: xTopLeftOffset, dy: yTopLeftOffset))
      print("Coordinate position: \(coordinate.screenPoint)")
      coordinate.click()
      // Check that the correct position was checked
      XCTAssert(app.staticTexts["GraphNetworkViewPopupTagInfoXpos"].waitForExistence(timeout: 5))
      let screenshot = canvasElement.screenshot()
      let attachment = XCTAttachment(screenshot: screenshot)
      add(attachment)
      if let tapInfo = staticText("GraphNetworkViewPopupTapInfo") {
         print("Tap Info \(tapInfo)")
      }
      if let adjustInfo = staticText("GraphNetworkViewPopupAdjustInfo") {
         print("Adjustment info \(adjustInfo)")
      }
      if let searchArg = staticText("GraphNetworkViewPopupSearchArgs") {
         print("Search arguments: \(searchArg)")
      }
      if let searchRslt = staticText("GraphNetworkViewPopupSearchResult") {
         print("Factor and results: \(searchRslt)")
      }
     if let xpos = staticText("GraphNetworkViewPopupTagInfoXpos") {
         XCTAssertEqual(xpos, "5", "Upper left x pos")
      } else {
         XCTFail("Tag Info xpos value not a String")
      }
      XCTAssert(app.staticTexts["GraphNetworkViewPopupTagInfoYpos"].exists)
      if let ypos = staticText("GraphNetworkViewPopupTagInfoYpos") {
         XCTAssertEqual(ypos, "5", "Upper left y pos")
      } else {
         XCTFail("Tag Info ypos value not a String")
      }
   }
   
   // Test drag to right and down then tap of upper left object for correct tag info, followed by scale up and same tap.
   //Use menu on macOS and pinch gesture for iOS for scaling up.
   func testDragScale() throws {
      app.launch()
      app.buttons["GraphNetworkView"].firstMatch.click()
      // pickup grid size from info box elements at top of screen
      let gridSize = extractSize(nameHeight: "GraphNetworkViewGridHeight", nameWidth: "GraphNetworkViewGridWidth")
      print("Gridsize is: (\(gridSize)) with width \(gridSize.width) and height \(gridSize.height)")
       // now extract the drawing canvas element information
      let canvasElement = app.otherElements.matching(identifier: "GraphNetworkViewCanvas").firstMatch
      let canvasFrame = canvasElement.frame
      print("Canvas (\(canvasFrame.size)) and width and height is (\(canvasFrame.width),\(canvasFrame.height)), position (\(canvasFrame.origin))")
      let factor = calcFactor(gridSize: gridSize, displaySize: canvasFrame.size)
      print("factor is \(factor)")
      // Use just inside the origin of the frame as a base to create specific co-ordinates for a tap to clear popover
      let nearOrigin = canvasElement.coordinate(withNormalizedOffset: CGVector(dx: 0.001, dy: 0.001))
      print("origin co-ord is (\(nearOrigin.screenPoint.x),\(nearOrigin.screenPoint.y))")
      // Pick a spot for the drag to end.
      let midpoint = nearOrigin.withOffset(CGVector(dx: 0.5*canvasElement.frame.width, dy: 0.5*canvasElement.frame.height))
      print("midpoint co-ord is (\(midpoint.screenPoint.x), \(midpoint.screenPoint.y))")
      // Use the top left grid point as the drag start and the click location
      let topleft = nearOrigin.withOffset(CGVector(dx: topLeftGridPoint.x * factor, dy: topLeftGridPoint.y * factor))
      print("topleft co-ord is (\(topleft.screenPoint.x), \(topleft.screenPoint.y))")
      // Now execute the drag
      topleft.press(forDuration: 2.0, thenDragTo: midpoint, withVelocity: .slow, thenHoldForDuration: 2.0)
      // Click the topleft and verify that we can get the correct info after the drag
      topleft.click()
      // Check the results in the popup
      XCTAssert(app.staticTexts["GraphNetworkViewPopupTagInfoXpos"].waitForExistence(timeout: 5))
      let screenshotDrag = canvasElement.screenshot()
      let attachmentDrag = XCTAttachment(screenshot: screenshotDrag)
      attachmentDrag.name = "GraphNetworkViewAfterDrag"
      attachmentDrag.lifetime = .deleteOnSuccess
      add(attachmentDrag)
      if let tapInfo = staticText("GraphNetworkViewPopupTapInfo") {
         print("Tap Info \(tapInfo)")
      }
      if let adjustInfo = staticText("GraphNetworkViewPopupAdjustInfo") {
         print("Adjustment info \(adjustInfo)")
      }
      if let searchArg = staticText("GraphNetworkViewPopupSearchArgs") {
         print("Search arguments: \(searchArg)")
      }
      if let searchRslt = staticText("GraphNetworkViewPopupSearchResult") {
         print("Factor and results: \(searchRslt)")
      }
      if let xpos = staticText("GraphNetworkViewPopupTagInfoXpos") {
         XCTAssertEqual(xpos, "5", "Upper left x pos")
      } else {
         XCTFail("Tag Info xpos value not a String")
      }
      XCTAssert(app.staticTexts["GraphNetworkViewPopupTagInfoYpos"].exists)
      if let ypos = staticText("GraphNetworkViewPopupTagInfoYpos") {
         XCTAssertEqual(ypos, "5", "Upper left y pos")
      } else {
         XCTFail("Tag Info ypos value not a String")
      }
      // Get rid of popup
      if app.popovers.element.exists {
         nearOrigin.tap()
      }
      // Now scale, using menu for macOS and gesture for iOS
#if os(macOS)
      app.menuItems["Magnify"].firstMatch.click()  // 1 Magnify click adds 0.25 to scale
      let scaleFactor = 1.25
      let scaleFactorAdj = 1.25
#elseif os(iOS)
      let scaleFactor = 1.25
      let scaleFactorAdj = 2.50 // pinch operation appears to deliver about twice amount requested at this level
      canvasElement.pinch(withScale: 1.25, velocity: 1.5)
#else
      XCTFail("Unknown platform")
#endif
      // Determine location of topleft post scaling
      print("Canvas (\(canvasFrame.size)) and width and height is (\(canvasFrame.width),\(canvasFrame.height)), position (\(canvasFrame.origin))")
      // 1.25 was requested, but pinch provides about twice as much
      let topleftScaled = nearOrigin.withOffset(CGVector(dx: topLeftGridPoint.x * factor * scaleFactorAdj,
                                                         dy: topLeftGridPoint.y * factor * scaleFactorAdj))
      print("topleftScaled co-ord is (\(topleftScaled.screenPoint.x), \(topleftScaled.screenPoint.y))")
      topleftScaled.click()
      // Check that the correct position was clicked
      XCTAssert(app.staticTexts["GraphNetworkViewPopupTagInfoXpos"].waitForExistence(timeout: 5))
      let screenshotScale = canvasElement.screenshot()
      let attachmentScale = XCTAttachment(screenshot: screenshotScale)
      attachmentScale.name = "GraphNetworkViewAfterScale"
      attachmentScale.lifetime = .deleteOnSuccess
      add(attachmentScale)
      if let tapInfo = staticText("GraphNetworkViewPopupTapInfo") {
         print("Tap Info \(tapInfo)")
      }
      if let adjustInfo = staticText("GraphNetworkViewPopupAdjustInfo") {
         print("Adjustment info \(adjustInfo)")
      }
      if let searchArg = staticText("GraphNetworkViewPopupSearchArgs") {
         print("Search arguments: \(searchArg)")
      }
      if let searchRslt = staticText("GraphNetworkViewPopupSearchResult") {
         print("Factor and results: \(searchRslt)")
      }
      if let xpos = staticText("GraphNetworkViewPopupTagInfoXpos") {
         XCTAssertEqual(xpos, "5", "Upper left x pos")
      } else {
         XCTFail("Tag Info xpos value not a String")
      }
      XCTAssert(app.staticTexts["GraphNetworkViewPopupTagInfoYpos"].exists)
      if let ypos = staticText("GraphNetworkViewPopupTagInfoYpos") {
         XCTAssertEqual(ypos, "5", "Upper left y pos")
      } else {
         XCTFail("Tag Info ypos value not a String")
      }
   }
   
   // Test scale followed by drag and then tap of upper left object for correct information
   //Use keyboard shortcuts to scale for both macOS and iOS
   func testScaleDrag() throws {
      app.launch()
      app.buttons["GraphNetworkView"].firstMatch.click()
      // pickup grid size from info box elements at top of screen
      let gridSize = extractSize(nameHeight: "GraphNetworkViewGridHeight", nameWidth: "GraphNetworkViewGridWidth")
      print("Gridsize is: (\(gridSize)) with width \(gridSize.width) and height \(gridSize.height)")
      // now extract the drawing canvas element information
      let canvasElement = app.otherElements.matching(identifier: "GraphNetworkViewCanvas").firstMatch
      let canvasFrame = canvasElement.frame
      print("Canvas (\(canvasFrame.size)) and width and height is (\(canvasFrame.width),\(canvasFrame.height)), position (\(canvasFrame.origin))")
      let factor = calcFactor(gridSize: gridSize, displaySize: canvasFrame.size)
      print("factor is \(factor)")
      // Use just inside the origin of the frame as a base to create specific co-ordinates for a tap to clear popover
      let nearOrigin = canvasElement.coordinate(withNormalizedOffset: CGVector(dx: 0.001, dy: 0.001))
      print("origin co-ord is (\(nearOrigin.screenPoint.x),\(nearOrigin.screenPoint.y))")
      // Zoom in using shortcut
      canvasElement.typeKey("+", modifierFlags: .command)
      // Pick a spot for the drag to end.
      let midpoint = nearOrigin.withOffset(CGVector(dx: 0.5*canvasElement.frame.width, dy: 0.5*canvasElement.frame.height))
      print("midpoint co-ord is (\(midpoint.screenPoint.x), \(midpoint.screenPoint.y))")
      // Use the top left grid point as the drag start and the click location
      let topleft = nearOrigin.withOffset(CGVector(dx: topLeftGridPoint.x * factor, dy: topLeftGridPoint.y * factor))
      print("topleft co-ord is (\(topleft.screenPoint.x), \(topleft.screenPoint.y))")
      // Now execute the drag
      topleft.press(forDuration: 2.0, thenDragTo: midpoint, withVelocity: .slow, thenHoldForDuration: 2.0)
      // Click the topleft and verify that we can get the correct info after the drag
      topleft.click()
      // Check the results in the popup
      XCTAssert(app.staticTexts["GraphNetworkViewPopupTagInfoXpos"].waitForExistence(timeout: 5))
      let screenshotDrag = canvasElement.screenshot()
      let attachmentDrag = XCTAttachment(screenshot: screenshotDrag)
      attachmentDrag.name = "GraphNetworkViewAfterDrag"
      attachmentDrag.lifetime = .deleteOnSuccess
      add(attachmentDrag)
      if let tapInfo = staticText("GraphNetworkViewPopupTapInfo") {
         print("Tap Info \(tapInfo)")
      }
      if let adjustInfo = staticText("GraphNetworkViewPopupAdjustInfo") {
         print("Adjustment info \(adjustInfo)")
      }
      if let searchArg = staticText("GraphNetworkViewPopupSearchArgs") {
         print("Search arguments: \(searchArg)")
      }
      if let searchRslt = staticText("GraphNetworkViewPopupSearchResult") {
         print("Factor and results: \(searchRslt)")
      }
      if let xpos = staticText("GraphNetworkViewPopupTagInfoXpos") {
         XCTAssertEqual(xpos, "5", "Upper left x pos")
      } else {
         XCTFail("Tag Info xpos value not a String")
      }
      XCTAssert(app.staticTexts["GraphNetworkViewPopupTagInfoYpos"].exists)
      if let ypos = staticText("GraphNetworkViewPopupTagInfoYpos") {
         XCTAssertEqual(ypos, "5", "Upper left y pos")
      } else {
         XCTFail("Tag Info ypos value not a String")
      }
   }
   
   func testLaunchPerformance() throws {
      if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
         // This measures how long it takes to launch your application.
         measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
         }
      }
   }
   
   
   // Helper functions to account for differences in the XCUIAutomation objects between platforms
   
   func staticText(_ name: String) -> String? {
      var result: String?
#if os(macOS)
      result = app.staticTexts[name].firstMatch.value as? String
#elseif os(iOS)
      result = app.staticTexts[name].firstMatch.label
#else
      result = nil
#endif
      return result
   }
   
   enum StepperAction {
      case incr
      case decr
   }
   
   func stepperAction(name: String, action: StepperAction) {
      switch action {
         case .incr:
            #if os(macOS)
            app.steppers[name].incrementArrows.firstMatch.click()
            #elseif os(iOS)
            app.buttons[name+"-Increment"].firstMatch.click()
            #else
            XCTFail("Unknown platform")
            #endif
         case .decr:
            #if os(macOS)
            app.steppers[name].decrementArrows.firstMatch.click()
            #elseif os(iOS)
            app.buttons[name+"-Decrement"].firstMatch.click()
            #else
            XCTFail("Unknown platform")
            #endif
      }
   }
   
   func extractSize(nameHeight: String, nameWidth: String) -> CGSize {
      let gridWidth : Int
      if let width = Int(staticText(nameWidth) ?? "") {
         gridWidth = width
      } else {
         gridWidth = 0
         XCTFail("\(nameWidth) not numeric")
      }
      let gridHeight : Int
      if let height = Int(staticText(nameHeight) ?? "") {
         gridHeight = height
      } else {
         gridHeight = 0
         XCTFail("\(nameHeight) not numeric")
      }
      return CGSize(width: gridWidth, height: gridHeight)
   }
      
}
