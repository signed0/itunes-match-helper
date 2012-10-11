//
//  AppDelegate.m
//  iTunesMatchHelper
//
//  Created by Kevin Vinck on 17-12-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "TrackView.h"

#import "iTunesApi.h"
#import "iTunesLibrary.h"
#import "RowData.h"
#import "LocalCache.h"

#define kApplicationSupportName @"iTunes Match Helper"
#define kCacheFilename @"cache.sqlite"

@interface AppDelegate ()

@property (nonatomic, strong) NSMutableArray *songData;

@property (nonatomic) BOOL updatingLibrary;
@property (nonatomic) BOOL canCancel;
@property (nonatomic) BOOL doCancel;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.updatingLibrary = NO;
    self.canCancel = NO;
    self.doCancel = NO;
    
    self.trackView.tableView = self.trackTableView;    
}

#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [self.songData count];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if (![[aTableColumn identifier] isEqualToString:@"checkCol"]) {
        return;
    }
    
    RowData *songInfo = self.songData[rowIndex];
    songInfo.isChecked = [value boolValue];
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    RowData *songInfo = self.songData[rowIndex];
    
    NSString *colId = [aTableColumn identifier];
    
    if ([colId isEqualToString:@"iTunesId"]) {
        return [NSString stringWithFormat:@"%li", songInfo.trackId];
    } else if ([colId isEqualToString:@"origName"]) {
        return [songInfo.fileTrack name];
    } else if ([colId isEqualToString:@"origArtist"]) {
        return [songInfo.fileTrack artist];
    } else if ([colId isEqualToString:@"origAlbum"]) {
        return [songInfo.fileTrack album];
    } else if ([colId isEqualToString:@"checkCol"]) {
        if (songInfo.officialInfo == nil) {
            return  @(NSOffState);
        } else {
            return @(songInfo.isChecked ? NSOnState : NSOffState);
        }  
    } else if ([colId isEqualToString:@"countryCode"]) {
        if (songInfo.officialInfo == nil) {
            return  @"";
        } else {
            return songInfo.officialInfo[@"countryCode"];
        }
    }
    
    return @"";
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    
    RowData *songInfo = self.songData[rowIndex];
    
    NSDictionary *newInfo = songInfo.officialInfo;
    iTunesFileTrack *oldInfo = songInfo.fileTrack;
    
    [cell setEnabled:YES];
    
    if (newInfo == nil) {
        if ([[aTableColumn identifier] isEqualToString:@"checkCol"]) {
            [cell setEnabled:NO];
        }
        else {
            [cell setTextColor:[NSColor grayColor]];            
        }
    }
    else if (songInfo.isDifferent) {
        if ([[aTableColumn identifier] isEqualToString:@"checkCol"]) {
            return;
        }
        
        NSString *newArtist = newInfo[@"artistName"];
        NSString *newAlbum = newInfo[@"collectionName"];;
        NSString *newName = newInfo[@"trackCensoredName"];
        
        BOOL isDifferent = NO;
        
        if ([[aTableColumn identifier] isEqualToString:@"origName"]) {
            if (![[oldInfo name] isEqualToString:newName]) {
                isDifferent = YES;
            }
        } else if ([[aTableColumn identifier] isEqualToString:@"origArtist"]) {
            if (![[oldInfo artist] isEqualToString:newArtist]) {
                isDifferent = YES;
            }
        } else if ([[aTableColumn identifier] isEqualToString:@"origAlbum"]) {
            if (![[oldInfo album] isEqualToString:newAlbum]) {
                isDifferent = YES;
            }
        }
        
        if (isDifferent) {
            [cell setTextColor:[NSColor redColor]];
        }
        else {
            [cell setTextColor:[NSColor textColor]];
        }
    
    } else {
        if ([[aTableColumn identifier] isEqualToString:@"checkCol"]) {
            [cell setEnabled:NO];
        }
        else {
            [cell setTextColor:[NSColor blueColor]];
        }
        
    }
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
    [self displayRowData:self.songData[row]];
    
    return YES;
}

#pragma mark -

