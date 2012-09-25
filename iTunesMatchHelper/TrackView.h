//
//  TrackView.h
//  iTunesMatchHelper
//
//  Created by Nathan Villaescusa on 9/9/12.
//
//

#import <Cocoa/Cocoa.h>

@class RowData;

@interface TrackView : NSView <NSTableViewDelegate,NSTableViewDataSource>

@property (nonatomic, strong) RowData *rowData;
@property (nonatomic, strong) NSTableView *tableView;
@end
