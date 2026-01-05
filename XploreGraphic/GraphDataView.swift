//
//  GraphDataView.swift
//  XploreGraphic
//  View graph statistics and graph
//  Created by John Holt on 4/4/25.
//

import SwiftUI
import Charts

struct GraphDataView: View {
   @Environment(\.dismiss) private var dismiss
   @Binding var graph: UndirectedGraph
   @Binding var bins: Int
   @Binding var distanceType : UndirectedGraph.DistanceType
   @State private var histogram = Array(repeating: StatsEntry(), count: 1)
   @State private var nTile : Int = 0
   @State private var stats = StatsEntry()
   let nTiles = [4, 5, 10, 20, 50, 100]
   @State private var islands = Array<IslandStat>()
   @State private var connections = Array<NodeConnectStat>()
   
   var body: some View {
      VStack {
         HStack {
            VStack {
               Stepper {
                  Text("Number of bins: \(nTiles[nTile])")
               } onIncrement: {
                  nTile += 1
                  if nTile >= nTiles.count { nTile = 0}
                  bins = nTiles[nTile]
               } onDecrement: {
                  nTile -= 1
                  if nTile < 0 { nTile = nTiles.count - 1 }
                  bins = nTiles[nTile]
               }
               Picker("Distance Measure", selection: $distanceType) {
                  Text("Path Length").tag(UndirectedGraph.DistanceType.PathLength)
                  Text("Tagset Jaccard").tag(UndirectedGraph.DistanceType.TagsetJaccard)
                  Text("Itemset Jaccard").tag(UndirectedGraph.DistanceType.ItemsetJaccard)
               }
               .pickerStyle(.menu)
               Button(action: {newDistanceType()}) {
                  Text("Refresh")
               }
               HStack {
                  VStack {
                     Text("Low Bound")
                     Text("\(stats.lowBound)")
                  }
                  VStack {
                     Text("High Bound")
                     Text("\(stats.highBound)")
                  }
                  VStack {
                     Text("Count")
                     Text("\(stats.count)")
                  }
                  VStack {
                     Text("Mean")
                     Text("\(stats.mean)")
                  }
                  VStack {
                     Text("Std")
                     Text("\(stats.std)")
                  }
               }
            }
            Table(histogram) {
               TableColumn("Low Bound") { entry in Text("\(entry.lowBound)") }
               TableColumn("High Bound") {entry in Text("\(entry.highBound)")}
               TableColumn("Count") {entry in Text("\(entry.count)")}
               TableColumn("Mean") {entry in Text("\(entry.mean)")}
               TableColumn("Std") {entry in Text("\(entry.std)")}
            }
         }
         Table(islands) {
            TableColumn("ID") {entry in Text("\(entry.id)")}
            TableColumn("Nodes") {entry in Text("\(entry.nodes.count)")}
            TableColumn("w/<3 Adj") {entry in Text("\(entry.numWith2Adj + entry.numWith1Adj)")}
            TableColumn("w/3 Adj") {entry in Text("\(entry.numWith3Adj)")}
            TableColumn("w/4 Adj") {entry in Text("\(entry.numWith4Adj)")}
            TableColumn("w/many Adj") {entry in Text("\(entry.numWithMany)")}
            TableColumn("w/Max Adj") {entry in Text("\(entry.numWithMax)")}
            TableColumn("Min Adjacent") {entry in Text("\(entry.minAdjacent)")}
            TableColumn("Max Adjacent") {entry in Text("\(entry.maxAdjacent)")}
            TableColumn("Avg Adjacent") {entry in Text("\(entry.avgAdjacent)")}
         }
         Table(connections) {
            TableColumn("Node") {entry in Text("\(entry.id)")}
            TableColumn("Isolated") {entry in Text("\(entry.numNoConnect)")}
            TableColumn("Adjacent") {entry in Text("\(entry.numAdjacent)")}
            TableColumn("Indirect") {entry in Text("\(entry.numIndirect)")}
            TableColumn("Min Distance") {entry in Text("\(entry.minAdjTagset)")}
            TableColumn("Max Distance") {entry in Text("\(entry.maxAdjTagset)")}
            TableColumn("Avg Distance") {entry in Text("\(entry.avgAdjTagset)")}
            TableColumn("Number Below Avg") {entry in Text("\(entry.numBelowAvg)")}
         }
         Table(connections) {
            TableColumn("ID") {entry in Text("\(entry.id)")}
            TableColumn("Adj nodes") {entry in Text("\(entry.adjNodes.formatted(.list(memberStyle: IntegerFormatStyle(), type: .and, width: .narrow)))")}
            TableColumn("Common Counts") {entry in Text("\(entry.adjNumCommon)")}
            TableColumn("Adj J-Dist") {entry in Text("\(entry.adjTagsetDst)")}
        }
      }
      .onAppear(perform: {prepState()})
#if os(macOS)        // bug: nav bar back button covered up by title
      .navigationBarBackButtonHidden(true)
      .toolbar {
         ToolbarItem(placement: .navigation) {
            Button(action: { dismiss() }) {
               Label("Back", systemImage: "arrow.left.circle")
            }
         }
      }
#endif
   }
   
   func prepState() -> Void {
      stats = graph.distanceStats(typ: distanceType)
      histogram = graph.histogram(type: distanceType, bins: bins)
      var temp = nTiles.count-1
      for i in 0..<nTiles.count {
         if bins <= nTiles[i] {
            temp = i
            break
         }
      }
      nTile = temp
      islands = graph.islandsFromDistanceMatrix(adjustNodeIdent: true)
      connections = graph.connectStatsFromDistanceMatrix()
   }
   func newDistanceType() -> Void {
      histogram  = graph.histogram(type: distanceType, bins: bins)
      stats = graph.distanceStats(typ: distanceType)
   }
}


// Preview support
func makeGraph4Preview() -> UndirectedGraph {
   let gen = GeneratedCollection(parameters: DataParameters())
   let graph = UndirectedGraph(nodes: gen.numTags, adjustment: -1)
   for item in gen.items {
      graph.add(list: item.tagIdList)
   }
   return graph
}
var graph4Preview = makeGraph4Preview()
var boundGraph = Binding.constant(graph4Preview)
var boundBins = Binding.constant(Int(4))
var distType = Binding.constant(UndirectedGraph.DistanceType.PathLength)

#Preview {
   GraphDataView(graph: boundGraph, bins: boundBins, distanceType: distType)
}
