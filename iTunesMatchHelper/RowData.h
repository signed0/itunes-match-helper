//
//  RowData.h
//  iTunesMatchHelper
//
//  Created by Nathan Villaescusa on 9/8/12.
//
//

#import <Foundation/Foundation.h>
#import "iTunes.h"

@interface RowData : NSObject

@property (nonatomic) BOOL isChecked;
@property (nonatomic) BOOL isDifferent;
@property (nonatomic) NSUInteger trackId;
@property (nonatomic, strong) iTunesFileTrack *fileTrack;
@property (nonatomic, strong) NSDictionary *officialInfo;

@end
