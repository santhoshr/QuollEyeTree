//
//  TreeViewController+Files.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 1/10/11.
//  Copyright 2011-2013 Ian Binnie. All rights reserved.
//

#import "TreeViewController+Files.h"
#import "MyWindowController.h"
#import "DirectoryItem.h"
#import "FileItem.h"
#import "volume.h"
#import "alias.h"
#import "ImageAndTextCell.h"
#import "OpenWith.h"
#import "DeletedItems.h"
#import "SearchPanelController.h"
#import "TextViewerController.h"
#import "CompareFileController.h"
#import "CompareFilterController.h"

extern NSPredicate *tagPredicate;
extern NSPredicate *notEmptyPredicate;

@interface TreeViewController()
- (void)setFileMenu;
- (void)enterFileView;
- (void)enterDirView;
- (BOOL)restoreSplitView;
- (void)copyToPasteboard: (id)object;
- (void)toggleTopSubView:(id)sender;
- (void)setPanel;
- (FileItem *)selectedFile;
- (void)postStatusMessage:(NSString *)message;
- (NSArray *)taggedFiles;
@end
@interface TreeViewController(Copy)
- (void)initPanelDest:(id)panel;
- (void)runBlockOnQueue:(void (^)(void))block;
- (void)copyTo:(FileSystemItem *)node;
- (void)moveTo:(FileSystemItem *)node;
- (void)renameTo:(FileSystemItem *)node;
- (void)copyTaggedTo:(NSArray *)objectsToCopy;
- (void)moveTaggedTo:(NSArray *)objectsToCopy;
- (void)renameTaggedTo:(NSArray *)objects;
- (void)batchForTagged:(NSArray *)objectsToCopy;
- (void)symlinkTo:(FileSystemItem *)node;
@end

@implementation TreeViewController(Files)

- (IBAction)openFile:(id)sender {
    FileItem *node = [self selectedFile];
    if (node == nil) return;
    [[NSWorkspace sharedWorkspace] openURL:node.url];
}

- (void)editFile {
    FileItem *node = [self selectedFile];
    if (node == nil) return;
    
    // Modern way to open files with specific app
    NSURL *fileURL = [NSURL fileURLWithPath:node.fullPath];
    NSURL *appURL = [NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] stringForKey:PREF_EDIT_COMMAND]];
    
    NSWorkspaceOpenConfiguration *config = [[NSWorkspaceOpenConfiguration alloc] init];
    [[NSWorkspace sharedWorkspace] openURLs:@[fileURL] 
                        withApplicationAtURL:appURL 
                               configuration:config
                           completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
        if (error) {
            [self postStatusMessage:@"unable to open file"];
        }
    }];
}

- (void)editTaggedFiles {
    NSURL *appURL = [NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] stringForKey:PREF_EDIT_COMMAND]];
    NSWorkspaceOpenConfiguration *config = [[NSWorkspaceOpenConfiguration alloc] init];
    
    for (FileItem *node in self.taggedFiles) {
        NSURL *fileURL = [NSURL fileURLWithPath:node.fullPath];
        [[NSWorkspace sharedWorkspace] openURLs:@[fileURL]
                            withApplicationAtURL:appURL
                                 configuration:config
                             completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
            if (error) {
                [self postStatusMessage:@"unable to open file"];
            }
        }];
    }
}

- (NSString *)tableView:(NSTableView *)tableView typeSelectStringForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
        NSTableCellView *cellView = [tableView viewAtColumn:1 row:row makeIfNecessary:NO];
        return cellView.textField.stringValue;
    }
    return nil;
}

@end
