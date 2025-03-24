//
//  ContentView.swift
//  XploreGraphic
//
//  Created by John Holt on 8/9/24.
//

import SwiftUI
import Charts


struct ContentView: View {
   @Binding var genParms: DataParameters
   @State private var genData = GeneratedCollection()
   @State private var matching = true     // Parm data matches displayed
   // Extracted data for editing
   @State private var forceUnusedTags : Bool = false
   @State private var maxCard : Int = 0
   @State private var numTagsRqst : Int = 0
   @State private var numItemsRqst : Int = 0
   @State private var avgTagFreq : Float = 0.0
   @State private var maxTagFreq : Float = 0.0
   @State private var cardPctTab : [CardinalityProportion] = []
   // Extracted data for display
   @State private var cardCntTab : [CardinalityCount] = []
   
   var body: some View {
      NavigationStack {
         VStack {
            HStack {
               Text("Requested \(genParms.numItems) items, and \(genParms.numTags) tags.")
               Text("Built \(genData.numItems) items and \(genData.numTags) tags.")
            }
            HStack {
               Text("Maximum and average frequency was \(genData.maxFreq) and \(genData.avgFreq) respectively")
            }
            Spacer()
            HStack {
               Text("Editable parameter values for generating a collection of tagged items")
               Button("Accept", systemImage: "checkmark.circle", action: applyChanges)
                  .disabled(matching).labelStyle(.iconOnly)
               Button("Undo", systemImage: "arrow.uturn.backward.circle", action: populateState)
                  .disabled(matching).labelStyle(.iconOnly)
            }
            HStack {
               Toggle(isOn: $forceUnusedTags) {
                  Text("Force two of the tags to be unused")
               }.onChange(of: forceUnusedTags) {markIfChanged(genParms.forceUnusedTags,
                                                              forceUnusedTags)}
               Spacer()
               Text("Maximum cardinality: ")
               TextField(
                  value: $maxCard,
                  format: .number,
                  label: {Text("cardinality")}
               ).frame(width: 25)
                  .onChange(of: maxCard, initial: false, changeCard)
               Spacer()
               Text("average freq: ")
               TextField(value: $avgTagFreq, format: .percent,
                         label: {Text("percent")}
               ).onChange(of: avgTagFreq) {markIfChanged(genParms.avgTagFreq,
                                                         avgTagFreq)}
               Spacer()
               Text("max freq: ")
               TextField(value: $maxTagFreq, format: .percent,
                         label: {Text("percent")}
               ).onChange(of: maxTagFreq) {markIfChanged(genParms.maxTagFreq, maxTagFreq)}
            }
            Spacer()
            HStack {
               ScrollView {
                  VStack {
                     Text("% items by cardinality")
                     ForEach($cardPctTab, id: \.cardinality) {$pct in
                        HStack {
                           Text("\(pct.cardinality): ")
                           TextField(value: $pct.proportion,
                                     format: .percent.precision(.significantDigits(4)),
                                     label: {Text("percent")})
                           .onChange(of: pct.proportion) {checkPctTab(tab: genParms.pctItemTable,
                                                                      card: pct.cardinality,
                                                                      pct: pct.proportion)}
                        }
                     }
                  }
               }
            }
            Spacer()
            HStack {
               ScrollView {
                  VStack {
                     Text("Number of items by tag-set cardinality")
                     Chart(cardCntTab, id: \.cardinality) {entry in
                        BarMark(x: .value("Cardinality", entry.cardinality),
                                y: .value("Items", entry.numItems),
                                width: 4)
                     }
                  }
               }
            }
            HStack {
               NavigationLink("List of tags") {
                  TagListView(genData: $genData)
               }
               NavigationLink("List of items") {
                  ItemListView(genData: $genData)
               }
            }
         }
         .padding(5)
         .onAppear(perform: populateState)
      }
   }
   
