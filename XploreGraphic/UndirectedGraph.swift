//
//  UndirectedGraph.swift
//  XploreGraphic
//
//  Created by John Holt on 8/14/25.
//

import Foundation

/// An undirected graph.
@Observable
class UndirectedGraph {
   enum DistanceType {
      case PathLength
      case ItemsetJaccard
      case TagsetJaccard
   }
   // Base information
   /// Number of nodes in this graph
   let nodes: Int
   
   /// A factor to add to an external node nominal value to convert it to a zero based row/column value
   let adjust: Int
   
   /// The number of times the pair of nodes appear in a list of co-occuring nodes.  The diagonal is zero
   internal var pairOccurs : SymSqMatrix<Int16>
   
   /// Number of co-occurrence lists in which each node participates
   internal var numLists4Node : Array<Int>
   
   /// Number of co-occurrence lists added
   internal var numListOccurrences : Int = 0
   
   /// Number of unique lists that occurred in the underlying data
   internal var uniqueLists : Int = 0
   
   /// the occurrence count for each unique list of nodes that occurred in the underlying dataset
   internal var listOccurrences : [Array<Int> : Int] = [:]
   
   /// Tracks whether the externally provided information has changed requiring recomputing the derived information
   private var updated = false
   
   /// Sets of connected sub-graphs from node co-occurrence lists added.  Node identifiers are adjusted.
   private var connected: Set<Set<Int>>
   
   // Adjacency information based upon tag occurence from each item
   /// The number of paths added containing this node
   /// - Parameter node: the node identifier
   /// - Returns: the number of paths added that specified this node
   func getNumPath(node: Int) -> Int {
      return numLists4Node[node+adjust]
   }
   
   /// Number of co-occuring nodes
   /// - Parameter node: The node ID number, which will be adjusted to make it a zero based index
   /// - Returns: the number of nodes connected to this node
   func getNumNodesCoinciding(node: Int) -> Int {
      var rslt = 0
      for target in 0..<nodes {
         if node+adjust == target {
            continue
         }
         let connected = self.pairOccurs[node+adjust, target]
         rslt += connected > 0   ? 1 : 0
      }
      return rslt
   }
   
   /// Self contained complete sub-graphs lists of nodes and selected statistics
   /// - Returns: the complete sub-graphs in this collection and selected statistics
   func islandStats() -> [IslandStat] {
      var rslt = Array<IslandStat>()
      for connectSet in self.connected {
         let connectList = connectSet.sorted()
         let id = convert2ID(connectList.first!)
         var nodes = Set<Int>()
         var numWithMax  = 0
         var numWithMany = 0
         var numWith4Adj = 0
         var numWith3Adj = 0
         var numWith2Adj = 0
         var numWith1Adj = 0
         var minAdjacent = self.nodes
         var maxAdjacent = 0
         var avgAdjacent : Float = 0.0
         for rc in connectList {
            nodes.insert(convert2ID(rc))
            var neighbors = 0
            for m in 0..<self.nodes {
               if m == rc {      // Q. Is this a diagonal entry
                  continue       // A. Yes, skip
               }
               if pairOccurs[rc,m] > 0 {  //Q. Is node adjacent
                  neighbors += 1          //A. Yes, it co-occurred in at least 1 list
               }
            }
            switch neighbors {
               case 0:
                  break
               case 1:
                  numWith1Adj += 1
               case 2:
                  numWith2Adj += 1
               case 3:
                  numWith3Adj += 1
               case 4:
                  numWith4Adj += 1
               default:
                  numWithMany += 1
            }
            if neighbors < minAdjacent {
               minAdjacent = neighbors
            }
            if neighbors > maxAdjacent {
               maxAdjacent = neighbors
               numWithMax = 1
            } else if neighbors == maxAdjacent {
               numWithMax += 1
            }
            avgAdjacent += Float(neighbors) / Float(connectList.count)
         }
         let newIsland = IslandStat(id: id, nodes: nodes,
                                    numWithMany: numWithMany, numWithMax: numWithMax,
                                    numWith4Adj: numWith4Adj, numWith3Adj: numWith3Adj,
                                    numWith2Adj: numWith2Adj, numWith1Adj: numWith1Adj,
                                    minAdjacent: minAdjacent, maxAdjacent: maxAdjacent,
                                    avgAdjacent: avgAdjacent)
         rslt.append(newIsland)
      }
      return rslt.sorted(by: {left, right in left.id < right.id})
   }
   
