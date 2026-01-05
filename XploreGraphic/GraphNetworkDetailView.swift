//
//  GraphNetworkDetailView.swift
//  XploreGraphic
//
//  Created by John Holt on 9/7/25.
//

import SwiftUI
import Foundation

struct GraphNetworkDetailView: View {
   @Environment(\.dismiss) private var dismiss
   @Binding var network: TagNetwork
   @Binding var islands: [IslandEntry]
   @Binding var regions: [RegionEntry]
   @Binding var nodes: [NodeEntry]
   @Binding var edges: [EdgeEntry]
   
   var body: some View {
      NavigationStack {
         VStack {
            Spacer()
            Text("There are \(network.numNodes) tags in the graph")
            Text("The working grid is \(network.gridWidth) x \(network.gridHeight)")
            Text("There are \(islands.count) islands, and \(regions.count) regions")
            Spacer()
            Table(islands) {
               TableColumn("id") {entry in Text("\(entry.id)")}
               TableColumn("Num nodes") {entry in Text("\(entry.nodes.count)")}
               TableColumn("Nodes") {entry in Text("\(entry.nodes.formatted(.list(memberStyle: IntegerFormatStyle(), type: .and, width: .narrow)))")}
               TableColumn("width") {entry in Text("\(entry.width)")}
               TableColumn("height") {entry in Text("\(entry.height)")}
               TableColumn("x-pos") {entry in Text("\(entry.xpos)")}
               TableColumn("y-pos") {entry in Text("\(entry.ypos)")}
               TableColumn("Min regions") {entry in Text("\(entry.minRegions)")}
               TableColumn("Max regions") {entry in Text("\(entry.maxRegions)")}
               TableColumn("Max Adj") {entry in Text("\(entry.maxAdjacent)")}
            }
            Table(regions) {
               TableColumn("id") { entry in Text("\(entry.id)")}
               TableColumn("island") {entry in Text("\(entry.island)")}
               TableColumn("Num interior") {entry in Text("\(entry.interior.count)")}
               TableColumn("Interior") {entry in Text("\(entry.interior.formatted(.list(memberStyle: IntegerFormatStyle(), type: .and, width: .narrow)))")}
               TableColumn("Num exterior") {entry in Text("\(entry.exterior.count)")}
               TableColumn("Exterior") {entry in Text("\(entry.exterior.formatted(.list(memberStyle: IntegerFormatStyle(), type: .and, width: .narrow)))")}
               TableColumn("width") {entry in Text("\(entry.width)")}
               TableColumn("height") {entry in Text("\(entry.height)")}
               TableColumn("x-pos") {entry in Text("\(entry.xpos)")}
               TableColumn("y-pos") {entry in Text("\(entry.ypos)")}
            }
            Table(nodes) {
               TableColumn("id") {entry in Text("\(entry.id)")}
               TableColumn("island") {entry in Text("\(entry.island)")}
               TableColumn("region") {entry in Text("\(entry.region)")}
               TableColumn("xpos") {entry in Text("\(entry.xpos)")}
               TableColumn("ypos") {entry in Text("\(entry.ypos)")}
               TableColumn("inLinks") {entry in Text("\(entry.inLinks.formatted(.list(memberStyle: IntegerFormatStyle(), type: .and, width: .narrow)))")}
               TableColumn("exLinks") {entry in Text("\(entry.exLinks.formatted(.list(memberStyle: IntegerFormatStyle(), type: .and, width: .narrow)))")}
            }
            Table(edges) {
               TableColumn("id") {entry in Text("\(entry.id.n1)-\(entry.id.n2)")}
               TableColumn("island") {entry in Text("\(entry.island)")}
               TableColumn("region 1") {entry in Text("\(entry.n1Region)")}
               TableColumn("xpos 1") {entry in Text("\(entry.n1Xpos)")}
               TableColumn("ypos 1") {entry in Text("\(entry.n1Ypos)")}
               TableColumn("region 2") {entry in Text("\(entry.n2Region)")}
               TableColumn("xpos 2") {entry in Text("\(entry.n2Xpos)")}
               TableColumn("ypos 2") {entry in Text("\(entry.n2Ypos)")}
            }
         }
      }
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
}


//Preview support
var boundIslands = Binding.constant(network4Preview.islands())
var boundRegions = Binding.constant(network4Preview.regions())
var boundNodes = Binding.constant(network4Preview.nodes())
var boundEdges = Binding.constant(network4Preview.edges())

#Preview {
   GraphNetworkDetailView(network: boundNetwork,
                          islands: boundIslands, regions: boundRegions,
                          nodes: boundNodes, edges: boundEdges)
}
