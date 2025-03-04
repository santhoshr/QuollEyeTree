//
//  RenamePanelController.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 14/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "RenamePanelController.h"

@implementation RenamePanelController

- (id)init {
	if (self = [super initWithWindowNibName: @"RenamePanel"]) { 
		[self window];
	}
	return self; 
}
- (IBAction)cancelRename:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSModalResponseCancel];
}
- (IBAction)performRename:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSModalResponseOK];
}
- (NSInteger)runModal {
	NSInteger result = [NSApp runModalForWindow:self.window];
	return result;
}
- (void)setTitle:(NSString *)title {
	[self.window setTitle:title];
}
- (NSString *)filename {
	return [name stringValue];	
}
- (void)setFilename:(NSString *)filename {
	[name setStringValue:filename];
}
- (void)setFrom:(NSString *)filename {
	[source setStringValue:filename];
}

@end