   /// Node Connection Statistic extracted from occurrence information
   /// - Returns: The statistics for each node and the nodes that are connected
   func nodeConnectStats() -> [NodeConnectStat] {
      var rslt = Array<NodeConnectStat>()
      for connectSet in self.connected {
         let connectList = connectSet.sorted()
         for node in connectList {
            var numAdjacent = 0
            var numBelowAvg = 0
            var minAdjTagsetDist: Float = 1.0
            var maxAdjTagsetDist: Float = 0.0
            var sumAdjTagsetDist: Float = 0.0
            var adjNodes = Set<Int>()
            var adjNumCommon: [Int:Int] = [:]
            var adjTagsetDist: [Int:Float] = [:]
            for adj in connectList {
               if node == adj {     //Q. Are these the same node
                  continue          //A. Yes, skip this
               }
               if self.pairOccurs[node,adj] == 0 {    //Q. Are these nodes adjacent
                  continue                            //A. No, they never co-occurred on a list
               }
               numAdjacent += 1
               adjNodes.insert(convert2ID(adj))
               var both = 0
               var either = 0
               for column in connectList {   // check all relevent nodes to determine the distance
                  if node == column {     //Q. Is the the diagonal column for the node row
                     either += 1          //A. Yes, only need to check the adj entry
                     both += self.pairOccurs[adj, column] > 0 ?  1 : 0
                  } else if adj == column {//Q. is this the diagonal column for the adj row
                     either += 1           //A. Yes, only need to check the node entry
                     both += self.pairOccurs[node,column] > 0 ?  1 : 0
                  } else if self.pairOccurs[node,column] > 0
                              && self.pairOccurs[adj,column] > 0 { //Q. Both also have the same node adjacent
                     either += 1
                     both += 1
                  } else if self.pairOccurs[node,column] > 0
                              || self.pairOccurs[adj,column] > 0 { //Q. Does one of them have the column node adjacent
                     either += 1                                  // A. Yes, count it
                  }
               }
               let dist: Float = max(1.0 - (Float(both)/Float(either)), Float.leastNonzeroMagnitude)
               adjNumCommon[adj] = both
               adjTagsetDist[adj] = dist
               minAdjTagsetDist = dist < minAdjTagsetDist ? dist  : minAdjTagsetDist
               maxAdjTagsetDist = dist > maxAdjTagsetDist ? dist  : maxAdjTagsetDist
               sumAdjTagsetDist += dist
            }
            let avgAdjTagsetDist = numAdjacent==0 ? 0.0  : sumAdjTagsetDist / Float(numAdjacent)
            for (_, dist) in adjTagsetDist {
               if dist < avgAdjTagsetDist {     //Q. distance less than the average
                  numBelowAvg += 1              //A. Yes, count it
               }
            }
            let stat = NodeConnectStat(id: convert2ID(node), numNoConnect: self.nodes-connectList.count,
                                       numAdjacent: numAdjacent, numIndirect: connectList.count-numAdjacent-1,
                                       minAdjTagset: minAdjTagsetDist, maxAdjTagset: maxAdjTagsetDist,
                                       avgAdjTagset: avgAdjTagsetDist, numBelowAvg: numBelowAvg,
                                       adjNodes: adjNodes, adjNumCommon: adjNumCommon, adjTagsetDst: adjTagsetDist)
            rslt.append(stat)
         }
      }
      return rslt.sorted(by: {lhs, rhs in lhs.id < rhs.id})
   }

   // Utilities
   /// Convert and original node Identifier into a Row/Column value for an adjacency matrix
   /// - Parameter nodeID: the original node ID, such as the Tag Identifier nominal
   /// - Returns: a row or column value for an adjacency matrix
   func convert2RC(_ nodeID: Int) -> Int {
      return nodeID + self.adjust
   }
   /// Convert a row/column into an original node identifier, such as a tag nominal
   /// - Parameter rc: the row/column value for an adjacency matrix
   /// - Returns: an identifier nominal
   func convert2ID(_ rc: Int) -> Int {
      return rc - self.adjust
   }
   /// A null conversion that can be used to effectuate a no-op
   /// - Parameter id: the node identifier
   /// - Returns: the node identifier as provided
   func nullConvert(_ id: Int) -> Int {
      return id
   }
   
