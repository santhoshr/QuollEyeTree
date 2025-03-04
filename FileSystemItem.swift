/*
 File: FileSystemItem.swift
 
 Abstract: Base class containing common properties/methods to support Files and Directories.
 
 Created by Swift conversion
 */

import Cocoa

/**
 The FileSystemItem class
 
 This is a base class containing common properties/methods to support Files and Directories.
 This class should only be used when no distinction is needed between Files and Directories.
 */
class FileSystemItem: NSObject {
    // MARK: - Properties
    @objc var relativePath: String?
    @objc var nodeIcon: NSImage?
    @objc private(set) var kind: String?
    @objc var cDate: Date?
    @objc var wDate: Date?
    
    // Protected properties in Swift are private with internal setter
    @objc private(set) var alias: Bool = false
    @objc private(set) var package: Bool = false
    
    // Using weak to avoid retain cycles
    private weak var parentItem: FileSystemItem?
    
    // MARK: - Initialization
    init(path url: URL, parent parentItem: FileSystemItem?) {
        super.init()
        
        self.relativePath = url.lastPathComponent
        self.parentItem = parentItem
        
        // Get file attributes
        var resourceValue: AnyObject?
        
        // Creation date
        do {
            var tempDate: Date?
            try (url as NSURL).getResourceValue(&tempDate, forKey: .creationDateKey)
            if let date = tempDate, date.timeIntervalSince1970 >= 24*3600 {
                self.cDate = date
            }
        } catch {}
        
        // Modification date
        do {
            var tempDate: Date?
            try (url as NSURL).getResourceValue(&tempDate, forKey: .contentModificationDateKey)
            self.wDate = tempDate
        } catch {}
        
        // Kind description
        do {
            var tempKind: String?
            try (url as NSURL).getResourceValue(&tempKind, forKey: .localizedTypeDescriptionKey)
            self.kind = tempKind
        } catch {}
        
        // Alias
        do {
            var tempValue: Bool = false
            try (url as NSURL).getResourceValue(&tempValue, forKey: .isAliasFileKey)
            self.alias = tempValue
        } catch {}
        
        // Package
        do {
            var tempValue: Bool = false
            try (url as NSURL).getResourceValue(&tempValue, forKey: .isPackageKey)
            self.package = tempValue
        } catch {}
    }
    
    // MARK: - Parent-Child Relationship
    @objc func parent() -> FileSystemItem? {
        return parentItem ?? self  // If no parent, return self
    }
    
    @objc func setParent(_ newParent: FileSystemItem?) {
        parentItem = newParent
    }
    
    // MARK: - Path Handling
    @objc func fullPath() -> String {
        guard let relativePath = relativePath else {
            return ""
        }
        
        if parentItem == nil {
            return relativePath  // If no parent, return our own relative path
        }
        
        // Recurse up the hierarchy, prepending each parent's path
        return (parentItem!.fullPath() as NSString).appendingPathComponent(relativePath)
    }
    
    @objc func url() -> URL {
        return URL(fileURLWithPath: self.fullPath())
    }
    
    // MARK: - Boolean Property Getters
    @objc func isAlias() -> Bool {
        return alias
    }
    
    @objc func isPackage() -> Bool {
        return package
    }
}