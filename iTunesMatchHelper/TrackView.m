//
//  TrackView.m
//  iTunesMatchHelper
//
//  Created by Nathan Villaescusa on 9/9/12.
//
//

#import "TrackView.h"
#import "RowData.h"

@implementation TrackView 

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
}

- (void)setRowData:(RowData *)rowData {
    _rowData = rowData;

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self.tableView reloadData];
    });
    
}

- (void)setTableView:(NSTableView *)tableView {
    _tableView = tableView;
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [_tableView reloadData];
}

- (NSString *)formatIndex:(NSInteger)index count:(NSInteger)count {
    if (index == 0 && count == 0) {
        return @"";
    }
    
    if (count == 0) {
        return [@(index) stringValue];
    }
    
    return [NSString stringWithFormat:@"%li of %li ", index, count];
}

#pragma mark - TableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return 8;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    
    NSString *oldValue = @"";
    NSString *newValue = @"";
    
    if (rowIndex == 0) {
        oldValue = self.rowData.fileTrack.name;
        newValue = self.rowData.officialInfo[@"trackCensoredName"];
    }
    else if (rowIndex == 1) {
        oldValue = self.rowData.fileTrack.artist;
        newValue = self.rowData.officialInfo[@"artistName"];
    }
    else if (rowIndex == 2) {
        oldValue = self.rowData.fileTrack.albumArtist;
        newValue = self.rowData.officialInfo[@"albumArtistName"];
    }
    else if (rowIndex == 3) {
        oldValue = self.rowData.fileTrack.album;
        newValue = self.rowData.officialInfo[@"collectionName"];
    }
    else if (rowIndex == 4) {
        oldValue = self.rowData.fileTrack.genre;
        newValue = self.rowData.officialInfo[@"primaryGenreName"];
    }
    else if (rowIndex == 5) {
        oldValue = [@(self.rowData.fileTrack.year) stringValue];
        newValue = [self.rowData.officialInfo[@"year"] stringValue];
    }
    else if (rowIndex == 6) {
        oldValue = [self formatIndex:self.rowData.fileTrack.trackNumber
                               count:self.rowData.fileTrack.trackCount];
       newValue = [self formatIndex:[self.rowData.officialInfo[@"trackNumber"] intValue]
                              count:[self.rowData.officialInfo[@"trackCount"] intValue]];
    }
    else if (rowIndex == 7) {
        oldValue = [self formatIndex:self.rowData.fileTrack.discNumber
                          count:self.rowData.fileTrack.discCount];
        newValue = [self formatIndex:[self.rowData.officialInfo[@"discNumber"] intValue]
                          count:[self.rowData.officialInfo[@"discCount"] intValue]];
    }    
    
    if ([oldValue isEqualToString:newValue]) {
        [cell setTextColor:[NSColor textColor]];
    }
    else {
        [cell setTextColor:[NSColor redColor]];
    }

}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableColumn identifier] isEqualToString:@"fieldCol"]) {
        if (rowIndex == 0) {
            return @"Name";
        }
        else if (rowIndex == 1) {
            return @"Artist";
        }
        else if (rowIndex == 2) {
            return @"Album Artist";
        }
        else if (rowIndex == 3) {
            return @"Album";
        }
        else if (rowIndex == 4) {
            return @"Genre";
        }
        else if (rowIndex == 5) {
            return @"Year";
        }
        else if (rowIndex == 6) {
            return @"Track Number";
        }
        else if (rowIndex == 7) {
            return @"Disc Number";
        }
    }
    else if ([[aTableColumn identifier] isEqualToString:@"currentCol"]) {
        if (rowIndex == 0) {
            return self.rowData.fileTrack.name;
        }
        else if (rowIndex == 1) {
            return self.rowData.fileTrack.artist;
        }
        else if (rowIndex == 2) {
            return self.rowData.fileTrack.albumArtist;
        }
        else if (rowIndex == 3) {
            return self.rowData.fileTrack.album;
        }
        else if (rowIndex == 4) {
            return self.rowData.fileTrack.genre;
        }
        else if (rowIndex == 5) {
            return [@(self.rowData.fileTrack.year) stringValue];
        }
        else if (rowIndex == 6) {
            return [self formatIndex:self.rowData.fileTrack.trackNumber
                          count:self.rowData.fileTrack.trackCount];
        }
        else if (rowIndex == 7) {
            return [self formatIndex:self.rowData.fileTrack.discNumber
                          count:self.rowData.fileTrack.discCount];
        }
    }
    else if ([[aTableColumn identifier] isEqualToString:@"newCol"]) {
        if (self.rowData.officialInfo == nil) {
            return @"";
        }
        
        if (rowIndex == 0) {
            return self.rowData.officialInfo[@"trackCensoredName"];
        }
        else if (rowIndex == 1) {
            return self.rowData.officialInfo[@"artistName"];
        }
        else if (rowIndex == 2) {
            return self.rowData.officialInfo[@"albumArtistName"];;
        }
        else if (rowIndex == 3) {
            return self.rowData.officialInfo[@"collectionName"];
        }
        else if (rowIndex == 4) {
            return self.rowData.officialInfo[@"primaryGenreName"];
        }
        else if (rowIndex == 5) {
            NSNumber *year = self.rowData.officialInfo[@"year"];
            return [year stringValue];
        }
        else if (rowIndex == 6) {
            return [self formatIndex:[self.rowData.officialInfo[@"trackNumber"] intValue]
                               count:[self.rowData.officialInfo[@"trackCount"] intValue]];
        }
        else if (rowIndex == 7) {
            return [self formatIndex:[self.rowData.officialInfo[@"discNumber"] intValue]
                               count:[self.rowData.officialInfo[@"discCount"] intValue]];
        }
            
    }
    
    return @"";
}

@end