   // Derived inforamtion
   /// Extract the by node connection stats from the distanxe matrix.
   /// - Parameter adjustNodeIdent: Default to returning the list of original node identifiers instead
   ///  of the list of adjusted node identifiers that map to row/column identifiers in an adjacey matrix
   /// - Returns: an array of connection statistics for each node
   func connectStatsFromDistanceMatrix(adjustNodeIdent : Bool = true) -> [NodeConnectStat] {
      var rslt = Array<NodeConnectStat>()
      let mat = distanceMatrix(typ: .PathLength)
      let matTag = distanceMatrix(typ: .TagsetJaccard)
      let numInCommon = numCommonTags()
      let convertFunc = adjustNodeIdent ? convert2ID : nullConvert
      for n1 in 0..<self.nodes {
         if self.numLists4Node[n1] == 0 { //Q. was node used?
            continue                      //A. No, skip it
         }
         var notConnected = 0
         var direct = 0
         var indirect = 0
         var minTagset: Float = 1.0
         var maxTagset: Float = 0.0
         var sumTagset: Float = 0.0
         var numBelow = 0
         var adjacentNodes = Set<Int>()
         var numAdjCommon: [Int:Int] = [:]
         var adjTagsetDst: [Int:Float] = [:]
         for n2 in 0..<self.nodes {
            if self.numLists4Node[n2] == 0 { //Q. was node used?
               continue                      //A. No, skip it
            }
            if n1==n2 {                //Q. Is this the same node
               continue                //A. Yes, skip it
            }
            switch mat[n1,n2] {
               case 0:
                  notConnected += 1
               case 1:
                  direct += 1
                  sumTagset += matTag[n1,n2]
                  minTagset = (minTagset < matTag[n1,n2]) ? minTagset : matTag[n1,n2]
                  maxTagset = (maxTagset > matTag[n1,n2]) ? maxTagset : matTag[n1,n2]
                  numAdjCommon[convertFunc(n2)] = numInCommon[NodePair(n1,n2)]
                  adjTagsetDst[convertFunc(n2)] = matTag[n1,n2]
                  adjacentNodes.insert(convertFunc(n2))
               default:
                  indirect += 1
            }
         }
         let avgTagset = sumTagset/Float(direct)
         for n2 in 0..<self.nodes {
            if self.numLists4Node[n2] == 0 // Q. Node not used
                  || n1==n2                // or diagonal entry
                  || mat[n1,n2] == 0.0     // or not connected
                  || matTag[n1,n2] > avgTagset { // or further away than the average distance
               continue                    // A. Yes, skip it
            }
            numBelow += 1                  // A. No, count it
         }
         rslt.append(NodeConnectStat(id: convertFunc(n1),
                                     numNoConnect: notConnected,
                                     numAdjacent: direct,
                                     numIndirect: indirect,
                                     minAdjTagset: minTagset,
                                     maxAdjTagset: maxTagset,
                                     avgAdjTagset: avgTagset,
                                     numBelowAvg: numBelow,
                                     adjNodes: adjacentNodes,
                                     adjNumCommon: numAdjCommon,
                                     adjTagsetDst: adjTagsetDst))
      }
      return rslt
   }
   /// The list of isolated sets of connected nodes using the distance matrix instead of the adjancy matrix.
   /// - Parameter adjustNodeIdent: Default to returning the list of original node identifiers instead
   ///  of the list of adjusted node identifiers that map to row/column identifiers in an adjacey matrix
   /// - Returns: a list with zero (no nodes recorded) or more isolated complete subgraphs
   func islandsFromDistanceMatrix(adjustNodeIdent : Bool = true) -> [IslandStat] {
      var rslt = Array<IslandStat>()
      let mat = self.distanceMatrix(typ: .PathLength)
      for n1 in 0..<self.nodes {
         if self.numLists4Node[n1] == 0 {   //Q. Is this node used
            continue                   //A. No, skip it
         }
         var inList = false
         var island = 0
         let ndx4Test = (adjustNodeIdent) ? convert2ID(n1) : n1
         for i in 0..<rslt.count {
            if rslt[i].nodes.contains(ndx4Test) { //Q. is this node claimed
               inList = true
               island = i
               break
            }
         }
         if inList {             //Q. already assigned
            var neighbors = 0    //A. Yes, record details then advance to the next node
            for m in 0..<self.nodes {
               if m == n1 {      //Q. Is this a diagonal element
                  continue       //A. Yes, skip it
               }
               // pathDistance matrix is symmetric, so [m,n1] == [n1,m]
               if mat[m,n1] == 1 {  //Q. Is the node adjacent
                  neighbors += 1                   //A. Yes, count it
               }
            }
            switch neighbors {
               case 1:
                  rslt[island].numWith1Adj += 1
               case 2:
                  rslt[island].numWith2Adj += 1
               case 3:
                  rslt[island].numWith3Adj += 1
               case 4:
                  rslt[island].numWith4Adj += 1
               default:
                  rslt[island].numWithMany += 1
            }
            if rslt[island].minAdjacent > neighbors {
               rslt[island].minAdjacent = neighbors
            }
            if rslt[island].maxAdjacent < neighbors {
               rslt[island].maxAdjacent = neighbors
               rslt[island].numWithMax = 1
            } else if rslt[island].maxAdjacent == neighbors {
               rslt[island].numWithMax += 1
            }
            let cnt = Float(rslt[island].nodes.count)
            rslt[island].avgAdjacent += Float(neighbors)/cnt
            continue             // advance to the next node
         }
         // n1 is the low nominal for a new region
         var neighbors = 0
         var nodeList = Set<Int>()
         for m in 0..<self.nodes {
            if m != n1 && mat[n1,m] == 0.0 { //Q. Not diag and not connected
               continue                      //A. Yes, not on the island
            }
            let ndx4List = (adjustNodeIdent) ? convert2ID(m)  : m
            nodeList.insert(ndx4List)
            if m != n1 {                           //Q. Not the diagonal
               if mat[m,n1] == 1 {                 //Q. Is m a neighbor
                  neighbors += 1                   //A. Yes, count it
               }
            }
         }
         let newIsland = IslandStat(id: ndx4Test, nodes: nodeList,
                                     numWithMany: (neighbors>=5) ? 1 : 0,
                                     numWithMax: 1,
                                     numWith4Adj: (neighbors==4) ? 1 : 0,
                                     numWith3Adj: (neighbors==3) ? 1 : 0,
                                     numWith2Adj: (neighbors==2) ? 1 : 0,
                                     numWith1Adj: (neighbors==1) ? 1 : 0,
                                     minAdjacent: neighbors,
                                     maxAdjacent: neighbors,
                                     avgAdjacent: Float(neighbors)/Float(nodeList.count))
         rslt.append(newIsland)
      }
      return rslt
   }
   /// A histogram of the distance metric values.  In addition to the range and count for each bin, the
   /// returned structure also includes the median, mean, and standard deviation.
   /// - Parameters:
   ///   - type: the distance metric to use
   ///   - bins: te number of bins
   /// - Returns: an array for the histogram
   func histogram(type: DistanceType, bins: Int) -> Array<StatsEntry> {
      let initialEntry = StatsEntry()
      var rslt = Array<StatsEntry>(repeatElement(initialEntry, count: bins))
      var tempM : Double = 0.0
      var tempS : Double = 0.0
      let baseStats = distanceStats(typ: type)
      let interval = (baseStats.highBound==baseStats.lowBound)
                     ? 1.0 / Float(bins)
                     : (baseStats.highBound-baseStats.lowBound) / Float(bins)
      rslt[0].lowBound = baseStats.lowBound
      rslt[0].id = 1
      rslt[bins-1].highBound = baseStats.highBound
      for i in 1..<bins {
         let nextBound = rslt[i-1].lowBound + interval
         rslt[i].lowBound = nextBound
         rslt[i-1].highBound = nextBound
         rslt[i].id = rslt[i-1].id + 1
      }
      let mat = distanceMatrix(typ: type)
      guard self.nodes > 0 && interval > 0.0 else {return rslt}
      // walk through entries and calculate mean and variance sum
      for n1 in 0..<self.nodes-1 {
         if self.numLists4Node[n1] == 0 {    //Q. Was node in data
            continue                         //A. No, skip it
         }
         for n2 in n1+1..<self.nodes {
            if self.numLists4Node[n2] == 0 { //Q. Was node in data
               continue                      //A. No, skip it
            }
            let rawPos = Int((mat[n1,n2]-baseStats.lowBound)/interval)
            let ndx = max(0,min(rawPos,bins-1))    // Force index into valid range
            // calculate the running mean and variance sum using Welford
            // from in Knuth Art of Computer Programming Volume 2 page 232
            let count = rslt[ndx].count + 1
            tempM = rslt[ndx].mean + ((Double(mat[n1,n2]) - rslt[ndx].mean)/Double(count))
            tempS = rslt[ndx].std + ((Double(mat[n1,n2]) - rslt[ndx].mean)*(Double(mat[n1,n2])-tempM))
            rslt[ndx].mean = tempM
            rslt[ndx].std = tempS
            rslt[ndx].count = count
         }
      }
      // complete histogram by calculating standard deviation from variance sum and return
      for i in 0..<bins {
         rslt[i].std = (rslt[i].count == 0) ? 0.0  : rslt[i].std / Double(rslt[i].count)
      }
      return rslt
   }
   /// The distance between 2 nodes in the specified metric.
   /// the greatest finite magnitude is returned
   /// - Parameters:
   ///   - typ: the metric type for the distance
   ///   - node1: the node number (original) of the first node
   ///   - node2: the node number (original) of the second node
   /// - Returns: the distance between the nodes.  The greatest finite magnitude is returned for no connection.
   func distance(typ: DistanceType, node1: Int, node2: Int) -> Float {
      let distMatrix = distanceMatrix(typ: typ)
      let f = distMatrix[convert2RC(node1), convert2RC(node2)]
      return (f > 0.0) ? f : Float.greatestFiniteMagnitude
   }
   /// A matrix of the node to node distances
   /// - Parameter typ: the distance metric to be used
   /// - Returns: a matrix of the distances.  The diagonal entries are zero.  The row and column numbers are zero based
   private func distanceMatrix(typ: DistanceType) -> SymSqMatrix<Float> {
      if updated {
         calcDistances()
      }
      switch typ {
         case .ItemsetJaccard:
            return _itemSetDistance
         case .TagsetJaccard:
            return _tagSetDistance
         case .PathLength:
            return _pathDistance
      }
   }
   func numCommonTags() -> [NodePair:Int] {
      if updated {
         calcDistances()
      }
      return self._numTagsCommon
   }
   /// Summary distnce statistics.  Stats include minimum, maximum, mean, and standard deviation
   /// - Parameters
   ///   - typ: the distance type, PathLength, ItemsetJaccard, or TagsetJaccard
   ///   - forceCalc: used only for performance testing, default False
   /// - Returns: The descriptive stats
   func distanceStats(typ: DistanceType, forceCalc: Bool = false) -> StatsEntry {
      if updated || forceCalc {
         calcDistances()
      }
      switch typ {
         case .ItemsetJaccard:
            return self._itemSetStats
         case .TagsetJaccard:
            return self._tagSetStats
         case .PathLength:
            return self._pathStats
      }
   }
   // Data derived by the calcDistance() function
   /// The path distance using the Jaccard distance based upon the underlying itemsets for tags that co-occur
   private var _itemSetDistance : SymSqMatrix<Float>
   /// Descriptive statistics of the Itemset Distances
   private var _itemSetStats: StatsEntry
   /// The path distance using a Jaccard distance based upon the two tag sets in the undderlyiing data of the nodes
   private var _tagSetDistance : SymSqMatrix<Float>
   /// Descriptive statistics of the Tag set distances
   private var _tagSetStats : StatsEntry
   /// The path length between each pair of nodes
   private var _pathDistance : SymSqMatrix<Float>
   /// Descriptive statistics of the path distances
   private var _pathStats : StatsEntry
   /// The number of tags that this pair of nodes has in common.  Note that a tag is a node and the
   /// tags in common are thise nodes that are adjacent to both of these nodes.
   private var _numTagsCommon : Dictionary<NodePair,Int>
   
