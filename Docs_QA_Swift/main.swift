//
//  main.swift
//  Docs_QA_Swift
//
//  Created by Mark Watson on 4/7/23.
//

import Foundation

func dotProduct(_ list1: [Float], _ list2: [Float]) -> Float {
    guard list1.count == list2.count else {
        fatalError("Lists must have the same length.")
    }
    
    var result: Float = 0
    
    for i in 0..<list1.count {
        result += list1[i] * list2[i]
    }
    
    return result
}

func readList(_ input: String) -> [Float] {
    return input.split(separator: " ").compactMap { Float($0) }
}

let input1 = "1.0 2.0 3.0"
let input2 = "4.0 5.0 6.0"

let list1 = readList(input1)
let list2 = readList(input2)

let dotProductResult = dotProduct(list1, list2)

print(dotProductResult)


