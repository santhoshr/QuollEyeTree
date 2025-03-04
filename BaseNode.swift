/*
     File: BaseNode.swift
 Abstract: Generic multi-use node object used with NSOutlineView and NSTreeController.
  
  Version: 1.1 
*/

import Cocoa

class BaseNode: NSObject, NSCoding, NSCopying {
    // MARK: - Properties
    @objc dynamic var nodeTitle: String?
    @objc dynamic var children: NSMutableArray?
    @objc dynamic var nodeIcon: NSImage?
    
    private var isLeafNode: Bool = false
    private var nodePath: String?
    
    // MARK: - Static Properties
    private static var leafNode: [Any] = []
    
    // MARK: - Initialization
    override class func initialize() {
        leafNode = []
    }
    
    override init() {
        super.init()
        self.nodeTitle = "BaseNode Untitled"
        self.children = NSMutableArray()
        self.setLeaf(false) // container by default
    }
    
    convenience init(leaf: Bool) {
        self.init()
        self.setLeaf(leaf)
    }
    
    // MARK: - Leaf Handling
    @objc func setLeaf(_ flag: Bool) {
        isLeafNode = flag
        if isLeafNode {
            self.children = NSMutableArray(array: [BaseNode.leafNode])
        } else {
            self.children = NSMutableArray()
        }
    }
    
    @objc func isLeaf() -> Bool {
        return isLeafNode
    }
    
    // MARK: - Path Handling
    @objc func setPath(_ urlStr: String) {
        if nodePath == nil || nodePath != urlStr {
            nodePath = urlStr
        }
    }
    
    @objc func path() -> String? {
        return nodePath
    }
    
    // MARK: - Archiving And Copying Support
    // Override this method to maintain support for archiving and copying
    @objc func mutableKeys() -> [String] {
        return [
            "nodeTitle",
            "isLeaf",     // isLeaf MUST come before children for initWithDictionary: to work
            "children",
            "nodeIcon",
            "nodePath"
        ]
    }
    
    // MARK: - NSCoding
    required init?(coder: NSCoder) {
        super.init()
        
        for key in self.mutableKeys() {
            if let value = coder.decodeObject(forKey: key) {
                self.setValue(value, forKey: key)
            }
        }
    }
    
    func encode(with coder: NSCoder) {
        for key in self.mutableKeys() {
            if let value = self.value(forKey: key) {
                coder.encode(value, forKey: key)
            }
        }
    }
    
    // MARK: - NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let newNode = type(of: self).init()
        
        for key in self.mutableKeys() {
            if let value = self.value(forKey: key) {
                newNode.setValue(value, forKey: key)
            }
        }
        
        return newNode
    }
    
    // MARK: - KVO
    override func setNilValueForKey(_ key: String) {
        if key == "isLeaf" {
            isLeafNode = false
        } else {
            super.setNilValueForKey(key)
        }
    }
}