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
   let test1aPaths: Array<Set<Int>> = [[1,3], [1,2,4], [3,4],[4,5]]
   let test1CnxnCount = [3,2,2,4,1]
   let test1PathCount = [2,1,2,3,1]
   let test2Paths: Array<Set<Int>> = [[5,6], [4,6], [5,7]]
   
    override func setUpWithError() throws {
       // Put setup code here.  Method called before the invocation of each test in the class
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testConnectionCounts() throws {
       let testGraph = UndirectedGraph(nodes: 7, adjustment: 0)
       for p in test1Paths {
          testGraph.add(list: p)
       }
       XCTAssertEqual(testGraph.numListOccurrences, test1Paths.count, "Wrong number of connections")
       for n in 0..<testGraph.nodes {
          XCTAssertEqual(testGraph.getNumNodesCoinciding(node: n), test1CnxnCount[n], "Wrong connection count for node \(n)")
          XCTAssertEqual(testGraph.getNumPath(node: n), test1PathCount[n], "Wrong path count for node \(n)")
       }
    }
   
   func testSingleItemPaths() throws {
      let testGraph = UndirectedGraph(nodes: 8, adjustment: 0)
      for p in test1Paths {
         testGraph.add(list: p)
      }
      for p in test2Paths {
         testGraph.add(list: p)
      }
      let stats = testGraph.distanceStats(typ: .PathLength)
      XCTAssertEqual(stats.count, 28, "Wrong item count")
      XCTAssertEqual(testGraph.distance(typ: .PathLength, node1: 0, node2: 7), 5, "Wrong path length")
      XCTAssertEqual(testGraph.distance(typ: .TagsetJaccard, node1: 0, node2: 4), 0.867, accuracy: 0.001, "Wrong Tagset Length for 0,4")
      XCTAssertEqual(testGraph.distance(typ: .ItemsetJaccard, node1: 0, node2: 4), 1.5, accuracy: 0.01, "Wrong Itemset Length for 0,4")
      XCTAssertEqual(testGraph.distance(typ: .TagsetJaccard, node1: 1, node2: 5), 2.07, accuracy: 0.01, "Wrong TagSet Length for 1,5")
   }
   
   func testAdjustment() throws {
      let t1 = UndirectedGraph(nodes: 5, adjustment: -1)
      for p in test1aPaths {
         t1.add(list: p)
      }
      XCTAssertEqual(t1.numListOccurrences, test1Paths.count, "Wrong number of connections")
      for n in 1...t1.nodes {
         XCTAssertEqual(t1.getNumNodesCoinciding(node: n), test1CnxnCount[n], "Wrong connection count for node \(n)")
         XCTAssertEqual(t1.getNumPath(node: n), test1PathCount[n], "Wrong path count for node \(n)")
      }
   }
   
   func testZeroNodes() throws {
      let t0 = UndirectedGraph(nodes: 0)
      let s0Jaccard = t0.distanceStats(typ: .ItemsetJaccard)
      let s0JaccardHist1 = t0.histogram(type: .ItemsetJaccard, bins: 1)
      XCTAssertEqual(s0Jaccard.count, 0, "Wrong count")
      XCTAssertEqual(s0JaccardHist1[0].count, 0, "Wrong count on histogram")
   }
   
   func testGenDataDefault() throws {
      let genParms = DataParameters()
      let genCollection = GeneratedCollection(parameters: genParms)
      let testUsedNodes = genCollection.numTags-genCollection.numUnusedTags
      let testCount = (testUsedNodes*(testUsedNodes-1))/2
      let testGraph = UndirectedGraph(nodes: genCollection.numTags, adjustment: -1)
      for item in genCollection.items {
         testGraph.add(list: item.tagIdList)
      }
      let stat = testGraph.distanceStats(typ: .PathLength)
      XCTAssertEqual(stat.count, testCount, "Incorrect number of active nodes")
   }

    func testPerformanceStats() throws {
       let testGraph = UndirectedGraph(nodes: 7, adjustment: 0)
       for p in test1Paths {
          testGraph.add(list: p)
       }
        self.measure {
           let stats = testGraph.distanceStats(typ: .PathLength)
           XCTAssertEqual(stats.count, 10, "Wrong count returned")
           XCTAssertEqual(stats.lowBound, 1.0, "Wrong lower bound returned")
           XCTAssertEqual(stats.highBound, 2.0, "Wrong higher bound returned")
        }
    }

}
