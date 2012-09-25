//
//  AppDelegate.m
//  iTunesMatchHelper
//
//  Created by Kevin Vinck on 17-12-11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize progressBar = _progressBar;
@synthesize progressLabel = _progressLabel;
@synthesize songTable = _songTable;
@synthesize scanButton = _scanButton;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    updatingLibrary = NO;
    canCancel = NO;
    doCancel = NO;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [songData count];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {          
    if ([[aTableColumn identifier] isEqualToString:@"checkCol"]) {
        NSArray *songInfo = [songData objectAtIndex:rowIndex];
        
        NSDictionary *newInfo = [songInfo objectAtIndex:0];
        iTunesFileTrack *oldInfo = [songInfo objectAtIndex:1];
        
        NSArray *newSongInfo = [NSArray arrayWithObjects:newInfo,oldInfo,[NSNumber numberWithBool:[value boolValue]], nil];
        
        [songData replaceObjectAtIndex:rowIndex withObject:newSongInfo];
    }
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    //NSLog(@"Updating data for column: %@ / row: %ldi",[aTableColumn identifier],rowIndex);
    
    NSArray *songInfo = [songData objectAtIndex:rowIndex];
    
    NSDictionary *newInfo = [songInfo objectAtIndex:0];
    iTunesFileTrack *oldInfo = [songInfo objectAtIndex:1];
    BOOL selected = [[songInfo objectAtIndex:2] boolValue];
    
    if ([[aTableColumn identifier] isEqualToString:@"origName"]) {
        return [oldInfo name];
    } else if ([[aTableColumn identifier] isEqualToString:@"origArtist"]) {
        return [oldInfo artist];
    } else if ([[aTableColumn identifier] isEqualToString:@"newName"]) {
        if ([[newInfo valueForKey:@"resultCount"] intValue] == 0) {
            return  @"";
        } else {
            return [[[newInfo valueForKey:@"results"] objectAtIndex:0] valueForKey:@"trackName"];
        }
    } else if ([[aTableColumn identifier] isEqualToString:@"newArtist"]) {
        if ([[newInfo valueForKey:@"resultCount"] intValue] == 0) {
            return  @"";
        } else {
            return [[[newInfo valueForKey:@"results"] objectAtIndex:0] valueForKey:@"artistName"];
        }
    } else if ([[aTableColumn identifier] isEqualToString:@"origAlbum"]) {
        return [oldInfo album];
    } else if ([[aTableColumn identifier] isEqualToString:@"newAlbum"]) {
        if ([[newInfo valueForKey:@"resultCount"] intValue] == 0) {
            return  @"";
        } else {
            return [[[newInfo valueForKey:@"results"] objectAtIndex:0] valueForKey:@"collectionName"];
        }
    } else if ([[aTableColumn identifier] isEqualToString:@"checkCol"]) {
        if ([[newInfo valueForKey:@"resultCount"] intValue] == 0) {
            return  @"";
        } else {
            return [NSNumber numberWithInteger:(selected ? NSOnState : NSOffState)];
        }  
    } else
        return @"";
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    
    NSArray *songInfo = [songData objectAtIndex:rowIndex];
    
    NSDictionary *newInfo = [songInfo objectAtIndex:0];
    iTunesFileTrack *oldInfo = [songInfo objectAtIndex:1];
    
    if ([[newInfo valueForKey:@"resultCount"] intValue] < 1) {
        [cell setEnabled:NO];
    } else {
        [cell setEnabled:YES];
    }
    
    if ([[newInfo valueForKey:@"resultCount"] intValue] > 0) {
        NSString *newArtist = [[[newInfo valueForKey:@"results"] objectAtIndex:0] valueForKey:@"artistName"];
        NSString *newAlbum = [[[newInfo valueForKey:@"results"] objectAtIndex:0] valueForKey:@"collectionName"];;
        NSString *newName = [[[newInfo valueForKey:@"results"] objectAtIndex:0] valueForKey:@"trackName"];
        
        if ([[aTableColumn identifier] isEqualToString:@"newName"]) {
            if (![[oldInfo name] isEqualToString:newName]) {
                [cell setTextColor:[NSColor redColor]];
            } else {
                [cell setTextColor:[NSColor textColor]];
            }
        } else if ([[aTableColumn identifier] isEqualToString:@"newArtist"]) {
            if (![[oldInfo artist] isEqualToString:newArtist]) {
                [cell setTextColor:[NSColor redColor]];
            } else {
                [cell setTextColor:[NSColor textColor]];
            }
        } else if ([[aTableColumn identifier] isEqualToString:@"newAlbum"]) {
            if (![[oldInfo album] isEqualToString:newAlbum]) {
                [cell setTextColor:[NSColor redColor]];
            } else {
                [cell setTextColor:[NSColor textColor]];
            }
        }
    } else {
        if (![[aTableColumn identifier] isEqualToString:@"checkCol"])
            [cell setTextColor:[NSColor textColor]];
    }
    
}

