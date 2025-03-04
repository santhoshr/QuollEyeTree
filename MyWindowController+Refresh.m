//
//  MyWindowController+Refresh.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 2/10/11.
//  Copyright 2011-2015 Ian Binnie. All rights reserved.
//

#import "MyWindowController+Refresh.h"
#import "DirectoryItem.h"
#import "volume.h"
#import "TreeViewController.h"

@implementation MyWindowController(Refresh)

static NSOperationQueue *queue;
static dispatch_queue_t fsEventQueue;

+ (void)initialize {
    if (self == [MyWindowController class]) {
        queue = [NSOperationQueue new];
        [queue setMaxConcurrentOperationCount:1];  // Ensure sequential processing
        fsEventQueue = dispatch_queue_create("com.quolleyetree.fsevent", DISPATCH_QUEUE_SERIAL);
    }
}

/*! @brief	Called if there are loaded Directories requiring refresh
 @param	dirs an array of loaded Directories requiring refresh
 @param	wc MyWindowController
*/
//void refreshDirectories(NSArray *dirs, TreeViewController *tvc) {
//	NSLog(@"refreshDirectories");
//	if(queue == NULL) {
//		queue = [NSOperationQueue new];
//		[queue setMaxConcurrentOperationCount:10];
//	}
//	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
//		for(DirectoryItem *node in dirs) {
//			[node updateDirectory];
//		}
//	}];
//	[op setCompletionBlock:^{
//		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
//			if(tvc)	[tvc reloadData];
//		}];
//	}];
//	[queue addOperation:op];
//}
void refreshDirectories(NSArray *dirs, MyWindowController *wc) {
    if (!dirs || !wc || ![dirs count]) {
        NSLog(@"refreshDirectories: Invalid input parameters");
        return;
    }
    
    NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        @try {
            for(DirectoryItem *node in dirs) {
                if (![node isKindOfClass:[DirectoryItem class]]) {
                    NSLog(@"refreshDirectories: Invalid node type in array");
                    continue;
                }
                
                @try {
                    [node updateDirectory];
                } @catch (NSException *exception) {
                    NSLog(@"refreshDirectories: Exception updating directory %@: %@", 
                          [node relativePath], exception);
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"refreshDirectories: Exception in update loop: %@", exception);
        }
    }];
    
    [op setCompletionBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                if (![wc isKindOfClass:[MyWindowController class]]) {
                    NSLog(@"refreshDirectories: Invalid window controller in completion");
                    return;
                }
                
                TreeViewController *tvc = wc->currentTvc;
                if (!tvc) {
                    NSLog(@"refreshDirectories: No tree view controller available");
                    return;
                }
                
                [wc pauseMonitoring:YES];
                [tvc reloadData];
                [wc pauseMonitoring:NO];
            } @catch (NSException *exception) {
                NSLog(@"refreshDirectories: Exception in completion block: %@", exception);
            }
        });
    }];
    
    [queue addOperation:op];
}

//http://stackoverflow.com/questions/12507193/coreanimation-warning-deleted-thread-with-uncommitted-catransaction

// FSEventStreamCallback which will be called when FS events occur
void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]) {
    @autoreleasepool {
        if (!userData || !eventPaths) {
            NSLog(@"FSEvents callback received invalid data");
            return;
        }
        
        MyWindowController * __strong wc = (__bridge MyWindowController *)userData;
        if (!wc) {
            NSLog(@"FSEvents callback: window controller is nil");
            return;
        }
        
        NSArray *paths = (__bridge NSArray *)eventPaths;
        if (![paths isKindOfClass:[NSArray class]]) {
            NSLog(@"FSEvents callback: invalid paths array");
            return;
        }
        
        NSMutableArray *dirsToRefresh = [[NSMutableArray alloc] initWithCapacity:numEvents];
        
        dispatch_async(fsEventQueue, ^{
            @try {
                for(size_t i = 0; i < numEvents; i++) {
                    NSString *path = [paths objectAtIndex:i];
                    if (![path isKindOfClass:[NSString class]]) {
                        NSLog(@"FSEvents callback: invalid path at index %zu", i);
                        continue;
                    }
                    
                    path = [path stringByStandardizingPath];
                    if (!path.length) continue;
                    
                    DirectoryItem *node = findPathInVolumes(path);
                    if (!node) {
                        NSLog(@"FSEvents callback: could not find node for path: %@", path);
                        continue;
                    }
                    
                    if ([node isKindOfClass:[DirectoryItem class]] && [node isPathLoaded]) {
                        @synchronized(dirsToRefresh) {
                            [dirsToRefresh addObject:node];
                        }
                    }
                }
                
                if ([dirsToRefresh count] > 0) {
                    refreshDirectories(dirsToRefresh, wc);
                }
            } @catch (NSException *exception) {
                NSLog(@"FSEvents callback: Exception occurred: %@", exception);
            }
        });
    }
}

