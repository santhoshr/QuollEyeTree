/*
 File: FileItem.swift
 
 Abstract: The FileItem class containing common properties/methods to support Files.
 
 Created by Swift conversion
 */

import Cocoa

/**
 The FileItem class
 
 This class contains common properties/methods to support Files.
 */
class FileItem: FileSystemItem {
    // MARK: - Properties
    @objc var fileSize: NSNumber?
    @objc var tag: Bool = false
    
    // MARK: - URL Handling
    override func url() -> URL {
        return URL(fileURLWithPath: self.fullPath(), isDirectory: false)
    }
}