   /// Initializer
   /// - Parameters:
   ///   - nodes: the number of nodes involved, must be less than 32,768
   ///   - adjustment: a value to be added to the node identifier such that the first internal ID value is zero (0)
   init(nodes: Int, adjustment: Int = 0) {
      self.nodes = nodes
      self.adjust = adjustment
      self.pairOccurs = SymSqMatrix<Int16>(rows: nodes)
      self.numLists4Node = Array<Int>(repeating: 0, count: nodes)
      self._itemSetDistance = SymSqMatrix<Float>(rows: nodes)
      self._tagSetDistance = SymSqMatrix<Float>(rows: nodes)
      self._pathDistance = SymSqMatrix<Float>(rows:nodes)
      self._pathStats = StatsEntry()
      self._tagSetStats = StatsEntry()
      self._itemSetStats = StatsEntry()
      self._numTagsCommon = Dictionary<NodePair,Int>(minimumCapacity: nodes*2)
      self.connected = Set<Set<Int>>(minimumCapacity: nodes)
   }
   
   /// Add a path instancce to the graph.  A path instance is a set of nodes that co-occurred
   /// in the source data.  For instance, the items on a receipt could be captured as a set of co-occuring
   /// nodes.
   /// - Parameter list: the set of node identifiers that co-occur
   func add(list: Set<Int>) {
      var nodeArray = Array<Int>()
      for nodeId in list.sorted() {
         nodeArray.append(nodeId + adjust)
      }
      for row in nodeArray {
         for column in nodeArray {
            if row > column {    //Q. position in lower triangle
               continue          //A. Yes, no need to count
            }
            if row == column {   //Q. position on the diagonal
               self.numLists4Node[row] += 1 //A. Yes, Count only as a participant
               continue
            }
            self.pairOccurs[row,column] += 1  // on the upper triangle, count the pair
         }
      }
      self.numListOccurrences += 1
      let prevUniques = listOccurrences.count
      self.listOccurrences[nodeArray] = 1 + (self.listOccurrences[nodeArray] ?? 0)
      if prevUniques < self.listOccurrences.count {  //Q. Did we just add a new list?
         self.uniqueLists += 1                       //A. Yes, count it
      }
      var adjList = Set<Int>(nodeArray)
      var matches = Set<Set<Int>>()
      var alreadyInSets = false
      for grp in connected {
         if grp.isSuperset(of: adjList) {    // Q. Do we already have all of these nodes
            alreadyInSets = true             // A. Yes, break out
            break
         }
         if !grp.isDisjoint(with: adjList) { // Q. Do we already have some of these nodes
            matches.insert(grp)              // A. Yes, keep track
         }
      }
      if !matches.isEmpty {
         for match in matches {
            adjList.formUnion(match)
            connected.remove(match)
         }
      }
      if !alreadyInSets {
         connected.insert(adjList)
      }
      self.updated = true
   }
   

