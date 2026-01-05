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
            ForEach(genData.tagStats) { stat in
               HStack {
                  //Text("\(stat)")
                  Text("id: \(stat.id)")
                  Spacer()
                  Text("target: \(stat.target)  occurs: \(stat.occurs)")
                  Spacer()
                  Text("by card count: [\(stat.byCard.formatted(.list(memberStyle: IntegerFormatStyle(), type: .and, width: .narrow)))]").frame(alignment: .leading)
               }
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

struct ItemListView: View {
   @Binding var genData: GeneratedCollection
   @Environment(\.dismiss) private var dismiss
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
                  Text("tags: \(item.tagIdList.sorted().formatted(.list(memberStyle: IntegerFormatStyle(), type: .and, width: .narrow)))").frame(alignment: .leading)
               }
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
