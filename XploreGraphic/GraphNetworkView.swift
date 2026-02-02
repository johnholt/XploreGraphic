//
//  GraphNetworkView.swift
//  XploreGraphic
//
//  Created by John Holt on 7/5/25.
//

import SwiftUI
import Foundation

internal let minFactor: Double = 10.0

struct GraphNetworkView: View {
   @Environment(\.dismiss) private var dismiss
   @Environment(\.menuBridge) private var menuBridge: MenuBridge
   @Binding var network: TagNetwork
   @State private var islands: [IslandEntry] = Array<IslandEntry>()
   @State private var regions: [RegionEntry] = Array<RegionEntry>()
   @State private var nodes:   [NodeEntry]   = Array<NodeEntry>()
   @State private var edges:   [EdgeEntry]   = Array<EdgeEntry>()
   @State private var scale: CGFloat = 1.0
   @State private var anchor: UnitPoint = .zero // .topLeading
   @State private var currentOffset: CGSize = .zero
   @State private var tapLocation: CGPoint = .zero
   @State private var tagInfo: TagInfo?
   @State private var factor: Double = 10.0     // Should match minFactor constant below
   
   internal var canvasSpaceName = "GraphNetworkViewCanvas"
   private var dragGraph: some Gesture {
      DragGesture(coordinateSpace: .named(canvasSpaceName))
         .onChanged { value in currentOffset = value.translation}
         .onEnded { value in currentOffset = value.translation}
   }
   private var magnification: some Gesture {
      MagnifyGesture()
         .onChanged {value in scale = value.magnification}
         .onEnded({value in scale = value.magnification})
   }
   private var revealDetails: some Gesture {
      SpatialTapGesture(count: 1, coordinateSpace: .named(canvasSpaceName))
         .onEnded { location in tapLocation = location.location }
   }
   
