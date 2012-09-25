//
//  iTunesLibrary.h
//  iTunesMatchHelper
//
//  Created by Nathan Villaescusa on 9/8/12.
//
//

#import <Foundation/Foundation.h>

@class iTunesLibraryPlaylist;
@class iTunesFileTrack;

@interface iTunesLibrary : NSObject

+ (iTunesLibraryPlaylist *)primaryPlaylist;

+ (NSNumber *)fileTrackId:(iTunesFileTrack *)track;

@end
