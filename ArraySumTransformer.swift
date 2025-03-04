//
//  ArraySumTransformer.swift
//  QuollEyeTree
//
//  Created by Swift conversion
//

import Foundation

class ArraySumTransformer: NSValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        var sum: UInt = 0
        if let array = value as? [NSNumber] {
            for number in array {
                sum += UInt(number.intValue)
            }
        }
        return NSNumber(value: sum)
    }
}