/*! @brief	This is a (private) method to initiate watch for modifications on a nominated directory
 @internal
 */
- (void)initializeEventStream {
    @try {
        if (stream) {
            [self stopMonitoring];
        }
        
        NSString *watchPath = [[[NSUserDefaults standardUserDefaults] stringForKey:PREF_REFRESH_DIR] stringByResolvingSymlinksInPath];
        if (!watchPath) {
            NSLog(@"initializeEventStream: No watch path specified");
            return;
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:watchPath]) {
            NSLog(@"initializeEventStream: Watch path does not exist: %@", watchPath);
            return;
        }
        
        NSArray *pathsToWatch = @[watchPath];
        void *appPointer = (__bridge_retained void *)self;  // Retain to prevent deallocation
        FSEventStreamContext context = {0, appPointer, NULL, NULL, NULL};
        NSTimeInterval latency = 3.0;
        
        stream = FSEventStreamCreate(NULL,
                                   &fsevents_callback,
                                   &context,
                                   (__bridge CFArrayRef)pathsToWatch,
                                   kFSEventStreamEventIdSinceNow,
                                   (CFAbsoluteTime)latency,
                                   kFSEventStreamCreateFlagUseCFTypes | 
                                   kFSEventStreamCreateFlagIgnoreSelf |
                                   kFSEventStreamCreateFlagFileEvents);
        
        if (!stream) {
            NSLog(@"initializeEventStream: Failed to create FSEvent stream");
            CFRelease(appPointer);  // Release if stream creation failed
            return;
        }
        
        FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
        if (!FSEventStreamStart(stream)) {
            NSLog(@"initializeEventStream: Failed to start FSEvent stream");
            FSEventStreamInvalidate(stream);
            FSEventStreamRelease(stream);
            stream = nil;
            CFRelease(appPointer);
            return;
        }
        
        NSLog(@"initializeEventStream: Successfully initialized FSEvent stream for path: %@", watchPath);
    } @catch (NSException *exception) {
        NSLog(@"initializeEventStream: Exception occurred: %@", exception);
        [self stopMonitoring];
    }
}

- (void)startMonitoring {
    if (stream != nil) {
        NSLog(@"MyWindowController: Stream already exists, stopping first");
        [self stopMonitoring];
    }
    
	if([[NSUserDefaults standardUserDefaults] boolForKey:PREF_AUTOMATIC_REFRESH]) {
        NSLog(@"MyWindowController: Initializing event stream");
		[self initializeEventStream];
    }
}

- (void)stopMonitoring {
    if (stream) {
        NSLog(@"stopMonitoring: Stopping and releasing event stream");
        FSEventStreamStop(stream);
        FSEventStreamInvalidate(stream);
        FSEventStreamRelease(stream);
        stream = nil;
        pauseCount = 0;
    }
}

- (void)pauseMonitoring:(BOOL)pause {
    if (!stream) {
        NSLog(@"pauseMonitoring: Cannot pause/resume - stream is nil");
        return;
    }
    
    @synchronized(self) {
        if (pause) {
            if (pauseCount++ == 0) {
                NSLog(@"pauseMonitoring: Pausing event stream");
                FSEventStreamStop(stream);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [refresh startAnimation:self];
                });
            }
            return;
        }
        
        if (pauseCount > 0) {
            if (--pauseCount == 0) {
                NSLog(@"pauseMonitoring: Resuming event stream");
                if (!FSEventStreamStart(stream)) {
                    NSLog(@"pauseMonitoring: Failed to restart stream");
                    [self stopMonitoring];
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [refresh stopAnimation:self];
                });
            }
        } else {
            NSLog(@"pauseMonitoring: Warning - unbalanced pause/resume calls");
            pauseCount = 0;
        }
    }
}

@end
