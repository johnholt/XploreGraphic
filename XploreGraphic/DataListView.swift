//
//  DataListView.swift
//  XploreGraphic
//
//  Created by John Holt on 4/25/25.
//

import SwiftUI

struct TagListView: View {
   @Binding var genData: GeneratedCollection
   @Environment(\.dismiss) private var dismiss
   var body: some View {
      ScrollView {
         VStack {
            Button ("Back") {    // work around for macOS bug
               dismiss()
            }
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
   @Environment(\.dismiss) private var dismiss
   var body: some View {
      ScrollView {
         VStack {
            Button("Back") {     // work around for macOS bug
               dismiss()
            }
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