   /// Calculate the distance matrices and summary stats for all nodes.
   /// A zero distance means that there is no path connecting the pair of nodes
   private func calcDistances() -> Void {
      self._itemSetDistance.clear()
      self._tagSetDistance.clear()
      self._pathDistance.clear()
      self._numTagsCommon.removeAll(keepingCapacity: true)
      //Determine the Jaccard distance for the nodes that co-occur in the
      //underlying data and set those pairs to a path distance of 1
      //Calculate both item set and tag set Jaccard distance
      var activeNodesLists = Array<Array<Int>>()
      for list in connected {
         activeNodesLists.append(Array(list).sorted())
      }
      for activeNodesList in activeNodesLists {
         for n1 in activeNodesList {
            for n2 in activeNodesList where n2 > n1 {
               if self.pairOccurs[n1,n2] == 0 { //Q. Do these nodes co-occur?
                  continue                      //A. No, can't calculate distance
               }                                //     from underlyiing data
               let unionCardinality = self.numLists4Node[n1]
               + self.numLists4Node[n2]
               - Int(self.pairOccurs[n1,n2])
               let similarity = Float(self.pairOccurs[n1,n2]) / Float(unionCardinality)
               self._itemSetDistance[n1,n2] = max(1.0 - similarity, Float.leastNonzeroMagnitude)
               self._pathDistance[n1,n2] = 1
               // Determine Jaccard distance using the tag sets
               var both = 0      // both present, the cardinality of the intersection of the sets
               var either = 0    // either one or both, the cardinality of the union of the sets
               // use the node number as the row and vary the column number
               for column in activeNodesList {
                  if column == n1 {                // Q. is this the diagonal entry of the n1 row
                     either += 1                   // A. yes, only need to check n2 entry
                     both += (self.pairOccurs[n2,column] > 0) ? 1 : 0
                  } else if column == n2 {         // Q. is this the diagonal entry for the n2 row
                     either += 1                   // A. yes, only need to check the n1 entry
                     both += (self.pairOccurs[n1,column] > 0) ? 1 : 0
                  } else if self.pairOccurs[n1,column] > 0
                              && self.pairOccurs[n2,column] > 0 {  // Q. both exist?
                     both += 1                                     // A. yes
                     either += 1
                  } else if self.pairOccurs[n1,column] > 0
                              || self.pairOccurs[n2,column] > 0 { // Q. only 1 is present
                     either += 1                                  // A. yes
                  }
               }
               self._tagSetDistance[n1,n2] = max(1.0 - Float(both)/Float(either), Float.leastNonzeroMagnitude)
               self._numTagsCommon[NodePair(n1,n2)] = both
            }
         }
      }
      // Now determine distances for pairs that are not directly associated.
      var changed = true
      var changes = Array<Bool>(repeating: true, count: connected.count)
      var iter = 1
      var paths = Dictionary<Int,Float>(minimumCapacity: self.nodes/2)
      var tagsets = Dictionary<Int,Float>(minimumCapacity: self.nodes/2)
      var itemsets = Dictionary<Int,Float>(minimumCapacity: self.nodes/2)
      while iter < self.nodes-1 && changed { //Q. At longest possible path or early exit?
         changed = false                     //A. No, check to extend path
         iter += 1
         for listNdx in 0..<activeNodesLists.count {
            if !changes[listNdx] {     //Q. Is this group still incomplete
               continue                //A. No, no change last time means no more changes
            }
            changes[listNdx] = false
            for n1 in activeNodesLists[listNdx] {
               for n2 in activeNodesLists[listNdx] where n2 > n1 {
                  if self._pathDistance[n1,n2] != 0 {//Q. Already in a path
                     continue                        //A. Yes, skip
                  }
                  // use the node numbers as the rows and vary the column number
                  // to find the pairs that connect.  Record the distances
                  paths.removeAll(keepingCapacity: true)
                  itemsets.removeAll(keepingCapacity: true)
                  tagsets.removeAll(keepingCapacity: true)
                  var haveConnection = false
                  for column in activeNodesLists[listNdx] {
                     if column == n1 || column == n2 { // Q. looking at a diagonal entry?
                        continue                       // A. One is, so skip this column
                     }
                     if self._pathDistance[n1,column] != 0
                           && self._pathDistance[n2,column] != 0 {//Q. is there a connection?
                        paths[column] = self._pathDistance[n1,column] + self._pathDistance[n2,column]
                        //n1 & n2 do not share any tags or underlying items
                        //so not clear that approach preserves the triangle inequality
                        //required for a distance metric
                        itemsets[column] = self._itemSetDistance[n1,column] + self._itemSetDistance[n2,column]
                        tagsets[column] = self._tagSetDistance[n1,column] + self._tagSetDistance[n2,column]
                        haveConnection = true
                     }
                  }
                  if !haveConnection {       //Q. Anything to connect the nodes n1 & n2?
                     continue                //A. Nothing, check the next pair
                  }
                  // have one or more connections, now select the minimums
                  var minPathLength = Float(Int32.max)
                  for length in paths.values {
                     if length < minPathLength {
                        minPathLength = length
                     }
                  }
                  var minItemsetLen = Float.greatestFiniteMagnitude
                  for length in itemsets.values {
                     if length < minItemsetLen {
                        minItemsetLen = length
                     }
                  }
                  var minTagsetLen = Float.greatestFiniteMagnitude
                  for length in tagsets.values {
                     if length < minTagsetLen {
                        minTagsetLen = length
                     }
                  }
                  // extend with the minimum length
                  self._pathDistance[n1,n2] = minPathLength
                  self._itemSetDistance[n1,n2] = minItemsetLen
                  self._tagSetDistance[n1,n2] = minTagsetLen
                  changed = true
                  changes[listNdx] = true
               }
            }
         }
      }
      // calculate stats for networks.  Running mean and variance from Welford
      // in Knuth Art of Computer Programming Volume 2 page 232
      self._itemSetStats.highBound = 0.0
      self._itemSetStats.lowBound = Float.greatestFiniteMagnitude
      self._tagSetStats.highBound = 0.0
      self._tagSetStats.lowBound = Float.greatestFiniteMagnitude
      self._pathStats.highBound = 0.0
      self._pathStats.lowBound = Float.greatestFiniteMagnitude
      var count: Int = 0
      var itemSetM : Double = 0.0
      var tagSetM: Double = 0.0
      var pathM: Double = 0.0
      var itemSetS: Double = 0.0
      var tagSetS: Double = 0.0
      var pathS: Double = 0.0
      var tempM: Double = 0.0
      var tempS: Double = 0.0
      for n1 in 0..<self.nodes-1 {
         if self.numLists4Node[n1] == 0 { //Q. Was node in the data?
            continue                      //A. No, skip
         }
         for n2 in n1+1..<self.nodes {
            if self.numLists4Node[n2] == 0 { //Q. Was node in the data?
               continue                      //A. No, skip
            }
            count += 1
            if self._itemSetDistance[n1,n2] < self._itemSetStats.lowBound {
               self._itemSetStats.lowBound = self._itemSetDistance[n1,n2]
            }
            if self._itemSetDistance[n1,n2] > self._itemSetStats.highBound {
               self._itemSetStats.highBound = self._itemSetDistance[n1,n2]
            }
            tempM = itemSetM + ((Double(self._itemSetDistance[n1,n2]) - itemSetM)/Double(count))
            tempS = itemSetS + ((Double(self._itemSetDistance[n1,n2]) - itemSetM)*(Double(self._itemSetDistance[n1,n2])-tempM))
            itemSetM = tempM
            itemSetS = tempS
            self._itemSetStats.count = count
            if self._tagSetDistance[n1,n2] < self._tagSetStats.lowBound {
               self._tagSetStats.lowBound = self._tagSetDistance[n1,n2]
            }
            if self._tagSetDistance[n1,n2] > self._tagSetStats.highBound {
               self._tagSetStats.highBound = self._tagSetDistance[n1,n2]
            }
            tempM = tagSetM + ((Double(self._tagSetDistance[n1,n2]) - tagSetM)/Double(count))
            tempS = tagSetS + ((Double(self._tagSetDistance[n1,n2]) - tagSetM)*(Double(self._tagSetDistance[n1,n2])-tempM))
            tagSetM = tempM
            tagSetS = tempS
            self._tagSetStats.count = count
            if self._pathDistance[n1,n2] < self._pathStats.lowBound {
               self._pathStats.lowBound = self._pathDistance[n1,n2]
            }
            if self._pathDistance[n1,n2] > self._pathStats.highBound {
               self._pathStats.highBound = self._pathDistance[n1,n2]
            }
            tempM = pathM + ((Double(self._pathDistance[n1,n2]) - pathM)/Double(count))
            tempS = pathS + ((Double(self._pathDistance[n1,n2]) - pathM)*(Double(self._pathDistance[n1,n2])-tempM))
            pathM = tempM
            pathS = tempS
            self._pathStats.count = count
         }
      }
      self.updated = false
      self._itemSetStats.mean = itemSetM
      self._itemSetStats.std = (count==0) ? 0.0 : sqrt(itemSetS/Double(count))
      self._tagSetStats.mean = tagSetM
      self._tagSetStats.std = (count==0) ? 0.0  : sqrt(tagSetS/Double(count))
      self._pathStats.mean = pathM
      self._pathStats.std = (count==0) ? 0.0  : sqrt(pathS/Double(count))
   }
   
