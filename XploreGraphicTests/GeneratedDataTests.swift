//
//  GeneratedDataTests.swift
//  XploreGraphicTests
//
//  Created by John Holt on 12/24/25.
//

import XCTest

@testable
import XploreGraphic

final class GeneratedDataTests: XCTestCase {
   let stdItemFreqs: [Float] = [0.0, 0.2, 0.4, 0.2, 0.1, 0.1]     // by cardinality of the assigned set of tags
   let stdAvgFreq: Float = 0.2
   let stdMaxFreq: Float = 0.3

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
   
   func testCardinalityDistribution() throws {
      let numItems = 100
      let numTags = 50
      let parm = DataParameters(numItems: numItems, numTags: numTags, forceUnusedTags: false, pctItemTable: stdItemFreqs, avgTagFreq: stdAvgFreq, maxTagFreq: stdMaxFreq)
      let data = GeneratedCollection(parameters: parm)
      let rqstCards = data.numItemsByTagsetCard
      let builtCards = data.builtItemsByCard
      XCTAssertEqual(rqstCards.count, builtCards.count, "Requested versus Built Cardinality number of entries")
      XCTAssertEqual(rqstCards, builtCards, "Requested versus Built items by cardinalty")
   }
   
   func testTagAssignment2Few() throws {
      let numItems = 200
      let numTags = 80     // will be bumped up to 100
      let parm = DataParameters(numItems: numItems, numTags: numTags, forceUnusedTags: false, pctItemTable: stdItemFreqs, avgTagFreq: stdAvgFreq, maxTagFreq: stdMaxFreq)
      let data = GeneratedCollection(parameters: parm)
      let items = data.items
      XCTAssertEqual(data.numTags, 100, "Number of tags built")
      XCTAssertEqual(data.saved.numTags, 80, "Number of tags requested")
      XCTAssertEqual(items[19].tagIdList, [96,97,98,99,100], "Tags assigned to 20")
      XCTAssertEqual(items[20].tagIdList, [1,2,3,4], "tags assigned to 21")
      XCTAssertEqual(items[40].tagIdList, [81,82,83], "Tags assigned to 41")
      XCTAssertEqual(items[80].tagIdList, [1,2], "Tags assigned to 81")
      XCTAssertEqual(items[160].tagIdList, [61], "Tags assigned to 161")
   }
   
   func testTagAssignmentLowFreq() throws {
      let numItems = 1000
      let numTags = 200
      let avgFreq: Float = 0.01
      let maxFreq: Float = 0.10
      let parm = DataParameters(numItems: numItems, numTags: numTags, forceUnusedTags: false, pctItemTable: stdItemFreqs, avgTagFreq: avgFreq, maxTagFreq: maxFreq)
      let data = GeneratedCollection(parameters: parm)
      let items = data.items
      XCTAssertEqual(items[99].tagIdList, [96,97,98,99,100], "Tags assigned to 99")
      XCTAssertEqual(items[199].tagIdList, [97,98,99,100], "Tags assigned to 200")
      XCTAssertEqual(items[399].tagIdList, [106,107,108], "Tags assigned to 400")
      XCTAssertEqual(items[799].tagIdList, [3,4], "Tags assigned to 800")
      XCTAssertEqual(items[839].tagIdList, [4], "Tag assigned to 840")
      XCTAssertEqual(items[840].tagIdList, [], "No tags assigned to 841")
      XCTAssertEqual(items[999].tagIdList, [], "No tags assigned to 1000")
   }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
   
   func testPerformance1000Items() throws {
      let numItems = 1000
      let numTags = 200       // will be bumped to 250
      let avgFreq: Float = 0.10
      let maxFreq: Float = 0.20
      let parm = DataParameters(numItems: numItems, numTags: numTags, forceUnusedTags: false, pctItemTable: stdItemFreqs, avgTagFreq: avgFreq, maxTagFreq: maxFreq)
      self.measure {
         let data = GeneratedCollection(parameters: parm)
         XCTAssertEqual(data.numTags, 250, "Tags increased from 200 to 250 to accomodate average freq")
      }
   }

}