- (void)displayRowData:(RowData *)rowData {
    
    self.trackView.rowData = rowData;
    
    if (rowData == nil) {
        [self.trackView setHidden:YES];
        return;
    }
    
    [self.trackView setHidden:NO];
    
    NSString *trackId = [[NSNumber numberWithUnsignedInteger:rowData.trackId] stringValue];
    [self.trackIdLabel setStringValue:trackId];
    
    if (rowData.officialInfo == nil) {
        [self.countryCodeLabel setStringValue:@""];
    }
    else {
        NSString *countryCode = rowData.officialInfo[@"countryCode"];
        [self.countryCodeLabel setStringValue:countryCode];
    }
    
}

// Takes an array, splits it into chunks of the given size, runs each chunk through
// the block and then combines the results
- (NSArray *)chunkArray:(NSArray *)array size:(NSInteger)size callback:(NSArray *(^)(NSArray *chunk))block {
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[array count]];
    
    NSRange range;
    for (int i = 0; i < [array count]; i+=size) {
        range.location = i;
        range.length = MIN(size, [array count] - i);
        
        NSArray *items = block([array subarrayWithRange:range]);        
        [result addObjectsFromArray:items];
    }
    return result;
}

- (NSArray *)matchTrackIds:(NSArray *)trackIds {
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.progressBar.doubleValue = 0;
    });
    
    NSMutableArray *mTrackIds = [trackIds mutableCopy];
    
    NSArray *countryCodes = @[@"US", @"GB", @"DE", @"SE", @"AU", @"CA", @"FR", @"AR", @"DK", @"NL"];
    
    const int batchSize = 100;
    
    NSMutableDictionary *matches = [NSMutableDictionary dictionaryWithCapacity:[mTrackIds count]];
    
    for (NSString *countryCode in countryCodes) {
        
        NSArray *result = [self chunkArray:mTrackIds size:batchSize callback:^(NSArray *chunk){
            NSArray *tracks = [iTunesApi lookupTracks:chunk forCountry:countryCode];
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                self.progressBar.doubleValue += [tracks count];
            });
            
            return tracks;
        }];
        
        for (NSMutableDictionary *track in result) {
            NSNumber *trackId = track[@"trackId"];
            matches[trackId] = track;
            [mTrackIds removeObject:trackId];
            
            track[@"countryCode"] = countryCode;
            
            NSDate *releaseDate = track[@"releaseDate"];
            NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:releaseDate];
            track[@"year"] = @(components.year);
        }
    }
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[trackIds count]];
    
    for (NSNumber *trackId in trackIds) {
        NSDictionary *track = matches[trackId];
        if (track == nil) {
            [result addObject:@{}];
        }
        else {
            [result addObject:track];
        }
    }
    
    // create a set containing all the album ids for tracks that were matched
    NSMutableSet *albumIds = [NSMutableSet new];
    for (NSDictionary *item in result) {
        if ([item count] == 0) {
            continue;
        }
        [albumIds addObject:item[@"collectionId"]];
    }
    NSLog(@"%li albums", [albumIds count]);
    
    NSMutableArray *albums = [NSMutableArray arrayWithCapacity:[albumIds count]];
    
    for (NSString *countryCode in countryCodes) {        
        NSArray *countryAlbums = [self chunkArray:[albumIds allObjects] size:batchSize callback:^(NSArray *chunk){
            return [iTunesApi lookupCollections:chunk forCountry:countryCode];
        }];
        [albums addObjectsFromArray:countryAlbums];
    }
    
    NSMutableDictionary *albumMap = [NSMutableDictionary dictionaryWithCapacity:[albums count]];
    
    // create a dictionary of all the albums
    for (NSDictionary *album in albums) {
        albumMap[album[@"collectionId"]] = album;
    }
    
    for (NSMutableDictionary *item in result) {
        if ([item count] == 0) {
            continue;
        }
        
        NSNumber *collectionId = item[@"collectionId"];
        NSLog(@"%@", collectionId);
        NSDictionary *collection = albumMap[collectionId];
        if (collection != nil) {
            item[@"albumArtistName"] = collection[@"artistName"];
        }
    }
    
    return result;
}

+ (NSString *)applicationSupportDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                         NSUserDomainMask,
                                                         YES);
    if ([paths count] != 1) {
        return nil;
    }
    
    NSString *path = [paths[0] stringByAppendingPathComponent:kApplicationSupportName];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL isDir;
    if (![fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        NSError * error = nil;
        [fileManager createDirectoryAtPath:path
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:&error];
        if (error != nil) {
            NSLog(@"error creating directory: %@", error);
            return nil;
        }
    }
    
    return path;
}

