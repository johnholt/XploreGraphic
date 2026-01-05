//
//  TagNetwork.swift
//  XploreGraphic
//
//  Created by John Holt on 12/16/24.
//

import Foundation

/// The relationship network between the tags
struct TagNetwork {
   // Data inputs
   let tags : [Int : Tag]
   let numNodes: Int
   let gridWidth: Int
   let gridCols: Int
   let gridSplitPad: Int
   let gridHeight: Int
   let gridRows: Int
   let islandStats: [IslandStat]
   let nodeConnectStats: [NodeConnectStat]
   // Display constants
   let margin = 5
   let minTagsBeforeSplit = 20   // minimum tags to trigger split
   let maxTagsBeforeSplit = 50   // maximum tags before forcing split
   // Cached information
   private var _islands : [IslandEntry]?
   private var _regions : [RegionEntry]?
   private var _nodes: [NodeEntry]?
   private var _edges: [EdgeEntry]?
   
   /// Displable network graph of the tags.
   /// - Parameters:
   ///   - g: the undirected graph of the tag network
   ///   - tags: the list of tags with descriptive information
   ///   - aspect: the ratio of width over height for the display
   init(_ g: UndirectedGraph, tags:[Tag], aspect: Float = 2.5) {
      self.numNodes = g.nodes
      self.islandStats = g.islandsFromDistanceMatrix()
      self.nodeConnectStats = g.connectStatsFromDistanceMatrix()
      var workTags : [Int : Tag] = Dictionary<Int,Tag>(minimumCapacity: tags.count*2)
      for tag in tags {
         workTags[tag.id] = tag
      }
      self.tags = workTags
      var workPad: Int = 0
      for islandStat in islandStats {
         workPad += islandStat.nodes.count / minTagsBeforeSplit   // Islands cannot split cannot need extra room
      }
      self.gridSplitPad = workPad      // worst case for additional padding because of splitting into regions
      self.gridCols = Int((Double(self.numNodes)*Double(aspect)).squareRoot().rounded(.up))
      self.gridWidth = 2*gridCols + 2*margin + 1 + 2*self.gridSplitPad
      self.gridRows = Int((Double(self.numNodes)/Double(aspect)).squareRoot().rounded(.up))
      self.gridHeight = 2*gridRows + 2*margin + 1
   }
   /// The isolated groups of Tags in the network
   func islands() -> [IslandEntry]   {
      guard self._islands == nil else {
         return self._islands!
      }
      var rslt = Array<IslandEntry>()
      var widthUsed = self.margin
      let usableGrid = self.gridWidth - 2*margin - 2*self.gridSplitPad
      for islandStat in self.islandStats {
         let islandNumNodes = islandStat.nodes.count
         let proportionRaw = Float(islandNumNodes)/Float(self.numNodes)
         let proportionWidth = (proportionRaw * Float(usableGrid)).rounded()
         let padWidth = islandNumNodes / self.minTagsBeforeSplit  // too small to split => no padding
         // TODO: need approach for islands that are too small to use the the height provided
         // NOTE: consider a pass through island stats looking at small islands and making a block for them
         var islandWidth = Int(proportionWidth) + 1 + 2*padWidth
         if islandWidth + widthUsed > self.gridWidth {
            islandWidth = self.gridWidth - widthUsed
         }
         let islandHeight = self.gridHeight - 2*self.margin
         // NOTE: When merge of small regions is implemented, revisit limit because of seeds
         let maxRegions: Int = if islandStat.nodes.count < maxTagsBeforeSplit    //Q. Have to few tags or to many seed tags
                                    || islandStat.nodes.count / islandStat.numWithMax < minTagsBeforeSplit {
            1                                                                    //A. Yes, force max to 1
         } else {                                                                //A. No, make max the min number of seeds or enough to have min tags
            max(islandStat.numWithMax, (islandStat.nodes.count + minTagsBeforeSplit - 1) / minTagsBeforeSplit)
         }
         let minRegions: Int = if islandStat.nodes.count < minTagsBeforeSplit {  //Q. To few tags for multiple region minimum
            1                                                                    //A. Yes, make the minimum 1 region
         } else {                                                                //A. No, make minimum the larger of the minimum seed count or enough to have max tag sized regions
            min(maxRegions, (islandStat.nodes.count + maxTagsBeforeSplit - 1) / maxTagsBeforeSplit)
         }
         rslt.append(IslandEntry(id: islandStat.id, nodes: islandStat.nodes,
                                 width: islandWidth, height: islandHeight,
                                 xpos: widthUsed, ypos: margin,
                                 minRegions: minRegions, maxRegions: maxRegions,
                                 maxAdjacent: islandStat.maxAdjacent))
         widthUsed += islandWidth
      }
      return rslt
   }
   func regions() -> [RegionEntry]  {
      guard self._regions == nil else {
         return self._regions!
      }
      var rslt = Array<RegionEntry>()
      let islands = self._islands ?? islands()
      for island in islands {
         if (island.maxRegions==1)  {                    //Q: Is island too small to split
            rslt.append(RegionEntry(id: island.id,       //A: Yes, make it a single region
                                    island: island.id,
                                    interior: island.nodes, exterior: Set<Int>(),
                                    width: island.width, height: island.height,
                                    xpos: island.xpos, ypos: island.ypos))
            continue
         }
         // will split the island into 2 or more regions, so get node details
         // for the nodes on this island
         var nodeStats = Dictionary<Int,NodeConnectStat>(minimumCapacity: island.nodes.count*2)
         // Need to determine appropriate number of splits, assign nodes to a split
         // and allocate the space
         var seedSet = Set<Int>()
         var assigned2Seed = [Int:Int]()           // (node:seed)
         var seedAssignments = Dictionary<Int,Set<Int>>(minimumCapacity: island.maxRegions)  // seed:nodeSet
         var adjCounts = Array<Int>(repeating: 0, count: island.maxAdjacent+1)
         for nodeStat in self.nodeConnectStats where island.nodes.contains(nodeStat.id) {
            nodeStats[nodeStat.id] = nodeStat
            adjCounts[nodeStat.numAdjacent] += 1
         }
         var threshold = island.maxAdjacent
         var regionSeeds = adjCounts[threshold]
         // First, select the well connected
         while threshold > 3 && regionSeeds + adjCounts[threshold-1] <= island.maxRegions {
            threshold -= 1
            regionSeeds += adjCounts[threshold]
         }
         if regionSeeds < island.minRegions
               && threshold > 2                          //Q. Was there enough well connected to reach minimum?
               && regionSeeds + adjCounts[threshold-1] <= island.maxRegions {
            threshold -= 1                               // A. No, dip down into the nodes with 1 less adjacent
            regionSeeds += adjCounts[threshold]          // unless there are to many
         }
         for nodeStat in self.nodeConnectStats where island.nodes.contains(nodeStat.id) {
            if nodeStat.numAdjacent >= threshold {          //Q. number adjacent high enough to take all as seeds
               seedSet.insert(nodeStat.id)                  //A. Yes, add to the list of region seeds
               seedAssignments[nodeStat.id] = [nodeStat.id] //Start the region list with itself
               assigned2Seed[nodeStat.id] = nodeStat.id     // Record as assigned to itself
            }
         }
         // Regions with seeds are determined.  First place directly connected
         // to the closest seed.  Nodes not adjacent to any seed will be used to fill
         // region membership
         //
         // Process nodes in sorted order for repeatability
         let workNodeSeq = island.nodes.subtracting(seedSet).sorted()
         var assignedSet = seedSet
         for workNode in workNodeSeq {
            var matchDist: Float = 1.0       // Distance = 1 - Jaccard co-efficient
            var matchSeed: Int!
            for testSeed in seedSet.sorted() {
               if seedAssignments[testSeed]!.count > self.maxTagsBeforeSplit {  //Q. max assigned
                  continue                                //A. Yes, don't assign more to this one
               }
               let testStat = nodeStats[testSeed]!
               if let testDist = testStat.adjTagsetDst[workNode]  {  // Q. is workNode adjacent to this seed
                  if testDist < matchDist                            // A. Yes, check closeness and lowest ID if equal distance
                     || (testDist == matchDist
                         && testStat.id < matchSeed ?? Int.max) {    // accept the stat if matchSeed not yet set
                     matchDist = testDist                            // closer to this seed so far
                     matchSeed = testSeed
                  }
               }
            }
            // matchSeed (if present) shows the best region for the workNode
            if let seed = matchSeed {
               var temp = seedAssignments[seed]!
               temp.insert(workNode)
               assignedSet.insert(workNode)
               seedAssignments[seed] = temp
               assigned2Seed[workNode] = seed
            }
         }
         // now assign the remaining nodes that were not directly adjacent to any seed
         // N.B. we will need to iterate on the unassigned set because we only have
         //   adjancent nodes for each node in the nodeStats
         // TODO: This process may result in seeds that are larger than the desired maxTagsBeforeSplit
         var unassignedSet = island.nodes.subtracting(assignedSet)
         var changed = true
         while changed && !unassignedSet.isEmpty {
            changed = false
            for workNode in unassignedSet {
               let workStat = nodeStats[workNode]!
               var matchDist: Float = 1.0 // distance is 1 - Jaccard Simalarity
               var matchSeed: Int!
               for (testAdj, testDist) in workStat.adjTagsetDst {
                  if let testSeed = assigned2Seed[testAdj] {   //Q. Is the adjacent node assigned
                     if testDist <= matchDist             {    //Q. and is it closest
                        matchDist = testDist                   //A. Yes, record distance and region
                        matchSeed = testSeed
                     }
                  }
               }
               if let seed = matchSeed {                     //Q. Do we have a region
                  changed = true
                  unassignedSet.remove(workNode)
                  assignedSet.insert(workNode)
                  assigned2Seed[workNode] = seed
                  var temp = seedAssignments[seed]!
                  temp.insert(workNode)
                  seedAssignments[seed] = temp
               }
            }
         }
         if !unassignedSet.isEmpty {                          //Q. Did any fail to assign?
            rslt.append(RegionEntry(id: island.id,            //A. Yes, split failed so
                                   island: island.id,         //   create just 1 region
                                    interior: island.nodes, exterior: Set<Int>(),
                                    width: island.width, height: island.height,
                                    xpos: island.xpos, ypos: island.ypos))
            continue
         }
         //The nodes are all assigned to seeds
         //
         // TODO: want to examine and merge regions that are too small
         //
         // seedSet           - the list of seeds, not region ID values
         // seedAssignments   - he node IDs assigned to each seed [seed:nodeSet]
         // nodeStats         - the information on each node [nodeID:NodeStat]
         // Loop on seedAssignments to produce seedExSeeds to determine which regions
         //will need to be close to each other and seedExNodes to record the nodes involved
         var seedExNodes = Dictionary<Int, Set<Int>>()      // [seed:external nodes]
         var seedExSeeds = Dictionary<Int, Set<Int>>()      // [seed:external node seeds]
         for (seed, assignedNodes) in seedAssignments {
            var extNodeList = Set<Int>()
            var extSeedList = Set<Int>()
            for assigned in assignedNodes {
               let nodeStat = nodeStats[assigned]!
               // check each adjacent node to see if it is external
               for adjNode in nodeStat.adjNodes where !assignedNodes.contains(adjNode) {
                  extNodeList.insert(adjNode)
                  extSeedList.insert(assigned2Seed[adjNode]!)
               }
            }
            seedExNodes[seed] = extNodeList
            seedExSeeds[seed] = extSeedList
         }
         // now have the list of external nodes for each seed and the seeds for those nodes
         // TODO: order seeds to reduce confusion of edge crossings
         var posSeed = Dictionary<Int, Int>() // Ordinal position, starting at 1
         var pos = 1
         for seed in seedSet {
            posSeed[pos] = seed           // order as is for now
            pos += 1
         }
         // write the seeds in position order
         var xpos = island.xpos
         let ypos = island.ypos
         let regionHeight = island.height
         var widthUsed = 0
         for regionOrd in 1...seedSet.count {
            let thisSeed = posSeed[regionOrd]!
            let assigned = seedAssignments[thisSeed]!
            let idRegion = assigned.min()!
            let external = seedExNodes[thisSeed]!
            let proportionRaw = Float(assigned.count)/Float(island.nodes.count)
            let proportionWidth  = (proportionRaw * Float(island.width)).rounded()
            var regionWidth = (proportionWidth>0.0) ? Int(proportionWidth) + 1  : 2
            if regionWidth + widthUsed > island.width {
               regionWidth = island.width - widthUsed
            }
            let entry = RegionEntry(id: idRegion, island: island.id,
                                interior: assigned, exterior: external,
                                width: regionWidth, height: regionHeight,
                                xpos: xpos, ypos: ypos)
            rslt.append(entry)
            widthUsed += regionWidth
            xpos += regionWidth
         }
      }
      return rslt
   }
   func nodes() -> [NodeEntry]  {
      guard self._nodes == nil else {
         return self._nodes!
      }
      var rslt = Array<NodeEntry>()
      let regions = self._regions ?? regions()
      var nodeStats = Dictionary<Int,NodeConnectStat>(minimumCapacity: self.numNodes*2)
      for nodeStat in self.nodeConnectStats {    // Load dictionary for lookup
         nodeStats[nodeStat.id] = nodeStat
      }
      var padColsUsed = 0
      var prevIsland : Int?
      for region in regions {
         if region.island != prevIsland ?? region.island {    //Q. Are we still in the same island
            padColsUsed = 0                                    //A. No, reset the amount of padding used
         }
         prevIsland = region.island
         let regionRows = (region.height - 1) / 2
         let regionCols = (region.width - 1) / 2
         // TODO: determine algorithm to position nodes such that edge line crosses are reduced
         // Assign row/col positions in column major to the nodes as they are encountered
         var currRow = 0
         var currCol = 0
         for node in region.interior {
            let xposNode = region.xpos + currCol*2 + padColsUsed*2
            let yposNode = region.ypos + currRow*2
            let nodeStat = nodeStats[node]!
            let inLinks = region.interior.intersection(nodeStat.adjNodes)
            let exLinks = region.exterior.intersection(nodeStat.adjNodes)
            let entry = NodeEntry(id: node, region: region.id, island: region.island,
                                  inLinks: inLinks, exLinks: exLinks,
                                  xpos: xposNode, ypos: yposNode)
            rslt.append(entry)
            currRow += 1
            if currRow >= regionRows {
               currRow = 0
               currCol += 1
            }
         }
         if currRow == 0 {                            //Q. Did we use any of the last column
            currCol = currCol == 0  ? 0 : currCol - 1 //A. No, reverse last column increment if done
         }
         if currCol > regionCols {                    //Q. Use more columns than planned
            padColsUsed += currCol - regionCols       //A. Yes, account for pad used
         } else {                                     //A. No, reduce used amount
            padColsUsed = max(0, padColsUsed - regionCols + currCol)
         }
      }
      return rslt
   }
   func edges() -> [EdgeEntry]  {
      guard self._edges == nil else {
         return self._edges!
      }
      var rslt = Array<EdgeEntry>()
      var nodeEntries = Dictionary<Int, NodeEntry>(minimumCapacity: 2*self.nodes().count)
      for entry in self.nodes() {
         nodeEntries[entry.id] = entry
      }
      // create the edges for pairs with node 1 ID < node 2 ID
      // TODO: use splines instead of straight lines for edges that pass through tag center-points
      for node1 in nodeEntries.values {
         for id2 in node1.exLinks.union(node1.inLinks) where id2 > node1.id {
            let node2 = nodeEntries[id2]!
            let edge = EdgeEntry(id: NodePair(node1.id, id2), island: node1.island,
                                 n1Region: node1.region, n2Region: node2.region,
                                 n1Xpos: node1.xpos, n1Ypos: node1.ypos,
                                 n2Xpos: node2.xpos, n2Ypos: node2.ypos)
            rslt.append(edge)
         }
      }
      return rslt
   }
   mutating func cacheResults() {
      self._islands = islands()
      self._regions = regions()
      self._nodes = nodes()
      self._edges = edges()
   }
}

