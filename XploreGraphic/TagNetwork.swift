//
//  TagNetwork.swift
//  XploreGraphic
//
//  Created by John Holt on 12/16/24.
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
   
   /// A factor to add to an external node ID value to convert it to a zero based row/column value
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
   
   // Derived inforamtion
   /// Assign each node to a cluster using the specified distance metric
   /// - Parameter type: the distance metric to use for clustering
   /// - Returns: an array of cluster identifiers corresponding to the list of nodes.  Nodes that did
   /// not appear in the underlying data as assigned to the 0 cluster
   func clusterAssignments(type: DistanceType) -> Array<Int> {
      return Array<Int>(repeating: 0, count: self.nodes)
   }
   /// The list of regions of connected nodes
   /// - Parameter adjustNodeIdent: Default to returning the list of original node identifiers instead
   ///  of the list of adjusted node identifiers that map to row/column identifiers in an adjacey matrix
   /// - Returns: a list with one or more
   func getIslands(adjustNodeIdent : Bool = true) -> [IslandEntry] {
      var rslt = Array<IslandEntry>()
      for n1 in 0..<self.nodes {
         if numLists4Node[n1] == 0 {   //Q. Is this node used
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
               if self._pathDistance[m,n1] == 1 {  //Q. Is the node adjacent
                  neighbors += 1                   //A. Yes, count it
               }
            }
            if neighbors == 1 {
               rslt[island].numWithEnds += 1      // this node is an end
            } else if neighbors > 1 {
               rslt[island].numWithBridge += 1     // this node bridges
            }
            continue             // advance to the next node
         }
         // n1 is the low nominal for a new region
         var neighbors = 0
         var nodeList = Set<Int>()
         for m in 0..<self.nodes {
            let ndx4List = (adjustNodeIdent) ? convert2ID(m)  : m
            nodeList.insert(ndx4List)
            if m != n1 {      //Q. The diagonal
               if self._pathDistance[m,n1] == 1 { //Q. Is m a neighbor
                  neighbors += 1                   //A. Yes, count it
               }
            }
         }
         let newIsland = IslandEntry(id: ndx4Test, nodes: nodeList,
                                     numWithBridge: (neighbors>1) ? neighbors : 0,
                                     numWithEnds: (neighbors==1) ? 1 : 0)
         rslt.append(newIsland)
      }
      return rslt
   }
   /// Convert and original node Identifier into a Row/Column value for an adjacency matrix
   /// - Parameter nodeID: the original node ID, sucj as the Tag Identifier nominal
   /// - Returns: a row or column value for an adjacency matrix
   func convert2RC(_ nodeID: Int) -> Int {
      return nodeID + self.adjust
   }
   /// Convert a row/column into an original node identifier, such as a tag nominal
   /// - Parameter rc: the row/column value for an adjacency matrix
   /// - Returns: an identifier nominal
   func convert2ID(_ rc: Int) -> Int {
      return rc + self.adjust
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
      let interval = (baseStats.highBound-baseStats.lowBound) / Float(bins)
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
      guard self.nodes > 0 else {return rslt}
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
   /// Summary distnce statistics.  Stats include minimum, maximum, mean, and standard deviation
   /// - Parameter typ: the distance type, PathLength, ItemsetJaccard, or TagsetJaccard
   /// - Returns: The descriptive stats
   func distanceStats(typ: DistanceType) -> StatsEntry {
      if updated {
         calcDistances()
      }
      switch typ {
         case .ItemsetJaccard:
            return _itemSetStats
         case .TagsetJaccard:
            return _tagSetStats
         case .PathLength:
            return _pathStats
      }
   }
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
   }
   
   /// Add a path instancce to the graph.  A path instance is a set of nodes that co-occurred
   /// in the source data.  For instance, the items on a receipt could be captured as a set of co-occuring
   /// nodes.
   /// - Parameter list: the set of node identifiers that co-occur
   func add(list: Set<Int>) {
      var nodeList = Array<Int>()
      for nodeId in list {
         nodeList.append(nodeId + adjust)
      }
      for row in nodeList {
         for column in nodeList {
            if row > column {    //Q. position in lower triangle
               continue          //A. Yes, no need to count
            }
            if row == column {   //Q. position on the diagonal
               self.numLists4Node[row] += 1 //A. Yes, Count only as a participant
               continue
            }
            self.pairOccurs[row,column] += 1  // on the uppoer triangle, count the pair
         }
      }
      self.numListOccurrences += 1
      let prevUniques = listOccurrences.count
      self.listOccurrences[nodeList.sorted()] = 1 + (self.listOccurrences[nodeList.sorted()] ?? 0)
      if prevUniques < self.listOccurrences.count {  //Q. Did we just add a new list?
         self.uniqueLists += 1                       //A. Yes, count it
      }
      self.updated = true
   }
   
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
   
   /// Calculate the distance matrices for all nodes.  A zero means that there is no path connecting the pair of nodes
   private func calcDistances() -> Void {
      var isolatedPairs: Int = nodes*(nodes-1)/2      // ordered pairs
      _itemSetDistance.clear()
      _tagSetDistance.clear()
      _pathDistance.clear()
      //Determine the Jaccard distance for the nodes that co-occur in the
      //underlying data and set those pairs to a path distance of 1
      //Calculate both item set and tag set Jaccard distance
      for n1 in 0..<nodes-1 {
         if numLists4Node[n1] == 0 {         //Q. Was this node in the data?
            continue                         //A. No, skip it
         }
         for n2 in n1+1..<nodes {
            if numLists4Node[n2] == 0 {      //Q. was this node in the data?
               continue                      //A. No, skip it
            }
            if pairOccurs[n1,n2] == 0 {      //Q. Do these nodes co-occur?
               continue                      //A. No, can't calculate distance
            }                                //     from underlyiing data
            _itemSetDistance[n1,n2] = 1.0
                                 - (Float(pairOccurs[n1,n2])
                                    / Float(numLists4Node[n1]
                                         + numLists4Node[n2]
                                         - Int(pairOccurs[n1,n2])))
            _pathDistance[n1,n2] = 1
            // Determine Jaccard distance using the tag sets
            var both = 0      // both present, the cardinality of the intersection of the sets
            var either = 0    // either one or both, the cardinality of the union of the sets
            // use the node number as the row and vary the column number
            for column in 0..<nodes {
               if column == n1 {                // Q. is this the diagonal entry of the n1 row
                  either += 1                   // A. yes, only need to check n2 entry
                  both += (pairOccurs[n2,column] > 0) ? 1 : 0
               } else if column == n2 {         // Q. is this the diagonal entry for the n2 row
                  either += 1                   // A. yes, only need to check the n1 entry
                  both += (pairOccurs[n1,column] > 0) ? 1 : 0
               } else if pairOccurs[n1,column] > 0 && pairOccurs[n2,column] > 0 {  // Q. both exist?
                  both += 1                                                        // A. yes
                  either += 1
               } else if pairOccurs[n1,column] > 0 || pairOccurs[n2,column] > 0 { // Q. only 1 is present
                  either += 1                                                     // A. yes
               }
            }
            _tagSetDistance[n1,n2] = 1.0 - Float(both)/Float(either)
            isolatedPairs -= 1
         }
      }
      // Now determine distances for pairs that are not directly associated.
      var changed = true
      var iter = 1
      while iter < self.nodes - 1 && changed
               && isolatedPairs > 0 {        //Q. At longest possible path or early exit?
         changed = false                     //A. No, check to extend path
         iter += 1
         for n1 in 0..<self.nodes-1 {
            if numLists4Node[n1] == 0 {      //Q. Was node in the data?
               continue                      //A. No, skip
            }
            for n2 in n1+1..<self.nodes {
               if numLists4Node[n2] == 0 {   //Q. Was node in the data?
                  continue                   //A. No, skip
               }
               if _pathDistance[n1,n2] != 0 {  //Q. Already in a path
                  continue                   //A. Yes, skip
               }
               // use the node numbers as the rows and vary the column number
               // to find the pairs that connect.  Record the distances
               var paths : [Int : Float] = [:]
               var itemsets : [Int : Float] = [:]
               var tagsets : [Int : Float] = [:]
               var haveConnection = false
               for column in 0..<self.nodes {
                  if _pathDistance[n1,column] != 0
                        && _pathDistance[n2,column] != 0 {  //Q. is there a connection?
                     paths[column] = _pathDistance[n1,column] + _pathDistance[n2,column]
                     itemsets[column] = _itemSetDistance[n1,column] + _itemSetDistance[n2,column]
                     tagsets[column] = _tagSetDistance[n1,column] + _tagSetDistance[n2,column]
                     haveConnection = true
                  }
               }
               if !haveConnection {       //Q. Anything to connect the nodes n1 & n2?
                  continue                //A. Nothing, check the next pair
               }
               // have one or more connections, now select the minimums
               var minPathLength = Float(Int16.max)
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
               _pathDistance[n1,n2] = minPathLength
               _itemSetDistance[n1,n2] = minItemsetLen
               _tagSetDistance[n1,n2] = minTagsetLen
               isolatedPairs -= 1
               changed = true
            }
         }
      }
      // calculate stats for networks.  Running mean and variance from Welford
      // in Knuth Art of Computer Programming Volume 2 page 232
      _itemSetStats.highBound = 0.0
      _itemSetStats.lowBound = Float.greatestFiniteMagnitude
      _tagSetStats.highBound = 0.0
      _tagSetStats.lowBound = Float.greatestFiniteMagnitude
      _pathStats.highBound = 0.0
      _pathStats.lowBound = Float.greatestFiniteMagnitude
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
         if numLists4Node[n1] == 0 {      //Q. Was node in the data?
            continue                      //A. No, skip
         }
         for n2 in n1+1..<self.nodes {
            if numLists4Node[n2] == 0 {      //Q. Was node in the data?
               continue                      //A. No, skip
            }
            count += 1
            if _itemSetDistance[n1,n2] < _itemSetStats.lowBound {
               _itemSetStats.lowBound = _itemSetDistance[n1,n2]
            }
            if _itemSetDistance[n1,n2] > _itemSetStats.highBound {
               _itemSetStats.highBound = _itemSetDistance[n1,n2]
            }
            tempM = itemSetM + ((Double(_itemSetDistance[n1,n2]) - itemSetM)/Double(count))
            tempS = itemSetS + ((Double(_itemSetDistance[n1,n2]) - itemSetM)*(Double(_itemSetDistance[n1,n2])-tempM))
            itemSetM = tempM
            itemSetS = tempS
            _itemSetStats.count = count
            if _tagSetDistance[n1,n2] < _tagSetStats.lowBound {
               _tagSetStats.lowBound = _tagSetDistance[n1,n2]
            }
            if _tagSetDistance[n1,n2] > _tagSetStats.highBound {
               _tagSetStats.highBound = _tagSetDistance[n1,n2]
            }
            tempM = tagSetM + ((Double(_tagSetDistance[n1,n2]) - tagSetM)/Double(count))
            tempS = tagSetS + ((Double(_tagSetDistance[n1,n2]) - tagSetM)*(Double(_tagSetDistance[n1,n2])-tempM))
            tagSetM = tempM
            tagSetS = tempS
            _tagSetStats.count = count
            if _pathDistance[n1,n2] < _pathStats.lowBound {
               _pathStats.lowBound = _pathDistance[n1,n2]
            }
            if _pathDistance[n1,n2] > _pathStats.highBound {
               _pathStats.highBound = _pathDistance[n1,n2]
            }
            tempM = pathM + ((Double(_pathDistance[n1,n2]) - pathM)/Double(count))
            tempS = pathS + ((Double(_pathDistance[n1,n2]) - pathM)*(Double(_pathDistance[n1,n2])-tempM))
            pathM = tempM
            pathS = tempS
            _pathStats.count = count
         }
      }
      self.updated = false
      _itemSetStats.mean = itemSetM
      _itemSetStats.std = (count==0) ? 0.0 : sqrt(itemSetS/Double(count))
      _tagSetStats.mean = tagSetM
      _tagSetStats.std = (count==0) ? 0.0  : sqrt(tagSetS/Double(count))
      _pathStats.mean = pathM
      _pathStats.std = (count==0) ? 0.0  : sqrt(pathS/Double(count))
   }
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
struct ConnectEntry: Identifiable {
   var id: Int             // original node identifier
   var numNoConnect: Int   // Not reachable, but present
   var numAdjacent: Int    // directly connected in the underlying data
   var numIndirect: Int    // connected via an adjacent node
}

/// Description of an isolated region
struct IslandEntry: Identifiable {
   var id: Int             // lowest node id (original or RC as requected) in region
   var nodes: Set<Int>     // list of nodes (original or RC as requested) in region
   var numWithBridge: Int  // number of nodes with 2 or more adjacent nodes
   var numWithEnds: Int    // number of nodes with one 1 adjacent node
}

struct RegionEntry: Identifiable {
   var id: Int             // zero based identifier of the region
   var island: Int         // identifier of the island containing this dregion
   var nodes : Set<Int>    // list of contained node identifiers (original), excludes bridge nodes
   var bridges : Set<Int>  // list of bridge nodes.  An empty set occurs when region covers an island
}

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
typealias NumCmpr = Comparable & Numeric

struct NodePair : Hashable {
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
   static func ==(lhs: NodePair, rhs: NodePair) -> Bool {
      return lhs.n1 == rhs.n1 && lhs.n2 == rhs.n2
   }
   func hash(into hasher: inout Hasher) {
      hasher.combine(n1)
      hasher.combine(n2)
   }
}