    var body: some View {
       NavigationStack {
          VStack {
             Spacer()
             Text("There are \(network.numNodes) tags in the graph")
             Text("The working grid is \(network.gridWidth) x \(network.gridHeight)")
             Text("There are \(islands.count) islands, and \(regions.count) regions")
             Spacer()
             GeometryReader {geometry in
                Canvas {ctx, size in
                   let factor = calcFactor(network: network, displaySize: size)
                   let midPoint = factor / 2.0
                   let radius = factor / 4.0
                   var pathIsland = Path()
                   for island in islands {
                      let xpos = Double(island.xpos) * factor
                      let ypos = Double(island.ypos) * factor
                      let width = Double(island.width) * factor
                      let height = Double(island.height) * factor
                      pathIsland.move(to: CGPoint(x: xpos, y: ypos))
                      pathIsland.addLine(to: CGPoint(x: xpos+width, y: ypos))
                      pathIsland.addLine(to: CGPoint(x: xpos+width, y: ypos+height))
                      pathIsland.addLine(to: CGPoint(x: xpos, y: ypos+height))
                      pathIsland.addLine(to: CGPoint(x: xpos, y: ypos))
                      pathIsland.closeSubpath()
                   }
                   ctx.stroke(pathIsland, with: .color(.blue), lineWidth: 5)
                   var pathRegion = Path()
                   for region in regions {
                      let xpos = Double(region.xpos) * factor
                      let ypos = Double(region.ypos) * factor
                      let width = Double(region.width) * factor
                      let height = Double(region.height) * factor
                      pathRegion.move(to: CGPoint(x: xpos, y: ypos))
                      pathRegion.addLine(to: CGPoint(x: xpos+width, y: ypos))
                      pathRegion.addLine(to: CGPoint(x: xpos+width, y: ypos+height))
                      pathRegion.addLine(to: CGPoint(x: xpos, y: ypos+height))
                      pathRegion.addLine(to: CGPoint(x: xpos, y: ypos))
                      pathRegion.closeSubpath()
                   }
                   ctx.stroke(pathRegion, with: .color(.green), lineWidth: 2)
                   var pathEdge = Path()
                   //  NOTE: Want to classify edges as straight lines or curved lines
                   //  NOTE: Want to use different line colors for intra-region versus inter-region
                   for edge in edges {
                      let n1Xpos = Double(edge.n1Xpos) * factor
                      let n1Ypos = Double(edge.n1Ypos) * factor
                      let n2Xpos = Double(edge.n2Xpos) * factor
                      let n2Ypos = Double(edge.n2Ypos) * factor
                      pathEdge.move(to: CGPoint(x: n1Xpos + midPoint,
                                                y: n1Ypos + midPoint))
                      pathEdge.addLine(to: CGPoint(x: n2Xpos + midPoint,
                                                   y: n2Ypos + midPoint))
                      pathEdge.closeSubpath()
                   }
                   ctx.stroke(pathEdge, with: .color(.cyan), lineWidth: 1.0)
                   var nodePath = Path()
                   let startAngle = Angle(degrees: 0)
                   let stopAngle = Angle(degrees: 360)
                   for node in nodes {
                      let xpos = Double(node.xpos) * factor + midPoint
                      let ypos = Double(node.ypos) * factor + midPoint
                      let center = CGPoint(x: xpos, y: ypos)
                      nodePath.addArc(center: center, radius: radius,
                                      startAngle: startAngle, endAngle: stopAngle,
                                      clockwise: true)
                   }
                   nodePath.closeSubpath()
                   ctx.stroke(nodePath, with: .color(.black), lineWidth: 2.0)
                }
                .coordinateSpace(.named(canvasSpaceName))
                .gesture(dragGraph)
                .offset(currentOffset)
                .animation(.interactiveSpring, value: currentOffset)
                .clipped()
                .onTapGesture(count:2) {
                   scale = 1.0
                   currentOffset = .zero}
                .gesture(magnification)
                .scaleEffect(scale, anchor: anchor)
                .animation(.easeInOut, value: scale)
                .gesture(revealDetails)
                .onChange(of: tapLocation, initial: false) { oldstate, newstate in
                   tagInfo = findTagInfo(network: network, displaySize: geometry.size,
                                         tapLocation: newstate, scale: scale, offset: currentOffset)
                }
                .popover(item: $tagInfo,
                         attachmentAnchor: PopoverAttachmentAnchor.point(UnitPoint(x: tapLocation.x/geometry.size.width, y: tapLocation.y/geometry.size.height)),
                         content: { info in
                            VStack {
                               Text("\(info.tag.name) at \(info.nodeEntry?.xpos ?? -1),\(info.nodeEntry?.ypos ?? -1)")
                               Text("Tap was (\(info.tapPostion.x),\(info.tapPostion.y)) adjusted to (\(info.adjustedTap.x), \(info.adjustedTap.y))")
                               Text(" and Search was (\(info.srchPosition.x), \(info.srchPosition.y))")
                               Text("There were \(info.matches) matches.  The screen factor was \(info.screenFactor)")
                               Text("Scale was \(info.scaleFactor) and offset was (width: \(info.offset.width), height: \(info.offset.height))")
                            }
                })
             }
             // .coordinateSpace(.named(canvasSpaceName))
             NavigationLink("Network details",
                            destination: GraphNetworkDetailView(network: $network,
                                                                islands: $islands,
                                                                regions: $regions,
                                                                nodes: $nodes,
                                                                edges: $edges))
          }
       }.onAppear(perform: {network.cacheResults()
          islands = network.islands()
          regions = network.regions()
          nodes = network.nodes()
          edges = network.edges()
          menuBridge.scale = $scale})
       .onDisappear(perform: {menuBridge.scale=nil})
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

struct TagInfo : Identifiable {
   let id: Int
   let tapPostion: CGPoint
   let adjustedTap: CGPoint
   let srchPosition: CGPoint
   let screenFactor: CGFloat
   let scaleFactor: CGFloat
   let offset: CGSize
   let tag: Tag
   let nodeEntry: NodeEntry?
   let matches: Int
}

func findTagInfo(network: TagNetwork, displaySize: CGSize, tapLocation: CGPoint,
                 scale: CGFloat, offset: CGSize) -> TagInfo? {
   let factor = calcFactor(network: network, displaySize: displaySize)
   let adjustedTap = CGPoint(x: (tapLocation.x / scale) - offset.width, y: (tapLocation.y / scale) - offset.height)
   let srchX = (adjustedTap.x / factor) - 0.5
   let srchY = (adjustedTap.y / factor) - 0.5
   // Search for the node entry.  Use sequential scan for now
   var nodeEntry : NodeEntry? = nil
   var matches : Int = 0
   for entry in network.nodes() {
      let bestMatch = nodeEntry ?? entry
      let diffX = srchX - Double(entry.xpos)
      let diffY = srchY - Double(entry.ypos)
      let testDist = sqrt(diffX*diffX + diffY*diffY)
      if testDist < 5.0 {
         matches += 1
         let bestX = Double(bestMatch.xpos)
         let bestY = Double(bestMatch.ypos)
         let bestDist = sqrt(((bestX-srchX)*(bestX-srchX) + (bestY-srchY)*(bestY-srchY)))
         if testDist <= bestDist {
            nodeEntry = entry
         }
      }
   }
   var tagInfo: TagInfo?
   let idNodeEntry = nodeEntry?.id ?? -1
   let info = network.tags[idNodeEntry] ?? Tag(id: -1)
   tagInfo = TagInfo(id: idNodeEntry, tapPostion: tapLocation,
                     adjustedTap: adjustedTap,
                     srchPosition: CGPoint(x: srchX, y: srchY),
                     screenFactor: factor,
                     scaleFactor: scale, offset: offset, tag: info,
                     nodeEntry: nodeEntry, matches: matches)
   return tagInfo
}

func calcFactor(network: TagNetwork, displaySize: CGSize) -> Double {
   let factorWidth = displaySize.width / Double(network.gridWidth)
   let factorHeight = displaySize.height / Double(network.gridHeight)
   let factor = Double.maximum(minFactor, Double.minimum(factorWidth, factorHeight))
   return factor
}

//Preview support
func makeTagNetwork4Preview() -> TagNetwork {
   let gen = GeneratedCollection(parameters: DataParameters())
   let graph = UndirectedGraph(nodes: gen.numTags, adjustment: -1)
   for item in gen.items {
      graph.add(list: item.tagIdList)
   }
   let network = TagNetwork(graph, tags: gen.tags, aspect: 3.0)
   return network
}
var network4Preview = makeTagNetwork4Preview()
var boundNetwork = Binding.constant(network4Preview)

#Preview {
   GraphNetworkView(network: boundNetwork)
}
