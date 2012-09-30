//
//  LocalCache.m
//  iTunesMatchHelper
//
//  Created by Nathan Villaescusa on 9/29/12.
//
//

#import "LocalCache.h"
#import <sqlite3.h>

#define kTrackInfoTable @"trackInfo"
#define kFileTrackIdTable @"fileTrackIds"

@interface LocalCache ()

@property sqlite3 *database;

@end


@implementation LocalCache

- (id)initWithPath:(NSString *)path {
    if (self = [super init]) {
        sqlite3 *dbConnection;
        if (sqlite3_open([path UTF8String], &dbConnection) != SQLITE_OK) {
            
            NSLog(@"[SQLITE] Unable to open database!");
            return nil; // if it fails, return nil obj
        }
        _database = dbConnection;
        [self prepareTables];
    }
    return self;
}

- (void)prepareTables {
    NSString *sql = @"CREATE TABLE IF NOT EXISTS %@ (trackId INTEGER PRIMARY KEY, \
                                                     countryCode VARCHAR(2), \
                                                     info TEXT \
                                                     );";
    sql = [NSString stringWithFormat:sql, kTrackInfoTable];    
    [self execute:sql];
    
    sql = @"CREATE TABLE IF NOT EXISTS %@ (databaseId INTEGER PRIMARY KEY, \
                                           trackId INTEGER);";
    sql = [NSString stringWithFormat:sql, kFileTrackIdTable];
    [self execute:sql];
}

- (BOOL)execute:(NSString *)query {
    char *error;
    
    const char *sql = [query UTF8String];
    if (sqlite3_exec(self.database, sql, NULL, NULL, &error) == SQLITE_OK) {
        return YES;
    } else {
        NSLog(@"Error: %s", error);
        return NO;
    }
}

- (NSArray *)executeOne:(NSString *)query {
    sqlite3_stmt *statement = nil;
    const char *sql = [query UTF8String];
    if (sqlite3_prepare_v2(self.database, sql, -1, &statement, NULL) != SQLITE_OK) {
        NSLog(@"[SQLITE] Error when preparing query!");
    } else {
        
        NSMutableArray *result;
        
        if (sqlite3_step(statement) == SQLITE_ROW) {
            int colCount = sqlite3_column_count(statement);
            result = [NSMutableArray arrayWithCapacity:colCount];
            
            for (int i = 0; i < colCount; i++) {
                int colType = sqlite3_column_type(statement, i);
                id value;
                if (colType == SQLITE_TEXT) {
                    value = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, i)];
                } else if (colType == SQLITE_INTEGER) {
                    int col = sqlite3_column_int(statement, i);
                    value = [NSNumber numberWithInt:col];
                } else if (colType == SQLITE_FLOAT) {
                    double col = sqlite3_column_double(statement, i);
                    value = [NSNumber numberWithDouble:col];
                } else if (colType == SQLITE_NULL) {
                    value = [NSNull null];
                } else {
                    NSLog(@"[SQLITE] UNKNOWN DATATYPE");
                }
                
                [result addObject:value];
            }
            
        }
        sqlite3_finalize(statement);
        
        return result;
    }
    return nil;
}

+ (NSMutableDictionary *)decodeJsonData:(NSString *)jsonString {
    
    if (jsonString == nil) {
        NSLog(@"[%@ %@] JSON error: %@",
              NSStringFromClass([self class]),
              NSStringFromSelector(_cmd),
              @"Json data was nil");
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    
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

+ (NSString *)encodeJsonData:(id)object {
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    if (error) {
        NSLog(@"[%@ %@] JSON error: %@",
              NSStringFromClass([self class]),
              NSStringFromSelector(_cmd),
              error.localizedDescription);
        return nil;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:data
                                                 encoding:NSUTF8StringEncoding];
    
    return jsonString;
}

- (NSDictionary *)trackInfo:(NSInteger)trackId {
    NSString *sql = [NSString stringWithFormat:@"SELECT info FROM trackInfo WHERE trackId = %li;", trackId];
    
    NSArray *row = [self executeOne:sql];
    if (row == nil) {
        return nil;
    }
    
    return [LocalCache decodeJsonData:row[0]];
}

- (void)addTrackInfo:(NSInteger)trackId countryCode:(NSString *)countryCode info:(NSDictionary *)info {
    sqlite3_stmt *stmt = nil;
    
    const char *sql = "REPLACE INTO trackInfo (trackId, countryCode, info) Values(?, ?, ?)";
    if (sqlite3_prepare_v2(self.database, sql, -1, &stmt, NULL) != SQLITE_OK) {
        NSLog(@"Error creating statement");
        return;
    }
    
    NSAssert([countryCode length] == 2, @"Country codes should be 2 characters");
    
    sqlite3_bind_int64(stmt, 1, trackId);
    sqlite3_bind_text(stmt, 2, [countryCode UTF8String], -1, SQLITE_TRANSIENT);
    
    NSMutableDictionary *mutableInfo = [info mutableCopy];
    [mutableInfo removeObjectForKey:@"releaseDate"];    
    NSString *infoString = [LocalCache encodeJsonData:mutableInfo];
    sqlite3_bind_text(stmt, 3, [infoString UTF8String], -1, SQLITE_TRANSIENT);
    
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        NSLog(@"Error inserting data");
    }
    
    sqlite3_finalize(stmt);
}

- (NSUInteger)trackIdForDatabaseId:(NSUInteger)databaseID {
    NSString *sql = [NSString stringWithFormat:@"SELECT trackId FROM fileTrackIds WHERE databaseId = %lu;", databaseID];
    
    NSArray *row = [self executeOne:sql];
    if (row == nil) {
        return 0;
    }
    
    return [row[0] integerValue];
}

- (void)addTrackId:(NSUInteger)trackId toDatabaseId:(NSUInteger)databaseID {
    sqlite3_stmt *stmt = nil;
    
    const char *sql = "REPLACE INTO fileTrackIds (databaseId, trackId) Values(?, ?)";
    if (sqlite3_prepare_v2(self.database, sql, -1, &stmt, NULL) != SQLITE_OK) {
        NSLog(@"Error creating statement");
        return;
    }
    
    sqlite3_bind_int64(stmt, 1, databaseID);
    sqlite3_bind_int64(stmt, 2, trackId);
    
    if (sqlite3_step(stmt) != SQLITE_DONE) {
        NSLog(@"Error inserting data");
    }
    
    sqlite3_finalize(stmt);
}

@end
