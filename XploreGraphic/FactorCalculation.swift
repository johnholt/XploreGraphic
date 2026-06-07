//
//  FactorCalculation.swift
//  XploreGraphic
//
//  Created by John Holt on 2/22/26.
//

import Foundation

internal let minFactor: Double = 10.0

func calcFactor(gridWidth: Int, gridHeight: Int, displaySize: CGSize) -> Double {
   return calcFactor(gridWidth: Double(gridWidth), gridHeight: Double(gridHeight),
                     displayWidth: displaySize.width, displayHeight: displaySize.height)
}

func calcFactor(gridSize: CGSize, displaySize: CGSize) -> Double {
   return calcFactor(gridWidth: gridSize.width, gridHeight: gridSize.height,
                     displayWidth: displaySize.width, displayHeight: displaySize.height)
}

func calcFactor(gridWidth: Double, gridHeight: Double, displayWidth: Double, displayHeight: Double) -> Double {
   let factorWidth = displayWidth / gridWidth
   let factorHeight = displayHeight / gridHeight
   let factor = Double.maximum(minFactor, Double.minimum(factorWidth, factorHeight))
   return factor
}