- (IBAction)fetchLibrary:(id)sender {
    self.doCancel = NO;
    
    NSString *appSupportDir = [AppDelegate applicationSupportDirectory];
    if (appSupportDir == nil) {
        return;
    }
    
    NSString *cachePath = [appSupportDir stringByAppendingPathComponent:kCacheFilename];    
    LocalCache *cache = [[LocalCache alloc] initWithPath:cachePath];
    
    if (self.canCancel) {
        self.doCancel = YES;
        if (self.updatingLibrary) {
            [self.scanButton setTitle:@"Update Library"];
            [self.progressLabel setStringValue:@"Updating canceled. Click 'Update Library' to update checked songs."];
        } else {
            [self.scanButton setTitle:@"Scan Library"];
            [self.progressLabel setStringValue:@"Scanning canceled. Click 'Scan Library' to begin."];
        }
        self.canCancel = NO;
    }
    
    if (!self.updatingLibrary) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            if (self.doCancel)
                return;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.scanButton setTitle:@"Cancel"];
                self.canCancel = YES;
            });
            
            iTunesLibraryPlaylist *theLibraryPlaylist = [iTunesLibrary primaryPlaylist];
            
            NSArray *fileList = [[theLibraryPlaylist fileTracks] get];

            self.songData = [NSMutableArray arrayWithCapacity:[fileList count]];
            
            self.progressBar.minValue = 1;
            self.progressBar.maxValue = [fileList count];
            
            for (int x=0;x < [fileList count];x++) {
                if (self.doCancel)
                    return;
                iTunesFileTrack *track = fileList[x];
                //NSLog(@"Loading track %i of %lu",x,[fileList count]);
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    NSUInteger fileListCount = [fileList count];
                    int z = x+1;
                    if (self.doCancel)
                        [self.progressLabel setStringValue:@"Scanning canceled. Click 'Scan Library' to begin."];
                    else
                        [self.progressLabel setStringValue:[NSString stringWithFormat:@"Scanning iTunes library song %i of %li...",z,fileListCount]];
                    [self.progressBar setDoubleValue:z];
                });
                
                NSUInteger trackId = [cache trackIdForDatabaseId:[track databaseID]];
                
                if (trackId == 0) {
                    // not in cache, read file
                    trackId = [iTunesLibrary fileTrackId:track];
                    
                    if (trackId > 0) {
                        [cache addTrackId:trackId toDatabaseId:[track databaseID]];
                    }
                }
                
                if (trackId > 0) {
                    RowData *rowData = [[RowData alloc] init];
                    rowData.isChecked = NO;
                    rowData.trackId = trackId;
                    rowData.fileTrack = track;
                    
                    [self.songData addObject:rowData];
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [self.songTable reloadData];
                    });
                }
                
                
            }
            
            NSLog(@"Found %lu matched songs.",[self.songData count]);
            
            self.progressBar.maxValue = [self.songData count];
            
            NSMutableArray *trackIds = [NSMutableArray arrayWithCapacity:[self.songData count]];
            for (RowData *item in self.songData) {
                NSDictionary *trackInfo = [cache trackInfo:item.trackId];
                if (trackInfo == nil) {
                    [trackIds addObject:@(item.trackId)];
                }
                else {
                    item.officialInfo = trackInfo;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.songTable reloadData];
            });
            
            NSMutableDictionary *matchedTracks = [NSMutableDictionary dictionary];
            
            NSArray *tracks = [self matchTrackIds:trackIds];
            for (NSDictionary *matchedTrack in tracks) {
                if (matchedTrack != nil && [matchedTrack count] > 0) {
                    matchedTracks[matchedTrack[@"trackId"]] = matchedTrack;
                }
            }
            
            NSLog(@"Fetched data for  %lu/%lu matched songs.", [tracks count],[self.songData count]);
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.progressBar setDoubleValue:[self.songData count]];
            });            
            
            for (RowData *rowData in self.songData) {
                iTunesFileTrack *track = rowData.fileTrack;
                
                if (rowData.officialInfo == nil) {                
                    NSDictionary *songNewData = matchedTracks[@(rowData.trackId)];
                    if (songNewData == nil) {
                        NSLog(@"No metadata available for song %@ (ID: %li)",[track name], rowData.trackId);
                    }
                    else {
                        [cache addTrackInfo:rowData.trackId
                                countryCode:songNewData[@"countryCode"]
                                       info:songNewData];
                        rowData.officialInfo = songNewData;
                        NSLog(@"Metadata for song %@ found in the %@ store",[track name], songNewData[@"country"]);
                    }
                }
                
                rowData.isDifferent = [self isTrackInfoDifferent:track newInfo:rowData.officialInfo];
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self.songTable reloadData];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.scanButton setTitle:@"Update Library"];
                self.updatingLibrary = YES;
                self.canCancel = NO;
                [self.progressLabel setStringValue:@"Finished fetching metadata. Click 'Update Library to update checked songs."];
            });
        });
    } else if (self.updatingLibrary) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            if (self.doCancel)
                return;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.scanButton setTitle:@"Cancel"];
                self.canCancel = YES;
            });
            
            self.progressBar.maxValue = [self.songData count];
            for (int z=0;z < [self.songData count];z++) {
                if (self.doCancel)
                    return;
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self.progressLabel setStringValue:[NSString stringWithFormat:@"Updating metadata for song %i of %li...",z+1,[self.songData count]]];
                    [self.progressBar setDoubleValue:z+1];
                });
                
                RowData *songInfo = self.songData[z];
                if (songInfo.isChecked) {
                    NSDictionary *newInfo = songInfo.officialInfo;
                    iTunesFileTrack *track = songInfo.fileTrack;
                    [self replaceTrackInfo:track newInfo:newInfo];                    
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.scanButton setTitle:@"Scan Library"];
                self.updatingLibrary = NO;
                self.canCancel = NO;
                [self.progressLabel setStringValue:@"Finished updating song metadata."];
            });
        });
    }
}

