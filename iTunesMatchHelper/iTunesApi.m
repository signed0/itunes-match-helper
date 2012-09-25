//
//  iTunesApi.m
//  iTunesMatchHelper
//
//  Created by Nathan Villaescusa on 9/8/12.
//
//

#import "iTunesApi.h"

#define BASE_URL @"http://itunes.apple.com/lookup"

@implementation iTunesApi

#pragma  mark - Helper Methods

+ (NSDate *)parseRFC3339Date:(NSString *)dateString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    NSDate *theDate = nil;
    NSError *error = nil;
    if (![formatter getObjectValue:&theDate forString:dateString range:nil error:&error]) {
        NSLog(@"Date '%@' could not be parsed: %@", dateString, error);
    }
    
    return theDate;
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

+ (NSDictionary *)fetchJsonEndpoint:(NSURL *)url {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // Fetch the data
    NSData *response = [NSURLConnection sendSynchronousRequest:request
                                             returningResponse:nil
                                                         error:nil];
    
    // Deserialize JSON
    return [self decodeJsonData:response];
}

+ (NSDictionary *)cleanupTrackInfo:(NSMutableDictionary *)trackInfo {
    
    
    NSString *releaseDate = trackInfo[@"releaseDate"];
    trackInfo[@"releaseDate"] = [self parseRFC3339Date:releaseDate];
    
    return trackInfo;
}

+ (NSArray *)lookupItems:(NSArray *)ids forCountry:(NSString *)countryCode {
    NSString *idsString = [ids componentsJoinedByString:@","];
    
    NSString *urlString = [NSString stringWithFormat:@"%@?id=%@", BASE_URL, idsString];
    if (countryCode != nil) {
        urlString = [urlString stringByAppendingFormat:@"&country=%@", countryCode];
    }
    
    // Fetch the URl
    NSDictionary *result = [self fetchJsonEndpoint:[NSURL URLWithString:urlString]];
    
    return result[@"results"];
}

#pragma mark - Public Methods

+ (NSDictionary *)lookupTrack:(NSUInteger)trackId {
    return [self lookupTrack:trackId forCountry:nil];
}

+ (NSDictionary *)lookupTrack:(NSUInteger)trackId forCountry:(NSString *)countryCode {

    NSArray *tracks = [self lookupTracks:@[@(trackId)] forCountry:countryCode];
    
    if ([tracks count] == 0) {
        return nil;
    }

    return tracks[0];
}

+ (NSDictionary *)lookupTrack:(NSUInteger)trackId forCountries:(NSArray *)countryCodes {
    for (NSString *countryCode in countryCodes) {
        NSDictionary *trackData = [self lookupTrack:trackId forCountry:countryCode];
        if (trackData != nil) {
            return trackData;
        }       
    }
    
    return nil;
}

+ (NSArray *)lookupTracks:(NSArray *)trackIds {
    return [self lookupTracks:trackIds forCountry:nil];
}

+ (NSArray *)lookupTracks:(NSArray *)trackIds forCountry:(NSString *)countryCode {
    
    NSArray *tracks = [self lookupItems:trackIds forCountry:countryCode];
    for (NSMutableDictionary *trackInfo in tracks) {
        [self cleanupTrackInfo:trackInfo];
    }
    
    return tracks;
}

+ (NSArray *)lookupCollections:(NSArray *)collectionIds {
    return [self lookupItems:collectionIds forCountry:nil];
}

+ (NSArray *)lookupCollections:(NSArray *)collectionIds forCountry:(NSString *)countryCode {
    return [self lookupItems:collectionIds forCountry:countryCode];
}


@end
