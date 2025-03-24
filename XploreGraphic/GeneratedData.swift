//
//  GeneratedData.swift
//  XploreGraphic
//
//  Created by John Holt on 8/10/24.
//
// Generated test data for graph construction.  The data model
// is a set of items and a set of tags with 0 or more tags
// assigned to each data item.  Outputs are: a matrix of items
// versus tags assign to the item; a tag to tag adjancy matrix
// capturing which tags co-occur on the items; and descriptive
// statistical tables.
// Inputs are: the number of items; the number of tags; a frequency
// table indexed by the cardinality of the tag set assigned to an
// item, holding the percentage of items with index position tags
// assigned; and the average and maximum percent of items with any
// one tag assigned.
//

import Foundation

@Observable()
class GeneratedCollection {
   // Input
   let saved: DataParameters
   // Generation parameters after review and correction
   let numItems : Int
   let numTags : Int
   let numUnusedTags: Int
   let numItemsByTagsetCard : [Int]
   let avgFreq: Float
   let maxFreq: Float
   // results
   let tags: [Tag]
   let items: [Item]
   let tagStats: [TagOccurs]
   // Dummy initializer
   init() {
      numItems = 0
      numTags = 0
      numUnusedTags = 0
      numItemsByTagsetCard = [0]
      avgFreq = 0.0
      maxFreq = 0.0
      saved = DataParameters(numItems: 0, numTags: 0, forceUnusedTags: false,
                             pctItemTable: [1.0], avgTagFreq: 0.0, maxTagFreq: 0.0)
      tags = []
      items = []
      tagStats = []
   }
   // Initializer
   init(parameters inp: DataParameters = DataParameters()) {
      self.saved = inp
      // set parameters, adjust and transform as necessary
      self.numUnusedTags = inp.forceUnusedTags ? 2 : 0
      self.numItems = inp.numItems < 2 ? 3 : inp.numItems
      self.avgFreq = (inp.avgTagFreq>0.0 && inp.avgTagFreq<1.0) ? inp.avgTagFreq : 0.05
      self.maxFreq = (inp.maxTagFreq>0.0 && inp.maxTagFreq<1.0
                      && inp.maxTagFreq >= self.avgFreq)  ? inp.maxTagFreq : self.avgFreq
      var w: [Int] = Array<Int>(repeating: 0, count: inp.pctItemTable.count)
      var wadj : Float = 0.0
      for pct in inp.pctItemTable {
         wadj += pct
      }
      wadj = 1.0 / wadj
      var wsum = 0
      let numCardEntries = inp.pctItemTable.count     // includes a zero entry
      let numCardinalities = numCardEntries - 1       // non-zero entries only
      if inp.pctItemTable[0] == 0.0 {
         w[0] = 0
      } else {
         w[0] = (1.0 > inp.pctItemTable[0]*Float(self.numItems))
         ? 1 : Int((wadj*inp.pctItemTable[0]*Float(self.numItems)).rounded())
         wsum += w[0]
      }
      for ndx in 1..<inp.pctItemTable.count {
         let t = Int((wadj*inp.pctItemTable[ndx]*Float(self.numItems)).rounded())
         w[ndx] = (t+wsum > self.numItems) ? self.numItems - wsum : t
         wsum += w[ndx]
      }
      if wsum < self.numItems {        // Q. Cardinalities assigned to every item
         w[0] += self.numItems - wsum  // A. No, assign missing to zero tag items
      }
      self.numItemsByTagsetCard = w
      var numWanted = 0
      for ndx in 1 ..< self.numItemsByTagsetCard.count  {
         numWanted += ndx * self.numItemsByTagsetCard[ndx]
      }
      let minRequiredTags = self.numUnusedTags
            + Int(((Float(numWanted) * self.avgFreq)).rounded(.awayFromZero))
      self.numTags = max(inp.numTags, minRequiredTags)

      // determine number of tags by occurrence group: min, average, max
      let minFreq : Float = self.avgFreq / 2.0
      let min2maxMult = Int((self.maxFreq/minFreq).rounded())
      let numMax = (Int((self.numTags-self.numUnusedTags)/2)/(min2maxMult+1))
      let numMin = numMax //min2maxMult*numMax
      let numAvg = self.numTags-self.numUnusedTags-numMax-numMin
      
      // create result tables in work areas, starting with the TagOccurs
      // Table has highest to lowest frequency tags
      var wTagOccurs : [TagOccurs] = []
      var target : Int
      for nominal in 1...self.numTags {
         if nominal <= numMax {
            target = Int(maxFreq*Float(self.numItems))
         } else if nominal <= numMax + numAvg {
            target = Int(avgFreq*Float(self.numItems))
         } else if nominal <= numMax + numAvg + numMin {
            target = Int(minFreq*Float(self.numItems))
         } else {
            target = 0
         }
         let occurs = TagOccurs(id:nominal, numCards: numCardinalities, target: target)
         wTagOccurs.append(occurs)
      }
      // The Tag table, holds only tag descriptions
      var wTags: [Tag] = []
      for nominal in 1...self.numTags {
         wTags.append(Tag(id: nominal))
      }
      // The items.  Create items with highest tag set cardinality to lowest.
      var wItems: [Item] = []
      var ndxTag = 0    // index into TagOccurs table
      // find the first tag with unused occurences
      while wTagOccurs[ndxTag].target == wTagOccurs[ndxTag].occurs { //Q. Any left to assign
         ndxTag += 1                                                 //A. no, check next
         if ndxTag == numTags - 1 {             // Q. Is this the last tag
            break                               // A. Yes.
         }
      }     // ndxTag points to first usable tag or last tag
      var ndxCard = numCardEntries  // index is past numItemsByTagsetCard
      var currCard = numCardinalities + 1 // start one higher
      var itemsBuilt = 0
      var items2build = 0           // trigger search for cardinality of new items
      var nominal =  0
      while itemsBuilt < self.numItems {
         while items2build == 0     //Q. All items built for this cardinality
                  && ndxCard > 0  { // and we have more entries
            ndxCard -= 1            //A, Yes, set to next level
            items2build = numItemsByTagsetCard[ndxCard]
            currCard -= 1
         }                          // May have items2build, may be zero
         nominal += 1
         var wItem = Item(id: nominal)
         var ndxTagThumb = ndxTag      // keep current position for wrap around
         if currCard > 0               //Q. Tag needed and has available occurrences
               && wTagOccurs[ndxTag].target > wTagOccurs[ndxTag].occurs {
            for _ in 1...currCard {    // ndxTag points to an available tag
               wTagOccurs[ndxTag].occurs += 1
               wTagOccurs[ndxTag].byCard[currCard-1] += 1
               wItem.tagIdList.insert(wTagOccurs[ndxTag].id)
               // Need to find the next available tag or break out
               var need2advance = true
               while need2advance {
                  if ndxTag == self.numTags - 1 {  //Q. Wrap to start of table
                     ndxTag = 0                    //A. Yes, set to start
                  } else {
                     ndxTag += 1                   //A. No, increment
                  }
                  if ndxTag == ndxTagThumb {       //Q. Have we wrapped to our starting point
                     break                         //A. Yes, nothing available for this item
                  }
                  need2advance = wTagOccurs[ndxTag].target == wTagOccurs[ndxTag].occurs
               }
               if need2advance {    //Q. Did we break out without finding available tag
                  break             //A. Yes, this item will be short
               }
            }
         }
         // tags were assigned if available
         itemsBuilt += 1
         items2build -= 1
         wItems.append(wItem)
         // make ndxTag point to an available tag if any are available
         ndxTagThumb = ndxTag    // keep position for wrap check
         while wTagOccurs[ndxTag].target == wTagOccurs[ndxTag].occurs {
            if ndxTag == self.numTags - 1 {     //Q. Need to wrap to start
               ndxTag = 0                       //A. Yes
            } else {                            //A. No, increment
               ndxTag += 1
            }
            if ndxTag == ndxTagThumb {          //Q. Have we wrapped to starting point
               break                            //A. Yes, none are available
            }
         }
      }
      // copy built results to constants
      tags = wTags
      items = wItems
      tagStats = wTagOccurs
   }
}

// result structure definitions
struct Tag : Identifiable{
   let id: Int
   let name: String
   init(id: Int) {
      self.id = id
      self.name = "Tag \(id)"
   }
}
struct Item : Identifiable{
   let id: Int
   let name: String
   var tagIdList = Set<Int>()
   init(id: Int) {
      self.id = id
      self.name = "Item \(id)"
   }
}
struct TagOccurs : Identifiable{
   let id: Int
   var occurs: Int
   var target: Int
   var byCard: [Int]
   init(id: Int, numCards: Int, target: Int) {
      self.id = id
      self.occurs = 0
      self.target = target
      self.byCard = Array(repeating: 0, count: numCards)
   }
}

// Input structure with defaults
struct DataParameters {
   var numItems: Int = 100
   var numTags: Int = 10
   var forceUnusedTags: Bool = false
   var pctItemTable: [Float] = [0.0, 0.2, 0.4, 0.2, 0.1, 0.1]
   var avgTagFreq: Float = 0.1
   var maxTagFreq: Float = 0.2
}