+ (NSMutableDictionary *)decodeJsonData:(NSData *)jsonData {
    
    if (jsonData == nil) {
        NSLog(@"[%@ %@] JSON error: %@",
              NSStringFromClass([self class]),
              NSStringFromSelector(_cmd),
              @"Json data was nil");
        return nil;
    }
    
    NSError *error = nil;
    NSMutableDictionary *results = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                   options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves
                                                                     error:&error];
    if (error) {
        NSLog(@"[%@ %@] JSON error: %@",
              NSStringFromClass([self class]),
              NSStringFromSelector(_cmd),
              error.localizedDescription);
        return nil;
    }
    
    return results;
}

- (IBAction)fetchLibrary:(id)sender {
    doCancel = NO;
    
    if (canCancel) {
        doCancel = YES;
        if (updatingLibrary) {
            [self.scanButton setTitle:@"Update Library"];
            [self.progressLabel setStringValue:@"Updating canceled. Click 'Update Library' to update checked songs."];
        } else {
            [self.scanButton setTitle:@"Scan Library"];
            [self.progressLabel setStringValue:@"Scanning canceled. Click 'Scan Library' to begin."];
        }
        canCancel = NO;
    }
    
    if (!updatingLibrary) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            if (doCancel)
                return;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.scanButton setTitle:@"Cancel"];
                canCancel = YES;
            });
            iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
            
            songData = [NSMutableArray arrayWithCapacity:5];
            
            SBElementArray *sources = [iTunes sources];
            iTunesSource *libsource;
            
            for (iTunesSource *source in sources) {
                if ([source kind] == 'kLib') {
                    NSLog(@"Found library");
                    libsource = source;
                    break;
                }
            }
            
            SBElementArray *libPlaylists = [libsource libraryPlaylists];
            
            iTunesLibraryPlaylist *theLibraryPlaylist = [libPlaylists objectAtIndex:0];
            
            //SBJsonParser *paser = [[SBJsonParser alloc] init];
            
            NSArray *fileList = [[theLibraryPlaylist fileTracks] get];
            
            NSMutableArray *searchList = [[NSMutableArray alloc] initWithCapacity:1];
            self.progressBar.minValue = 1;
            self.progressBar.maxValue = [fileList count];
            
            for (int x=0;x < [fileList count];x++) {
                if (doCancel)
                    return;
                iTunesFileTrack *track = [fileList objectAtIndex:x];
                //NSLog(@"Loading track %i of %lu",x,[fileList count]);
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    NSUInteger fileListCount = [fileList count];
                    int z = x+1;
                    if (doCancel)
                        [self.progressLabel setStringValue:@"Scanning canceled. Click 'Scan Library' to begin."];
                    else
                        [self.progressLabel setStringValue:[NSString stringWithFormat:@"Scanning iTunes library song %i of %li...",z,fileListCount]];
                    [self.progressBar setDoubleValue:z];
                });
                
                if (([[track kind] isEqualToString:@"Matched AAC audio file"])) {
                    //NSLog(@"Track location: %@",[track location]);
                    NSData *file = [NSData dataWithContentsOfURL:[track location]];
                    if (file != nil) {
                        //NSLog(@"Finding song in track %i",x);
                        NSRange range = [file rangeOfData:[@"song" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(0, 700)];
                        //NSLog(@"Range of song is: (%lu,%lu)",range.location,range.length);
                        if (range.location != NSNotFound) {
                            NSData *iTunesIDData = [file subdataWithRange:NSMakeRange(range.location+4, 4)];
                            //NSLog(@"ID Hex: %@",iTunesIDData);
                            
                            int iTunesIDInt = CFSwapInt32BigToHost(*(int*)([iTunesIDData bytes]));
                            NSNumber *iTunesID = [NSNumber numberWithInt:iTunesIDInt];
                            NSNumber *trackID = [NSNumber numberWithInteger:[track id]];
                            NSArray *iTunesTrack = [NSArray arrayWithObjects:iTunesID,track,trackID, nil];
                            
                            [searchList addObject:iTunesTrack];
                            
                            //NSLog(@"iTunes persistant ID: %ld",[track id]);
                        } else {
                            NSLog(@"SONG ID NOT FOUND!!!");
                        }
                    } else {
                        NSLog(@"Could not load file.");
                    }
                }
            }
            
            NSLog(@"Found %lu matched songs.",[searchList count]);
            
            self.progressBar.maxValue = [searchList count];
            for (int y=0; y < [searchList count]; y++) {
                if (doCancel)
                    return;
                NSNumber *iTunesID = [[searchList objectAtIndex:y] objectAtIndex:0];
                iTunesFileTrack *track = [[searchList objectAtIndex:y] objectAtIndex:1];
                
                //NSLog(@"Getting info for song %i of %lu (ID: %i / Name: %@)",y,[searchList count],[iTunesID intValue],[track name]);
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self.progressLabel setStringValue:[NSString stringWithFormat:@"Fetching metadata for song %i of %li...",y+1,[searchList count]]];
                    [self.progressBar setDoubleValue:y+1];
                });
                
                
                NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/lookup?id=%i",[iTunesID intValue]];
                
                //NSLog(@"URL String: %@",urlString);
                
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
                
                NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                
                NSDictionary *songNewData = [AppDelegate decodeJsonData:response];
                
                
                if ([[songNewData valueForKey:@"resultCount"] intValue] > 0) {
                    NSArray *songInfo = [NSArray arrayWithObjects:songNewData,[[searchList objectAtIndex:y] objectAtIndex:1],[NSNumber numberWithBool:YES],[[searchList objectAtIndex:y] objectAtIndex:2], nil];
                    [songData addObject:songInfo];
                } else {
                    NSLog(@"No metadata available for song %@ (ID: %i)",[track name],[iTunesID intValue]);
                    NSArray *songInfo = [NSArray arrayWithObjects:songNewData,[[searchList objectAtIndex:y] objectAtIndex:1],[NSNumber numberWithBool:NO],[[searchList objectAtIndex:y] objectAtIndex:2], nil];
                    [songData addObject:songInfo];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self.songTable reloadData];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.scanButton setTitle:@"Update Library"];
                updatingLibrary = YES;
                canCancel = NO;
                [self.progressLabel setStringValue:@"Finished fetching metadata. Click 'Update Library to update checked songs."];
            });
        });
    } else if (updatingLibrary) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            if (doCancel)
                return;
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.scanButton setTitle:@"Cancel"];
                canCancel = YES;
            });
            iTunesApplication *iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
            
            SBElementArray *sources = [iTunes sources];
            iTunesSource *libsource;
            
            for (iTunesSource *source in sources) {
                if ([source kind] == 'kLib') {
                    NSLog(@"Found library");
                    libsource = source;
                    break;
                }
            }
            
            SBElementArray *libPlaylists = [[libsource libraryPlaylists] copy];
            
            iTunesLibraryPlaylist *theLibraryPlaylist = [libPlaylists objectAtIndex:0];
            
            //SBJsonParser *paser = [[SBJsonParser alloc] init];
            
            SBElementArray *fileList = [theLibraryPlaylist fileTracks];
            self.progressBar.maxValue = [songData count];
            for (int z=0;z < [songData count];z++) {
                if (doCancel)
                    return;
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [self.progressLabel setStringValue:[NSString stringWithFormat:@"Updating metadata for song %i of %li...",z+1,[songData count]]];
                    [self.progressBar setDoubleValue:z+1];
                });
                NSArray *songInfo = [songData objectAtIndex:z];
                if ([[songInfo objectAtIndex:2] boolValue]) {
                    NSDictionary *newInfo = [songInfo objectAtIndex:0];
                    iTunesFileTrack *track = [fileList objectWithID:[songInfo objectAtIndex:3]];
                    NSDictionary *trackInfo = [[newInfo valueForKey:@"results"] objectAtIndex:0];
                    
                    //NSLog(@"Track info: %@",[[newInfo valueForKey:@"results"] objectAtIndex:0]);
                    NSLog(@"Replacing title: %@ with title: %@",[track name],[trackInfo valueForKey:@"trackName"]);
                    
                    //NSLog(@"Track count: %i",[[trackInfo valueForKey:@"trackCount"] intValue]);
                    
                    track.name = [trackInfo valueForKey:@"trackName"];
                    track.album = [trackInfo valueForKey:@"collectionName"];
                    track.artist = [trackInfo valueForKey:@"artistName"];
                    [track setTrackCount:[[trackInfo valueForKey:@"trackCount"] intValue]];
                    [track setTrackNumber:[[trackInfo valueForKey:@"trackNumber"] intValue]];
                    track.genre = [trackInfo valueForKey:@"primaryGenreName"];
                    [track setDiscCount:[[trackInfo valueForKey:@"discCount"] intValue]];
                    [track setDiscNumber:[[trackInfo valueForKey:@"discNumber"] intValue]];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self.scanButton setTitle:@"Scan Library"];
                updatingLibrary = NO;
                canCancel = NO;
                [self.progressLabel setStringValue:@"Finished updating song metadata."];
            });
        });
    }
}

- (IBAction)checkAllItems:(id)sender {
    for (int i=0;i < [songData count];i++) {
        NSArray *songInfo = [songData objectAtIndex:i];
        NSDictionary *newInfo = [songInfo objectAtIndex:0];
        iTunesFileTrack *oldInfo = [songInfo objectAtIndex:1];
        
        NSArray *newSongInfo = [NSArray arrayWithObjects:newInfo,oldInfo,[NSNumber numberWithBool:YES], nil];
        
        [songData replaceObjectAtIndex:i withObject:newSongInfo];
    }
    [self.songTable reloadData];
}

- (IBAction)uncheckAllItems:(id)sender {
    for (int i=0;i < [songData count];i++) {
        NSArray *songInfo = [songData objectAtIndex:i];
        NSDictionary *newInfo = [songInfo objectAtIndex:0];
        iTunesFileTrack *oldInfo = [songInfo objectAtIndex:1];
        
        NSArray *newSongInfo = [NSArray arrayWithObjects:newInfo,oldInfo,[NSNumber numberWithBool:NO], nil];
        
        [songData replaceObjectAtIndex:i withObject:newSongInfo];
    }
    [self.songTable reloadData];
}



@end