   /// Verify that each entry in the distance matrix is the minimum and report any exceptions
   /// - Parameter typ: the distance metric
   /// - Returns: the list of entries that are in error
   func validateDistanceMatrix(typ: DistanceType) -> [DistanceErrorEntry] {
      var rslt = Array<DistanceErrorEntry>()
      let mat = distanceMatrix(typ: typ)
      for n1 in 0..<self.nodes-1 {
         for n2 in n1+1..<self.nodes {
            if pairOccurs[n1,n2] > 0 {    //Q. Co-occurs in original data
               continue                   //A. Yes, no need to check further
            }
            // Did not co-occur in data, so check the path distance
            var minDistance = Float(self.nodes)    // All distances will be less than this
            var foundMin = false
            for m in 0..<self.nodes {
               if m==n1 || m==n2 {        //Q. Is this a diagonal entry
                  continue                //A. Yes. skip it
               }
               if mat[n1,m] == 0.0 || mat[n2,m] == 0.0 {
                  continue
               }
               if minDistance > mat[n1,m] + mat[n2,m] {
                  minDistance = mat[n1,m] + mat[n2,m]
                  foundMin = true
               }
            }
            if mat[n1,n2] != minDistance  && foundMin {
               let entry = DistanceErrorEntry(id: NodePair(n1,n2), n1: n1, n2: n2, recordedDistance: mat[n1,n2], minimumDistance: minDistance)
               rslt.append(entry)
            }
         }
      }
      return rslt
   }
}

