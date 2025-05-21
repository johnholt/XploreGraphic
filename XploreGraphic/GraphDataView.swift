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
   @State private var histogram = Array(repeating: StatsEntry(), count: 1)
   @State private var distanceType = UndirectedGraph.DistanceType.PathLength
   @State private var nTile : Int = 0
   let nTiles = [4, 5, 10, 20, 50, 100]
   
   var body: some View {
      VStack {
         HStack {
            VStack {
               Button ("Back") {    // work around for macOS bug
                  dismiss()
               }
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
               Button(action: {histogram  = graph.histogram(type: distanceType, bins: bins)}) {
                  Text("Refresh")
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
         .onAppear(perform: {prepState()})
      }
   }
   
   func prepState() -> Void {
      histogram = graph.histogram(type: distanceType, bins: bins)
      var temp = nTiles.count-1
      for i in 0..<nTiles.count {
         if bins <= nTiles[i] {
            temp = i
            break
         }
         nTile = temp
      }
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

#Preview {
   GraphDataView(graph: boundGraph, bins: boundBins)
}
