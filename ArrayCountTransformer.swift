//
//  ArrayCountTransformer.swift
//  QuollEyeTree
//
//  Created by Swift conversion
//

import Foundation

class ArrayCountTransformer: NSValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        var count: Int = 0
        if let array = value as? [Any] {
            count = array.count
        }
        return NSNumber(value: count)
    }
}