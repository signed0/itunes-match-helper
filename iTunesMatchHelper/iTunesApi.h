//
//  iTunesApi.h
//  iTunesMatchHelper
//
//  Created by Nathan Villaescusa on 9/8/12.
//
//

#import <Foundation/Foundation.h>

#define kCountryCodes     @[@"US", @"GB", @"AU", @"FR", @"DE", @"CA", @"IT", \
                            @"JP", @"DZ", @"AO", @"AI", @"AG", @"AR", @"AM", \
                            @"AT", @"AZ", @"BS", @"BH", @"BD", @"BB", @"BY", \
                            @"BE", @"BZ", @"BM", @"BO", @"BW", @"BR", @"BN", \
                            @"BG", @"CM", @"KY", @"CL", @"CN", @"CO", @"CR", \
                            @"CI", @"HR", @"CY", @"CZ", @"DK", @"DM", @"DO", \
                            @"EC", @"EG", @"SV", @"EE", @"ET", @"FI", @"GH", \
                            @"GR", @"GD", @"GT", @"GY", @"HN", @"HK", @"HU", \
                            @"IS", @"IN", @"ID", @"IE", @"IL", @"JM", @"JO", \
                            @"KZ", @"KE", @"KR", @"KW", @"LV", @"LB", @"LY", \
                            @"LI", @"LT", @"LU", @"MO", @"MK", @"MG", @"MY", \
                            @"MV", @"ML", @"MT", @"MU", @"MX", @"MD", @"MS", \
                            @"MM", @"NP", @"NL", @"NZ", @"NI", @"NE", @"NG", \
                            @"NO", @"OM", @"PK", @"PA", @"PY", @"PE", @"PH", \
                            @"PL", @"PT", @"QA", @"RO", @"RU", @"KN", @"LC", \
                            @"VC", @"SA", @"SN", @"RS", @"SG", @"SK", @"SI", \
                            @"ZA", @"ES", @"LK", @"SR", @"SE", @"CH", @"TW", \
                            @"TZ", @"TH", @"TT", @"TN", @"TR", @"TC", @"UG", \
                            @"UA", @"AE", @"UY", @"UZ", @"VE", @"VN", @"VG", \
                            @"YE"];

@interface iTunesApi : NSObject

+ (NSDictionary *)lookupTrack:(NSUInteger)trackId;
+ (NSDictionary *)lookupTrack:(NSUInteger)trackId forCountry:(NSString *)countryCode;
+ (NSDictionary *)lookupTrack:(NSUInteger)trackId forCountries:(NSArray *)countryCodes;

+ (NSArray *)lookupTracks:(NSArray *)trackIds;
+ (NSArray *)lookupTracks:(NSArray *)trackIds forCountry:(NSString *)countryCode;

+ (NSArray *)lookupCollections:(NSArray *)collectionIds;
+ (NSArray *)lookupCollections:(NSArray *)collectionIds forCountry:(NSString *)countryCode;

@end