/// Distance matrix errors
struct DistanceErrorEntry: Identifiable {
   var id: NodePair
   var n1: Int
   var n2: Int
   var recordedDistance: Float
   var minimumDistance: Float
}

/// Descriptive information for a collection or a slice of a collection of values
struct StatsEntry: Identifiable {
   var id : Int
   var lowBound : Float
   var highBound: Float
   var count : Int
   var mean : Double
   var std : Double
   init() {
      id = 0
      lowBound = Float.greatestFiniteMagnitude
      highBound = 0.0
      count = 0
      mean = 0.0
      std = 0.0
   }
   init(id: Int, lowBound: Float, highBound: Float, count: Int, mean: Double, std: Double) {
      self.id = id
      self.lowBound = lowBound
      self.highBound = highBound
      self.count = count
      self.mean = mean
      self.std = std
   }
}

/// Descriptive information concerning the connections for a node.  Note that nodes with zero occurrences are not counted
struct NodeConnectStat: Identifiable {
   var id: Int             // original node identifier
   var numNoConnect: Int   // Not reachable, but present
   var numAdjacent: Int    // directly connected in the underlying data
   var numIndirect: Int    // connected via an adjacent node
   var minAdjTagset: Float // minimum tagset distance of adjacent nodes
   var maxAdjTagset: Float // maximum tagset distance of adjacent nodes
   var avgAdjTagset: Float // average tagset distance of adjacent nodes
   var numBelowAvg: Int    // number of adjacent nodes closer than the average
   var adjNodes: Set<Int>  // adjacent node identifiers
   var adjNumCommon: [Int:Int] // adjacent node with num tags in common
   var adjTagsetDst: [Int:Float] // adj node with tagset distance
}

