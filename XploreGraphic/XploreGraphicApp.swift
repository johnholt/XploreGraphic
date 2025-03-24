//
//  XploreGraphicApp.swift
//  XploreGraphic
//
//  Created by John Holt on 8/9/24.
//

import SwiftUI

@main
struct XploreGraphicApp: App {
   @State var genParms = DataParameters()
   
   var body: some Scene {
      WindowGroup {
         ContentView(genParms: $genParms)
      }
   }
}