- (void)replaceTrackInfo:(iTunesFileTrack *)track newInfo:(NSDictionary *)trackInfo {
    NSLog(@"Replacing title: %@ with title: %@", track.name, trackInfo[@"trackCensoredName"]);
    
    track.name = trackInfo[@"trackCensoredName"];
    track.album = trackInfo[@"collectionName"];
    track.artist = trackInfo[@"artistName"];
    track.albumArtist = trackInfo[@"albumArtistName"];
    
    track.genre = trackInfo[@"primaryGenreName"];
    
    [track setTrackNumber:[trackInfo[@"trackNumber"] intValue]];
    [track setTrackCount:[trackInfo[@"trackCount"] intValue]];
    
    [track setDiscNumber:[trackInfo[@"discNumber"] intValue]];
    [track setDiscCount:[trackInfo[@"discCount"] intValue]];
    
    track.year = [trackInfo[@"year"] intValue];
}

- (BOOL)isTrackInfoDifferent:(iTunesFileTrack *)track newInfo:(NSDictionary *)trackInfo {
    if (![track.name isEqualTo:trackInfo[@"trackCensoredName"]]) {
        return YES;
    }
    
    if (![track.albumArtist isEqualToString:trackInfo[@"albumArtistName"]]) {
        return YES;
    }
        
    if (![track.album isEqualTo:trackInfo[@"collectionName"]]) {
        return YES;
    }
    
    if (![track.artist isEqualTo:trackInfo[@"artistName"]]) {
        return YES;
    }
    
    if (track.trackCount != [trackInfo[@"trackCount"] intValue]) {
        return YES;
    }
    
    if (track.trackNumber != [trackInfo[@"trackNumber"] intValue]) {
        return YES;
    }
    
    if (track.discCount != [trackInfo[@"discCount"] intValue]) {
        return YES;
    }
    
    if (track.discNumber != [trackInfo[@"discNumber"] intValue]) {
        return YES;
    }
    
    if (![track.genre isEqualToString:trackInfo[@"primaryGenreName"]]) {
        return YES;
    }
    
    if (track.year != [trackInfo[@"year"] intValue]) {
        return YES;
    };
    
    return NO;
}

- (IBAction)checkAllItems:(id)sender {
    for (RowData *rowData in self.songData) {
        rowData.isChecked = YES;
    }
    [self.songTable reloadData];
}

- (IBAction)uncheckAllItems:(id)sender {
    for (RowData *rowData in self.songData) {
        rowData.isChecked = NO;
    }
    [self.songTable reloadData];
}



@end
