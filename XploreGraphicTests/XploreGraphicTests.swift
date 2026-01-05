//
//  XploreGraphicTests.swift
//  XploreGraphicTests
//
//  Created by John Holt on 8/9/24.
//

import XCTest

@testable
import XploreGraphic

final class XploreGraphicTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
   
   /// Test the calculation to force more tags based upon the value of the average tag frequency and the number of tags requested
   func testRequiredTagCheck() {
      let parm1 = DataParameters(numItems:50, numTags: 4, pctItemTable: [0.0, 1.0], avgTagFreq: 0.1, maxTagFreq: 0.2)
      let ck1 = GeneratedCollection(parameters: parm1)
      XCTAssertEqual(ck1.numTags, 5, "Number of tags not increased to 5")
   }
   /// Test forcing the average frequency to not exceed the max frequency
   func testAvgMaxCheck() {
      let parm1 = DataParameters(numItems: 50, numTags: 4, pctItemTable: [0.0, 1.0], avgTagFreq: 0.2, maxTagFreq: 0.1)
      let ck1 = GeneratedCollection(parameters: parm1)
      XCTAssertEqual(ck1.avgFreq, ck1.maxFreq, "Average and Maximum frequencies not forced equal")
   }
   /// Test the calculation to force more tags based upon needing unused tags and the average frequency value
   func testRequiredUnusedTagCheck() {
      let parm1 = DataParameters(numItems: 50, numTags: 5, forceUnusedTags: true, pctItemTable: [0.0, 1.0], avgTagFreq: 0.1, maxTagFreq: 0.2)
      let ck1 = GeneratedCollection(parameters: parm1)
      XCTAssertEqual(ck1.numTags, 7, "Number of tags not increased to 7")
   }
   /// Test number of items by cardinality
   func testItemsCardBase() {
      let parm1 = DataParameters(numItems:50, numTags: 5, pctItemTable: [0.0, 1.0], avgTagFreq: 0.1, maxTagFreq: 0.2)
      let ck1 = GeneratedCollection(parameters: parm1)
      XCTAssertEqual(ck1.numItemsByTagsetCard.count, 2, "Number of item cardinalities not 2")
      XCTAssertEqual(ck1.numItemsByTagsetCard[0], 0, "number of items with cardinality 0 not zero")
      XCTAssertEqual(ck1.numItemsByTagsetCard[1], 50, "number of items with cardinality 1 not 50")
   }
   /// Test scaling the cardinality percentages to meet 100%
   func testItemsCardScale() {
      let parm1 = DataParameters(numItems: 100, numTags: 10, pctItemTable: [0.0, 0.2, 0.2, 0.1], avgTagFreq: 0.1, maxTagFreq: 0.2)
      let parm2 = DataParameters(numItems: 100, numTags: 10, pctItemTable: [0.0, 0.5, 0.5, 0.25], avgTagFreq: 0.1, maxTagFreq: 0.2)
      let ck1 = GeneratedCollection(parameters: parm1)
      XCTAssertEqual(ck1.numItemsByTagsetCard.count, 4, "Number of item cardinalities not 4")
      XCTAssertEqual(ck1.numItemsByTagsetCard[0], 0, "number of items with cardinality 0 not zero")
      XCTAssertEqual(ck1.numItemsByTagsetCard[1], 40, "number of items with cardinality 1 not 40")
      XCTAssertEqual(ck1.numItemsByTagsetCard[2], 40, "number of items with cardinality 2 not 40")
      XCTAssertEqual(ck1.numItemsByTagsetCard[3], 20, "number of items with cardinality 3 not 20")
      let ck2 = GeneratedCollection(parameters: parm2)
      XCTAssertEqual(ck2.numItemsByTagsetCard.count, 4, "Number of item cardinalities not 4")
      XCTAssertEqual(ck2.numItemsByTagsetCard[0], 0, "number of items with cardinality 0 not zero")
      XCTAssertEqual(ck2.numItemsByTagsetCard[1], 40, "number of items with cardinality 1 not 40")
      XCTAssertEqual(ck2.numItemsByTagsetCard[2], 40, "number of items with cardinality 2 not 40")
      XCTAssertEqual(ck2.numItemsByTagsetCard[3], 20, "number of items with cardinality 3 not 20")
   }
   /// Test that there is a floor of 1 for a non zero percentage for zero car items
   func testItemsCardFloor() {
      let parm1 = DataParameters(numItems: 100, numTags: 10, pctItemTable: [0.008, 0.2, 0.5, 0.292], avgTagFreq: 0.1, maxTagFreq: 0.2)
      let ck1 = GeneratedCollection(parameters: parm1)
      XCTAssertEqual(ck1.numItemsByTagsetCard.count, 4, "Number of item cardinalities not 4")
      XCTAssertEqual(ck1.numItemsByTagsetCard[0], 1, "number of items with cardinality 0 not 1")
      XCTAssertEqual(ck1.numItemsByTagsetCard[1], 20, "number of items with cardinality 1 not 20")
      XCTAssertEqual(ck1.numItemsByTagsetCard[2], 50, "number of items with cardinality 2 not 50")
      XCTAssertEqual(ck1.numItemsByTagsetCard[3], 29, "number of items with cardinality 3 not 29")
   }

    func testPerformanceExample() throws {
       let parm1 = DataParameters(numItems: 100, numTags: 50, forceUnusedTags: false, pctItemTable: [0.0, 0.2,0.4,0.2,0.1,0.1], avgTagFreq: 0.2, maxTagFreq: 0.3)
       let genData = GeneratedCollection(parameters: parm1)
       let graph = UndirectedGraph(nodes: genData.numTags, adjustment: -1)
       for item in genData.items {
          graph.add(list: item.tagIdList)
       }
        measure {
           let stats = graph.distanceStats(typ: .PathLength, forceCalc: true)
           XCTAssertEqual(stats.count, 1225, "Wrong count returned")
           XCTAssertEqual(stats.lowBound, 1.0, "Wrong lower bound returned")
           XCTAssertEqual(stats.highBound, 19.0, "Wrong higher bound returned")        }
    }

   func testPerformanceTag500() throws {
      let parm1 = DataParameters(numItems: 500, numTags: 500, forceUnusedTags: false, pctItemTable: [0.0, 0.2,0.4,0.2,0.1,0.1], avgTagFreq: 0.2, maxTagFreq: 0.3)
      let genData = GeneratedCollection(parameters: parm1)
      let graph = UndirectedGraph(nodes: genData.numTags, adjustment: -1)
      for item in genData.items {
         graph.add(list: item.tagIdList)
      }
      measure {
         let stats = graph.distanceStats(typ: .PathLength, forceCalc: true)
         XCTAssertEqual(stats.count, 124750, "Wrong count returned")
         XCTAssertEqual(stats.lowBound, 0.0, "Wrong lower bound returned")
         XCTAssertEqual(stats.highBound, 11.0, "Wrong higher bound returned")
      }
   }

}
