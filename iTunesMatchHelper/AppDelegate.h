//
//  AppDelegate.h
//  iTunesMatchHelper
//
//  Created by Kevin Vinck on 17-12-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iTunes.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,NSTableViewDelegate,NSTableViewDataSource> {
    
    NSMutableArray *songData;
    
    bool updatingLibrary;
    bool canCancel;
    bool doCancel;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSTextField *progressLabel;
@property (weak) IBOutlet NSTableView *songTable;
@property (weak) IBOutlet NSButton *scanButton;


- (IBAction)fetchLibrary:(id)sender;
- (IBAction)checkAllItems:(id)sender;
- (IBAction)uncheckAllItems:(id)sender;

@end
