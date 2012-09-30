//
//  LocalCache.h
//  iTunesMatchHelper
//
//  Created by Nathan Villaescusa on 9/29/12.
//
//

#import <Foundation/Foundation.h>

@interface LocalCache : NSObject

- (id)initWithPath:(NSString *)path;

- (NSDictionary *)trackInfo:(NSInteger)trackId;
- (void)addTrackInfo:(NSInteger)trackId countryCode:(NSString *)countryCode info:(NSDictionary *)info;

- (NSUInteger)trackIdForDatabaseId:(NSUInteger)databaseID;
- (void)addTrackId:(NSUInteger)trackId toDatabaseId:(NSUInteger)databaseID;



@end
