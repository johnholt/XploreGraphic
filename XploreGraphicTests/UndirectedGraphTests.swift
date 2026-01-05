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
   let test3Paths: Array<Set<Int>> = [[0,1,2,3,4],[5,6,7,8],[9,10,11],[12,13],[13,14],[0,1],[2,3],[4,5],[6,7],[8],[9],[15]]
   
    override func setUpWithError() throws {
       // Put setup code here.  Method called before the invocation of each test in the class
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testConnectionCounts() throws {
       let testGraph = UndirectedGraph(nodes: 5, adjustment: 0)
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
         XCTAssertEqual(t1.getNumNodesCoinciding(node: n), test1CnxnCount[n-1], "Wrong connection count for node \(n)")
         XCTAssertEqual(t1.getNumPath(node: n), test1PathCount[n-1], "Wrong path count for node \(n)")
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
   
   func testIslands() throws {
      let t3 = UndirectedGraph(nodes: 16, adjustment: 0 )
      for path in test3Paths {
         t3.add(list: path)
      }
      let islands = t3.islandStats()  //t3.islandsFromDistanceMatrix()
      let islandMembers: Array<Set<Int>> = [[0,1,2,3,4,5,6,7,8], [9,10,11], [12,13,14], [15]]
      XCTAssertEqual(islands.count, 4, "Wrong number of islands")
      XCTAssertEqual(islands[0].nodes.count, 9, "Wrong number of nodes for island 0")
      XCTAssertEqual(islands[0].nodes, islandMembers[0], "Island 0 members wrong")
      XCTAssertEqual(islands[0].maxAdjacent, 5, "Wrong number of max adjacent nodes")
      XCTAssertEqual(islands[0].minAdjacent, 3, "Wrong number of min adjacent nodes")
      XCTAssertEqual(islands[0].avgAdjacent, 3.77, accuracy: 0.01, "Wrong value for average adjacents")
      XCTAssertEqual(islands[0].numWith1Adj, 0, "Wrong number of nodes with 1 adjacent")
      XCTAssertEqual(islands[0].numWith2Adj, 0, "Wrong number of nodes with 2 adjacent")
      XCTAssertEqual(islands[0].numWith3Adj, 3, "Wrong number of nodes with 3 adjacent")
      XCTAssertEqual(islands[0].numWith4Adj, 5, "Wrong number of nodes with 3 adjacent")
      XCTAssertEqual(islands[0].numWithMany, 1, "Wrong number of nodes with many adjcnt")
      XCTAssertEqual(islands[1].nodes.count, 3, "Wrong number of nodes for island 9")
      XCTAssertEqual(islands[1].nodes, islandMembers[1], "Island 9 members wrong")
      XCTAssertEqual(islands[2].nodes.count, 3, "Wrong number of nodes for island 12")
      XCTAssertEqual(islands[2].nodes, islandMembers[2], "Island 12 members wrong")
      XCTAssertEqual(islands[3].nodes.count, 1, "Wrong number of nodes for island 15")
      XCTAssertEqual(islands[3].nodes, islandMembers[3], "Island 15 members wrong")
   }
   
   func testDistanceCalc() throws {
      let t3 = UndirectedGraph(nodes: 16, adjustment: 0 )
      for path in test3Paths {
         t3.add(list: path)
      }
      let pathErrors = t3.validateDistanceMatrix(typ: .PathLength)
      XCTAssertEqual(pathErrors.count, 0, "\(pathErrors.count) path length errors found")
   }
   
   func testConnect() throws {
      let t3 = UndirectedGraph(nodes: 16, adjustment: 0 )
      for path in test3Paths {
         t3.add(list: path)
      }
      let nodeStats = t3.nodeConnectStats()  //t3.connectStatsFromDistanceMatrix()
      XCTAssertEqual(nodeStats.count, 16, "Wrong number of connect stats.")
      XCTAssertEqual(nodeStats[0].id, 0, "Bad ID on first entry, expected 0")
      XCTAssertEqual(nodeStats[1].numNoConnect, 7, "Expected 7 nodes not connected")
      XCTAssertEqual(nodeStats[1].numAdjacent, 4, "Expected 4 nodes adjacent")
      XCTAssertEqual(nodeStats[1].numIndirect, 4, "Expected 4 nodes to be indirect")
      XCTAssertEqual(nodeStats[1].minAdjTagset, 0.0, accuracy: 0.01, "Expected ~0.0 for minAdjTagset")
      XCTAssertEqual(nodeStats[1].maxAdjTagset, 0.17, accuracy: 0.01, "Expected ~0.17 for maxAdjTagset")
      XCTAssertEqual(nodeStats[1].avgAdjTagset, 0.04, accuracy: 0.01, "Expected ~0.04 for the avgAdjTagset")
      XCTAssertEqual(nodeStats[1].numBelowAvg, 3, "Expected 3 adjacent nodes below average")
      XCTAssertEqual(nodeStats[1].adjNodes, [0,2,3,4], "Wrong adjacent nodes")
      XCTAssertEqual(nodeStats[1].adjNumCommon[4], 5, "Wrong count for nodes in common wrt 1 and 4")
      XCTAssertEqual(nodeStats[1].adjTagsetDst[4]!, Float(0.17), accuracy: 0.01, "Wrong tagset distance between 1 and 4")
      XCTAssertEqual(nodeStats[4].numNoConnect, 7, "Expected 7 nodes not connected")
      XCTAssertEqual(nodeStats[4].numAdjacent, 5, "Expected 5 nodes adjacent")
      XCTAssertEqual(nodeStats[4].numIndirect, 3, "Expected 3 nodes to be indirect")
      XCTAssertEqual(nodeStats[4].minAdjTagset, 0.17, accuracy: 0.01, "Expected ~0.17 for minAdjTagset")
      XCTAssertEqual(nodeStats[4].maxAdjTagset, 0.78, accuracy: 0.01, "Expected ~0.78 for maxAdjTagset")
      XCTAssertEqual(nodeStats[4].avgAdjTagset, 0.29, accuracy: 0.01, "Expected ~0.29 for the avgAdjTagset")
      XCTAssertEqual(nodeStats[4].numBelowAvg, 4, "Expected 4 adjacent nodes below average")
      XCTAssertEqual(nodeStats[4].adjNodes, [0,1,2,3,5], "Wrong adjacent nodes")
      XCTAssertEqual(nodeStats[4].adjNumCommon[5], 2, "Wrong count for nodes in common wrt 4 and 5")
      XCTAssertEqual(nodeStats[4].adjTagsetDst[5]!, Float(0.78), accuracy: 0.01, "Wrong tagset distance between 4 and 5")
      XCTAssertEqual(nodeStats[5].numNoConnect, 7, "Expected 7 nodes not connected")
      XCTAssertEqual(nodeStats[5].numAdjacent, 4, "Expected 4 nodes adjacent")
      XCTAssertEqual(nodeStats[5].numIndirect, 4, "Expected 4 nodes to be indirect")
      XCTAssertEqual(nodeStats[5].minAdjTagset, 0.20, accuracy: 0.01, "Expected ~0.20 for minAdjTagset")
      XCTAssertEqual(nodeStats[5].maxAdjTagset, 0.78, accuracy: 0.01, "Expected ~0.78 for maxAdjTagset")
      XCTAssertEqual(nodeStats[5].avgAdjTagset, 0.35, accuracy: 0.01, "Expected ~0.35 for the avgAdjTagset")
      XCTAssertEqual(nodeStats[5].numBelowAvg, 3, "Expected 3 adjacent nodes below average")
      XCTAssertEqual(nodeStats[5].adjNodes, [4,6,7,8], "Wrong adjacent nodes")
      XCTAssertEqual(nodeStats[5].adjNumCommon[6], 4, "Wrong count for nodes in common wrt 5 and 6")
      XCTAssertEqual(nodeStats[5].adjTagsetDst[6]!, Float(0.20), accuracy: 0.01, "Wrong tagset distance between 5 and 6")
   }

    func testPerformanceStats() throws {
       let testGraph = UndirectedGraph(nodes: 7, adjustment: 0)
       for p in test1Paths {
          testGraph.add(list: p)
       }
        self.measure {
           let stats = testGraph.distanceStats(typ: .PathLength, forceCalc: true)
           XCTAssertEqual(stats.count, 10, "Wrong count returned")
           XCTAssertEqual(stats.lowBound, 1.0, "Wrong lower bound returned")
           XCTAssertEqual(stats.highBound, 2.0, "Wrong higher bound returned")
        }
    }
   
   func testPerformanceExample() throws {
      let t3 = UndirectedGraph(nodes: 16, adjustment: 0 )
      for path in test3Paths {
         t3.add(list: path)
      }
      self.measure {
         let islands = t3.islandStats()
         let connectionStats = t3.nodeConnectStats()
         XCTAssertEqual(islands.count, 4, "Wrong number of islands")
         XCTAssertEqual(connectionStats[15].adjNodes, [], "Adjacent node set not empty")
      }
   }
}
