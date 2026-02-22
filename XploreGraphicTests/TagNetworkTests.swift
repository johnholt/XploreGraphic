//
//  TagNetworkTests.swift
//  XploreGraphicTests
//
//  Created by John Holt on 12/2/25.
//

import XCTest
import Foundation

@testable
import XploreGraphic


final class TagNetworkTests: XCTestCase {
   let stdItemFreqs: [Float] = [0.0, 0.2, 0.4, 0.2, 0.1, 0.1]     // by cardinality of the assigned set of tags
   let stdAvgFreq: Float = 0.2
   let stdMaxFreq: Float = 0.3

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTinyNetwork() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
       let numItems = 10
       let numTags = 15
       let parm = DataParameters(numItems: numItems, numTags: numTags, forceUnusedTags: false, pctItemTable: stdItemFreqs, avgTagFreq: stdAvgFreq, maxTagFreq: stdMaxFreq)
       let data = GeneratedCollection(parameters: parm)
       let graph = UndirectedGraph(nodes: data.numTags, adjustment: -1)
       for item in data.items {
          graph.add(list: item.tagIdList)
       }
       var network = TagNetwork(graph, tags: data.tags)
       var islands = network.islands()
       var regions = network.regions()
       XCTAssertEqual(islands.count, 3, "Number of islands, pre cache")
       XCTAssertEqual(islands[0].nodes.count, 9, "Number of nodes in island 1, pre-cache")
       XCTAssertEqual(islands[0].nodes, [7,4,1,6,2,8,5,9,3], "Island 1 nodes, pre-cache")
       XCTAssertEqual(regions[0].interior.count, 9, "Number of interior nodes, pre-cache")
       network.cacheResults()
       islands = network.islands()
       regions = network.regions()
       XCTAssertEqual(islands.count, 3, "Number of islands")
       XCTAssertEqual(islands[0].nodes.count, 9, "Number of nodes in island 1")
       XCTAssertEqual(islands[0].nodes, [7,4,1,6,2,8,5,9,3], "Island 1 nodes")
       XCTAssertEqual(regions[0].interior.count, 9, "Number of interior nodes")
       XCTAssertEqual(regions[0].interior, [7,4,1,6,2,8,5,9,3], "Interior nodes")
       let nodes = network.nodes().sorted(by: {lhs, rhs in lhs.id < rhs.id})
       XCTAssertEqual(nodes[4].id, 5, "Node 5 number")
       XCTAssertEqual(nodes[4].inLinks, [4,1,3,6,2], "Node 5 in region links")
       let edges = network.edges().sorted(by: {lhs, rhs in lhs.id < rhs.id})
       XCTAssertEqual(edges[3].id, NodePair(1,5), "Edge 1-5 id")
       XCTAssertEqual(edges[3].n1Region, 1, "Edge 1-5 node 1 Region")
       XCTAssertEqual(edges[3].n2Region, 1, "Edge 1-5 node 2 Region")
    }
   
   func testSingleIsland() throws {
      let numItems = 80
      let numTags = 50
      let parm = DataParameters(numItems: numItems, numTags: numTags, forceUnusedTags: false, pctItemTable: stdItemFreqs, avgTagFreq: stdAvgFreq, maxTagFreq: stdMaxFreq)
      let data = GeneratedCollection(parameters: parm)
      let graph = UndirectedGraph(nodes: data.numTags, adjustment: -1)
      for item in data.items {
         graph.add(list: item.tagIdList)
      }
      let network = TagNetwork(graph, tags: data.tags)
      let islands = network.islands()
      XCTAssertEqual(islands[0].nodes.count, 50, "Island nodes")
      XCTAssertEqual(islands[0].maxRegions, 3, "Maximum regions possible")
      XCTAssertEqual(islands[0].minRegions, 1, "Minimum regions")
      XCTAssertEqual(islands[0].maxAdjacent, 7, "Max adjacent nodes")
      let regions = network.regions().sorted(by: {lhs, rhs in lhs.id < rhs.id})
      XCTAssertEqual(regions[0].id, 1, "Region 1 ID")
      XCTAssertEqual(regions[1].id, 11, "Region 2 ID")
      XCTAssertEqual(regions[1].exterior.count, 2, "Links to nodes exterior of region 2")
      XCTAssertEqual(regions[1].exterior, [9,10], "Nodes exterior of region 2")
      let n11NodeSeq = network.nodes().filter({node in node.id == 11})
      XCTAssertEqual(n11NodeSeq.count, 1, "11 node record")
      XCTAssertEqual(n11NodeSeq[0].region, 11, "Node 1 region")
      XCTAssertEqual(n11NodeSeq[0].exLinks, [9,10], "Node 11 exterior links")
      let n10NodeSeq = network.nodes().filter({node in node.id == 10})
      XCTAssertEqual(n10NodeSeq.count, 1, "10 node record")
      XCTAssertEqual(n10NodeSeq[0].id, 10, "Node 10 id")
      XCTAssertEqual(n10NodeSeq[0].region, 1, "Node 10 region")
      XCTAssertEqual(n10NodeSeq[0].exLinks, [11], "Node 10 exterior links")
      let n09NodeSeq = network.nodes().filter({node in node.id==9})
      XCTAssertEqual(n09NodeSeq.count, 1, "9 node record")
      XCTAssertEqual(n09NodeSeq[0].id, 9, "Node 9 id")
      XCTAssertEqual(n09NodeSeq[0].region, 1, "Node 9 region")
      let e1011EdgeSeq = network.edges().filter({$0.id == NodePair(10,11)})
      XCTAssertEqual(e1011EdgeSeq.count, 1, "10-11 edge record")
   }
   
   func testMultiIslandMultiRegion() throws {
      let numItems = 400
      let numTags = 200
      let itemFreqs: [Float] = [0.0, 0.1, 0.3, 0.4, 0.1, 0.1]
      let avgFreq: Float = 0.01
      let maxFreq: Float = 0.04
      let parm = DataParameters(numItems: numItems, numTags: numTags, forceUnusedTags: false, pctItemTable: itemFreqs, avgTagFreq: avgFreq, maxTagFreq: maxFreq)
      let data = GeneratedCollection(parameters: parm)
      let graph = UndirectedGraph(nodes: data.numTags, adjustment: -1)
      for item in data.items {
         graph.add(list: item.tagIdList)
      }
      var network = TagNetwork(graph, tags: data.tags)
      network.cacheResults()
      let islands = network.islands().sorted(by: {$0.id < $1.id})
      let regions = network.regions().sorted(by: {$0.island < $1.island || ($0.island==$1.island && $0.id < $1.id)})
      let node_1 = network.nodes().filter({$0.id==1})[0]
      let edge_1_10 = network.edges().filter({$0.id == NodePair(1,10)})[0]
      XCTAssertEqual(islands[0].nodes.count, 80, "Num nodes for Island 1")
      XCTAssertEqual(islands[1].nodes.count, 60, "Num nodes for island 21")
      XCTAssertEqual(regions[0].exterior, [6,7,8,10,11], "Exterior nodes for island 1 region 1")
      XCTAssertEqual(regions[1].exterior, [1,2,4,5], "Exterior nodes for island 1 region 6")
      XCTAssertEqual(node_1.exLinks, [10,11], "Node 1 exteriior links")
      XCTAssertEqual(edge_1_10.n1Region, 1, "Node 1 region")
      XCTAssertEqual(edge_1_10.n2Region, 6, "Node 6 region")
   }
   
   func testFactorCalculation() throws {
      let display1 = CGSize(width: 1000.5, height: 750.5)
      let f1 = calcFactor(gridWidth: 40, gridHeight: 30, displaySize: display1)
      XCTAssertEqual(f1, 25.0125, "Large landscape")
      let display2 = CGSize(width: 750.5, height: 1000.5)
      let f2 = calcFactor(gridWidth: 30, gridHeight: 40, displaySize: display2)
      XCTAssertEqual(f2, 25.0125, "Large portrait")
      let display3 = CGSize(width: 500, height: 300)
      let f3 = calcFactor(gridWidth: 60, gridHeight: 50, displaySize: display3)
      XCTAssertEqual(f3, 10.0, "Small display, min factor used")
   }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