   func populateState() -> Void {
      maxCard = genParms.pctItemTable.count - 1
      forceUnusedTags = genParms.forceUnusedTags
      cardPctTab = cvt2ProportionArray(pctTab: genParms.pctItemTable)
      numItemsRqst = genParms.numItems
      avgTagFreq = genParms.avgTagFreq
      maxTagFreq = genParms.maxTagFreq
      numTagsRqst = genParms.numTags
      genData = GeneratedCollection(parameters: genParms)
      cardCntTab = cvt2CardCntArray(itemsByCard: genData.numItemsByTagsetCard)
      matching = true
   }
   func applyChanges() -> Void {
      genParms.forceUnusedTags = forceUnusedTags
      genParms.pctItemTable = cvt2PercentArray(proportionTab: cardPctTab)
      genParms.numTags = numTagsRqst
      genParms.numItems = numItemsRqst
      genParms.avgTagFreq = avgTagFreq
      genParms.maxTagFreq = maxTagFreq
      genData = GeneratedCollection(parameters: genParms)
      cardCntTab = cvt2CardCntArray(itemsByCard: genData.numItemsByTagsetCard)
      matching = true
   }
   func checkPctTab(tab: [Float], card: Int, pct: Float) -> Void {
      guard card >= 0 && card < tab.count else { return }
      if tab[card] != pct {
         matching = false
      }
   }
   func markIfChanged<T: Equatable>(_ a: T, _ b: T) -> Void {
      guard a != b else { return }
      matching = false
   }
   func changeCard() -> Void {
      let currCount = cardPctTab.count
      let delta = abs(maxCard + 1 - currCount)
      if currCount > maxCard + 1 {
         cardPctTab.removeLast(delta)
         matching = false
      } else if currCount < maxCard + 1 {
         for c in currCount...maxCard {
            cardPctTab.append(CardinalityProportion(cardinality: c, proportion: 0.0))
         }
         matching = false
      }
   }
}

var parms = DataParameters()
var previewParms = Binding(
   get: {return parms},
   set: { value in parms = value}  )

#Preview {
   ContentView(genParms: previewParms)
}

struct TagListView: View {
   @Binding var genData: GeneratedCollection
   var body: some View {
      ScrollView {
         VStack {
            ForEach(genData.tagStats) { stat in
               HStack {
                  //Text("\(stat)")
                  Text("id: \(stat.id)")
                  Spacer()
                  Text("target: \(stat.target)  occurs: \(stat.occurs)")
                  Spacer()
                  Text("by card count: \(stat.byCard)").frame(alignment: .leading)
               }
            }
         }
      }
   }
}

struct ItemListView: View {
   @Binding var genData: GeneratedCollection
   var body: some View {
      ScrollView {
         VStack {
            ForEach(genData.items) {item in
               HStack {
                  //Text("\(item)")
                  Text("id: \(item.id)")
                  Spacer()
                  Text("cardiality: \(item.tagIdList.count)")
                  Spacer()
                  Text("tags: \(item.tagIdList.sorted())").frame(alignment: .leading)
               }
            }
         }
      }
   }
}

// Display and entry oriented structures for array based data elements
struct CardinalityProportion {
   var cardinality : Int
   var proportion : Float
}
func cvt2ProportionArray(pctTab: [Float]) -> [CardinalityProportion] {
   var rslt : [CardinalityProportion] = []
   for (card, pct) in pctTab.enumerated() {
      let entry = CardinalityProportion(cardinality: card, proportion: pct)
      rslt.append(entry)
   }
   return rslt
}
func cvt2PercentArray(proportionTab: [CardinalityProportion]) -> [Float] {
   var rslt: [Float] = Array(repeating: 0.0, count: proportionTab.count)
   for entry in proportionTab {
      rslt[entry.cardinality] = entry.proportion
   }
   return rslt
}

struct CardinalityCount {
   var cardinality : Int
   var numItems : Int
}
func cvt2CardCntArray(itemsByCard: [Int]) -> [CardinalityCount] {
   var rslt : [CardinalityCount] = []
   for (card, numItems) in itemsByCard.enumerated() {
      let entry = CardinalityCount(cardinality: card, numItems: numItems)
      rslt.append(entry)
   }
   return rslt
}
func cvt2ItemsByCard(cardCount: [CardinalityCount]) -> [Int] {
   var rslt: [Int] = Array(repeating: 0, count: cardCount.count)
   for entry in cardCount {
      rslt[entry.cardinality] = entry.numItems
   }
   return rslt
}