/// Description of an isolated region
struct IslandStat: Identifiable {
   var id: Int             // lowest node id (original or R/C as requected)
   var nodes: Set<Int>     // list of nodes (original or R/C as requested)
   var numWithMany: Int    // number of nodes with more than 4 adjacent nodes
   var numWithMax:  Int    // number of nodes with max adjacent nodes
   var numWith4Adj: Int    // number of nodes with 4 adjacent nodes
   var numWith3Adj: Int    // number of nodes with 3 adjacent nodes
   var numWith2Adj: Int    // number of nodes with 2 adjacent nodes
   var numWith1Adj: Int    // number of nodes with 1 adjacent node
   var minAdjacent: Int    // fewest adjacent nodes to any node
   var maxAdjacent: Int    // most adjacent nodes to any node
   var avgAdjacent: Float  // average number of adjacent nodes
}

typealias NumCmpr = Comparable & Numeric
/// Square symmetric matrix.  The upper triangle is stored.
class SymSqMatrix<T : NumCmpr> {
   let rc: Int
   var matrix : [T]
   enum OperationError: Error {
      case DimensionMismatch
      case SubscriptBounds
   }
   
   /// Initializer
   /// - Parameter rows: number of rowd (columns)
   init(rows: Int) {
      rc = rows
      let entries = (rows+1)*rows/2
      matrix = Array<T>(repeating: T.zero, count: entries)
   }
   /// Are the row and column values in bounds for this matrix
   /// - Parameters:
   ///   - row: the row number with base zero
   ///   - column: the column number with base zero
   /// - Returns: both the row and column value are  >= 0 and < rows
   func isValid(row: Int, column: Int) -> Bool {
      return row >= 0 && row < rc && column >= 0 && column < rc
   }
   /// The array position associated with the row and column
   /// - Parameters:
   ///   - row: row number
   ///   - column: column number
   /// - Returns: position in the underlying array corresponding to the row and column numbers
   func position(row: Int, column: Int) -> Int {
      let r = row <= column  ? row : column
      let c = row <= column  ? column : row
      return (r*rc)-((r*(r-1))/2) + c - r
   }
   /// Clear the matrix to zero
   func clear() {
      for i in 0..<matrix.count {
         matrix[i] = T.zero
      }
   }
   subscript(row: Int, column: Int) -> T {
      get {
         return matrix[position(row: row, column: column)]
      }
      set {
         matrix[position(row: row, column: column)] = newValue
      }
   }
   /// Add the parameter into this matrix.  Dimensions must match
   /// - Parameter addend: the matrix to be added into this matrix
   func plus(_ addend: SymSqMatrix<T>) throws {
      guard self.rc == addend.rc else {
         throw OperationError.DimensionMismatch
      }
      for pos in 0..<self.rc {
         self.matrix[pos] += addend.matrix[pos]
      }
   }
   /// Subtract the parameter matrix from this matrix
   /// - Parameter subtrahend: the matrix subtracted from this matrix
   func minus(_ subtrahend: SymSqMatrix<T>) throws {
      guard self.rc == subtrahend.rc else {
         throw OperationError.DimensionMismatch
      }
      for pos in 0..<self.rc {
         self.matrix[pos] -= subtrahend.matrix[pos]
      }
   }
}

/// A pair of differing nodes in a cononalcal form suitable as a key
struct NodePair : Hashable, Comparable {
   let n1 : Int
   let n2 : Int
   init(_ node1: Int, _ node2: Int) {
      if node1 > node2 {
         self.n1 = node2
         self.n2 = node1
      } else {
         self.n1 = node1
         self.n2 = node2
      }
   }
   static func <(lhs: NodePair, rhs: NodePair) -> Bool {
      if lhs.n1 != rhs.n1 {
         return lhs.n1 < rhs.n1
      }
      return lhs.n2 < rhs.n2
   }
   static func ==(lhs: NodePair, rhs: NodePair) -> Bool {
      return lhs.n1 == rhs.n1 && lhs.n2 == rhs.n2
   }
   func hash(into hasher: inout Hasher) {
      hasher.combine(n1)
      hasher.combine(n2)
   }
}