/// Isolated partition of a network graph
struct IslandEntry: Identifiable {
   var id: Int             // lowest node id (original, not row/column number
   var nodes: Set<Int>     // number of active nodes
   var width: Int          // width in grid squares
   var height: Int         // height in grid squares
   var xpos: Int           // upper left grid square x coordinate
   var ypos: Int           // upper left grid square y coordinate
   var minRegions: Int     // minimum number of regions to use
   var maxRegions: Int     // maximum number of regions to use
   var maxAdjacent: Int    // max adjacent for any node on island
}
extension IslandEntry: Hashable {
   static func == (lhs: IslandEntry, rhs: IslandEntry) -> Bool {
      return lhs.id == rhs.id
   }
   func hash(into hasher: inout Hasher)  {
      hasher.combine(id)
   }
}

/// A sub-graph of a connected network graph
struct RegionEntry: Identifiable {
   var id: Int             // lowest node id (original)
   var island: Int         // identifier of the island containing this region
   var interior : Set<Int> // list of contained node identifiers (original), excludes bridging nodes
   var exterior : Set<Int> // list of bridge nodes.  An empty set occurs when region covers an island
   var width: Int          // width in grid squares
   var height: Int         // height in grid squares
   var xpos: Int           // upper left grid square x coordinate
   var ypos: Int           // upper left grid square y coordinate
}
extension RegionEntry: Hashable {
   static func == (lhs: RegionEntry, rhs: RegionEntry) -> Bool {
      return lhs.id == rhs.id
   }
   func hash(into hasher: inout Hasher) {
      hasher.combine(id)
   }
}

/// individual nodes of the network graph
struct NodeEntry: Identifiable {
   var id: Int             // node ID (original)
   var region: Int         // identifier of the region containing this node
   var island: Int         // identifier of the island containing this node
   var inLinks: Set<Int>   // internal link targets
   var exLinks: Set<Int>   // link targets external to this region
   var xpos: Int           // 2D x grid position
   var ypos: Int           // 2D y grid position
}
extension NodeEntry: Hashable {
   static func == (lhs: NodeEntry, rhs: NodeEntry) -> Bool {
      return lhs.id == rhs.id
   }
   func hash(into hasher: inout Hasher) {
      hasher.combine(id)
   }
}

/// Location information for edge connecting 2 nodes.
struct EdgeEntry: Identifiable {
   var id: NodePair        // pair of original node identifiers
   var island: Int         // island identifier
   var n1Region: Int       // region identifier for node 1
   var n2Region: Int       // region identifier for node 2
   var n1Xpos: Int         // 2D x grid position for node 1
   var n1Ypos: Int         // 2D y grid position for n1 node
   var n2Xpos: Int         // 2D x grid position for node 2
   var n2Ypos: Int         // 2D y grid position for node 2
}


