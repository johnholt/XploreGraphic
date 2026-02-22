//
//  FactorCalculation.swift
//  XploreGraphic
//
//  Created by John Holt on 2/22/26.
//

import Foundation

internal let minFactor: Double = 10.0

func calcFactor(gridWidth: Int, gridHeight: Int, displaySize: CGSize) -> Double {
   let factorWidth = displaySize.width / Double(gridWidth)
   let factorHeight = displaySize.height / Double(gridHeight)
   let factor = Double.maximum(minFactor, Double.minimum(factorWidth, factorHeight))
   return factor
}
