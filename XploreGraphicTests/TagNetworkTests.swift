//
//  UndirectedGraphTests.swift
//  XploreGraphicTests
//
//  Created by John Holt on 12/22/24.
//

import XCTest

@testable
import XploreGraphic

final class UndirectedGraphTests: XCTestCase {
   let test1Paths: Array<Set<Int>> = [[0,2], [0,1,3], [2,3],[3,4]]
   let test1CnxnCount = [3,2,2,4,1]
   let test1PathCount = [2,1,2,3,1]
   let test2Paths: Array<Set<Int>> = [[5,6], [4,6], [5,7]]
   var testGraph = UndirectedGraph(nodes: 7, adjustment: 0)

    override func setUpWithError() throws {
       testGraph.pairOccurs.clear()
       for p in test1Paths {
          testGraph.add(list: p)
       }
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testConnectionCounts() throws {
       let t1 = UndirectedGraph(nodes: 5, adjustment: 0)
       for p in test1Paths {
          t1.add(list: p)
       }
       XCTAssertEqual(testGraph.numListOccurrences, test1Paths.count, "Wrong number of connections")
       for n in 0..<testGraph.nodes {
          XCTAssertEqual(testGraph.getNumNodesCoinciding(node: n), test1CnxnCount[n], "Wrong connection count for node \(n)")
          XCTAssertEqual(testGraph.getNumPath(node: n), test1PathCount[n], "Wrong path count for node \(n)")
       }
    }
   
   func testAdjustment() throws {
      
   }

    func testPerformanceStats() throws {
        // This is an example of a performance test case.
        self.measure {
           let stats = testGraph.distanceStats(typ: .PathLength)
           XCTAssertEqual(stats.count, 10, "Wrong count returned")
           XCTAssertEqual(stats.lowBound, 1.0, "Wrong lower bound returned")
           XCTAssertEqual(stats.highBound, 2.0, "Wrong higher bound returned")
        }
    }

}
