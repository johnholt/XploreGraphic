//
//  XploreGraphicApp.swift
//  XploreGraphic
//
//  Created by John Holt on 8/9/24.
//

import SwiftUI

@main
struct XploreGraphicApp: App {
   @State private var genParms = DataParameters()
   @State private var menuBridge = MenuBridge()
   
   var body: some Scene {
      WindowGroup()  { 
         ContentView(genParms: $genParms)
            .environment(\.menuBridge, menuBridge)
      }
      .commands {
         CommandMenu("Graph") {
            Button("Magnify", systemImage: "plus.magnifyingglass") {menuBridge.zoomIn()}
               .keyboardShortcut("+")
               .disabled(menuBridge.zoomDisabled())
            Button("Reduce", systemImage: "minus.magnifyingglass") {menuBridge.zoomOut()}
               .keyboardShortcut("-")
               .disabled(menuBridge.zoomDisabled())
            Button("Reset", systemImage: "minus.magnifyingglass") {menuBridge.reset()}
               .keyboardShortcut(".")
               .disabled(menuBridge.zoomDisabled())
         }
      }
   }
}

@Observable
class MenuBridge {
   var scale : Binding<CGFloat>?
   var offset : Binding<CGSize>?
   
   func zoomDisabled() -> Bool {
      if scale == nil {
         return true
      } else {
         return false
      }
   }
   
   func zoomOutDisabled() -> Bool {
      if scale == nil || scale?.wrappedValue ?? 0.0 <= 0.25 { //Q. nil or scale to small to reduce
         return true                                          //A. Yes, disable button
      } else {
         return false
      }
   }
   
   func zoomIn() {
      guard scale != nil else {
         return
      }
      scale!.wrappedValue = scale!.wrappedValue + 0.25
   }
   
   func zoomOut() {
      guard scale?.wrappedValue ?? 0.0 > 0.25 else {   // Q. Scale not nil and greater than amount to decrease
         return                                        //A. No, decreasing magnification not available
      }
      scale!.wrappedValue = scale!.wrappedValue - 0.25
   }
   
   func reset() {
      if scale != nil {
         scale!.wrappedValue = 1.0
      }
      if offset != nil {
         offset!.wrappedValue = CGSize.zero
      }
   }
}

extension EnvironmentValues {
   @Entry var menuBridge: MenuBridge = MenuBridge()
}
