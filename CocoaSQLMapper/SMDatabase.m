//
//  SMDatabase.m
//  CocoaSQLMapper
//
//  Copyright 2010-2011 Kenji Nishishiro. All rights reserved.
//  Written by Kenji Nishishiro <marvel@programmershigh.org>.
//

#import "SMDatabase.h"

#import "SMBindParameter.h"
#import "SMColumn.h"

#import <objc/runtime.h>

NSString *const SMDatabaseErrorDomain = @"SMDatabaseErrorDomain";

@interface SMDatabase ()

- (sqlite3_stmt *)prepareSQL:(NSString *)SQL error:(NSError **)error;
- (BOOL)bindStatement:(sqlite3_stmt *)statement parameter:(id)parameter error:(NSError **)error;
- (id)fetchStatement:(sqlite3_stmt *)statement resultClass:(Class)resultClass once:(BOOL)once error:(NSError **)error;
- (BOOL)executeStatement:(sqlite3_stmt *)statement error:(NSError **)error;

@end

@implementation SMDatabase

- (id)initWithPath:(NSString *)path error:(NSError **)error
{
    NSParameterAssert(path);
    
    if (self = [super init]) {
        if (sqlite3_open([path UTF8String], &_sqlite3) != SQLITE_OK) {
            if (error) {
                NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
            }
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    sqlite3_close(_sqlite3);
}

- (id)selectObjectBySQL:(NSString *)SQL parameter:(id)parameter resultClass:(Class)resultClass error:(NSError **)error
{
    NSParameterAssert(SQL);
    NSParameterAssert(resultClass);
    
    sqlite3_stmt *statement = [self prepareSQL:SQL error:error];
    if (!statement) {
        return nil;
    }
    
    if (parameter) {
        if (![self bindStatement:statement parameter:parameter error:error]) {
            return nil;
        }
    }
    
    id result = [self fetchStatement:statement resultClass:resultClass once:YES error:error];
    if (!result) {
        sqlite3_finalize(statement);
        return nil;
    }
    
    sqlite3_finalize(statement);
    return result;
}

- (NSArray *)selectArrayBySQL:(NSString *)SQL parameter:(id)parameter resultClass:(Class)resultClass error:(NSError **)error
{
    NSParameterAssert(SQL);
    NSParameterAssert(resultClass);
    
    sqlite3_stmt *statement = [self prepareSQL:SQL error:error];
    if (!statement) {
        return nil;
    }
    
    if (parameter) {
        if (![self bindStatement:statement parameter:parameter error:error]) {
            sqlite3_finalize(statement);
            return nil;
        }
    }
    
    NSArray* results = [self fetchStatement:statement resultClass:resultClass once:NO error:error];
    if (!results) {
        sqlite3_finalize(statement);
        return nil;
    }
    
    sqlite3_finalize(statement);
    return results;
}

- (long long)insertBySQL:(NSString *)SQL parameter:(id)parameter error:(NSError **)error
{
    if (![self executeBySQL:SQL parameter:parameter error:error]) {
        return 0;
    }
    return sqlite3_last_insert_rowid(_sqlite3);
}

- (int)updateBySQL:(NSString *)SQL parameter:(id)parameter error:(NSError **)error
{
    if (![self executeBySQL:SQL parameter:parameter error:error]) {
        return 0;
    }
    return sqlite3_changes(_sqlite3);
}

- (int)deleteBySQL:(NSString *)SQL parameter:(id)parameter error:(NSError **)error
{
    if (![self executeBySQL:SQL parameter:parameter error:error]) {
        return 0;
    }
    return sqlite3_changes(_sqlite3);
}

- (BOOL)executeBySQL:(NSString *)SQL parameter:(id)parameter error:(NSError **)error
{
    NSParameterAssert(SQL);
    
    sqlite3_stmt *statement = [self prepareSQL:SQL error:error];
    if (!statement) {
        return NO;
    }
    
    if (parameter) {
        if (![self bindStatement:statement parameter:parameter error:error]) {
            sqlite3_finalize(statement);
            return NO;
        }
    }
    
    if (![self executeStatement:statement error:error]) {
        sqlite3_finalize(statement);
        return NO;
    }
    
    sqlite3_finalize(statement);
    return YES;
}

- (sqlite3_stmt *)prepareSQL:(NSString *)SQL error:(NSError **)error
{
    sqlite3_stmt *statement;
    if (sqlite3_prepare(_sqlite3, [SQL UTF8String], -1, &statement, NULL) != SQLITE_OK) {
        if (error) {
            NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
        }
        return NULL;
    }
    return statement;
}

- (BOOL)bindStatement:(sqlite3_stmt *)statement parameter:(id)parameter error:(NSError **)error
{
    NSMutableArray *bindParameters = [NSMutableArray array];
    int numberOfBindParameters = sqlite3_bind_parameter_count(statement);
    for (int index = 1; index <= numberOfBindParameters; index++) {
        const char* nameAsCString = sqlite3_bind_parameter_name(statement, index);
        if (nameAsCString) {
            NSString *name = [NSString stringWithUTF8String:nameAsCString + 1];
            objc_property_t property = class_getProperty([parameter class], [name UTF8String]);
            if (property) {
                NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(property)];
                NSRange range = [attributes rangeOfString:@","];
                NSString *type = [attributes substringWithRange:NSMakeRange(1, range.location - 1)];
                
                SMBindParameter *bindParameter = [[SMBindParameter alloc] init];
                bindParameter.index = index;
                bindParameter.name = name;
                bindParameter.type = type;
                [bindParameters addObject:bindParameter];
            }
        }
    }
    
    for (SMBindParameter *bindParameter in bindParameters) {
        if ([@"i" isEqual:bindParameter.type]) {
            NSNumber *number = [parameter valueForKey:bindParameter.name];
            if (sqlite3_bind_int(statement, bindParameter.index, [number intValue]) != SQLITE_OK) {
                if (error) {
                    NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                    *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                }
                return NO;
            }
        }
        else if ([@"q" isEqual:bindParameter.type]) {
            NSNumber *number = [parameter valueForKey:bindParameter.name];
            if (sqlite3_bind_int64(statement, bindParameter.index, [number longLongValue]) != SQLITE_OK) {
                if (error) {
                    NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                    *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                }
                return NO;
            }
        }
        else if ([@"c" isEqual:bindParameter.type]) {
            NSNumber *number = [parameter valueForKey:bindParameter.name];
            if (sqlite3_bind_int(statement, bindParameter.index, [number boolValue]) != SQLITE_OK) {
                if (error) {
                    NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                    *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                }
                return NO;
            }
        }
        else if ([@"f" isEqual:bindParameter.type]) {
            NSNumber *number = [parameter valueForKey:bindParameter.name];
            if (sqlite3_bind_double(statement, bindParameter.index, [number floatValue]) != SQLITE_OK) {
                if (error) {
                    NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                    *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                }
                return NO;
            }
        }
        else if ([@"d" isEqual:bindParameter.type]) {
            NSNumber *number = [parameter valueForKey:bindParameter.name];
            if (sqlite3_bind_double(statement, bindParameter.index, [number doubleValue]) != SQLITE_OK) {
                if (error) {
                    NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                    *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                }
                return NO;
            }
        }
        else if ([@"@\"NSDate\"" isEqual:bindParameter.type]) {
            NSDate *date = [parameter valueForKey:bindParameter.name];
            if (date) {
                if (sqlite3_bind_double(statement, bindParameter.index, [date timeIntervalSince1970]) != SQLITE_OK) {
                    if (error) {
                        NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                        *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                    }
                    return NO;
                }
            }
            else {
                if (sqlite3_bind_null(statement, bindParameter.index) != SQLITE_OK) {
                    if (error) {
                        NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                        *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                    }
                    return NO;
                }
            }
        }
        else if ([@"@\"NSString\"" isEqual:bindParameter.type]) {
            NSString *string = [parameter valueForKey:bindParameter.name];
            if (string) {
                if (sqlite3_bind_text(statement, bindParameter.index, [string UTF8String], -1, SQLITE_TRANSIENT) != SQLITE_OK) {
                    if (error) {
                        NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                        *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                    }
                    return NO;
                }
            }
            else {
                if (sqlite3_bind_null(statement, bindParameter.index) != SQLITE_OK) {
                    if (error) {
                        NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                        *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                    }
                    return NO;
                }
            }
        }
        else if ([@"@\"NSData\"" isEqual:bindParameter.type]) {
            NSData *data = [parameter valueForKey:bindParameter.name];
            if (data) {
                if (sqlite3_bind_blob(statement, bindParameter.index, [data bytes], (int)[data length], SQLITE_TRANSIENT) != SQLITE_OK) {
                    if (error) {
                        NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                        *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                    }
                    return NO;
                }
            }
            else {
                if (sqlite3_bind_null(statement, bindParameter.index) != SQLITE_OK) {
                    if (error) {
                        NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                        *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                    }
                    return NO;
                }
            }
        }
    }
    return YES;
}

- (id)stepStatement:(sqlite3_stmt *)statement resultClass:(Class)resultClass once:(BOOL)once error:(NSError **)error
{
    NSMutableArray *columns = [NSMutableArray array];
    int numberOfColumns = sqlite3_column_count(statement);
    for (int index = 0; index < numberOfColumns; index++) {
        NSString *name = [NSString stringWithUTF8String:sqlite3_column_name(statement, index)];
        objc_property_t property = class_getProperty(resultClass, [name UTF8String]);
        if (property) {
            NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(property)];
            NSRange range = [attributes rangeOfString:@","];
            NSString *type = [attributes substringWithRange:NSMakeRange(1, range.location - 1)];
            
            SMColumn *column = [[SMColumn alloc] init];
            column.index = index;
            column.name = name;
            column.type = type;
            [columns addObject:column];
        }
    }
    
    id result = nil;
    NSMutableArray* results = [NSMutableArray array];
    int status;
    while ((status = sqlite3_step(statement)) != SQLITE_DONE) {
        switch (status) {
            case SQLITE_BUSY:
                break;
            case SQLITE_ROW:
                NSAssert(!(once && result), @"Multiple result rows.");
                
                result = [[resultClass alloc] init];
                for (SMColumn *column in columns) {
                    if ([@"i" isEqual:column.type]) {
                        int value = sqlite3_column_int(statement, column.index);
                        NSNumber *number = [NSNumber numberWithInt:value];
                        [result setValue:number forKey:column.name];
                    }
                    else if ([@"q" isEqual:column.type]) {
                        long long value = sqlite3_column_int64(statement, column.index);
                        NSNumber *number = [NSNumber numberWithLongLong:value];
                        [result setValue:number forKey:column.name];
                    }
                    else if ([@"c" isEqual:column.type]) {
                        BOOL value = sqlite3_column_int(statement, column.index);
                        NSNumber *number = [NSNumber numberWithBool:value];
                        [result setValue:number forKey:column.name];
                    }
                    else if ([@"f" isEqual:column.type]) {
                        float value = sqlite3_column_double(statement, column.index);
                        NSNumber *number = [NSNumber numberWithFloat:value];
                        [result setValue:number forKey:column.name];
                    }
                    else if ([@"d" isEqual:column.type]) {
                        double value = sqlite3_column_double(statement, column.index);
                        NSNumber *number = [NSNumber numberWithDouble:value];
                        [result setValue:number forKey:column.name];
                    }
                    else if ([@"@\"NSDate\"" isEqual:column.type]) {
                        if (sqlite3_column_type(statement, column.index) != SQLITE_NULL) {
                            NSTimeInterval value = sqlite3_column_double(statement, column.index);
                            NSDate *date = [NSDate dateWithTimeIntervalSince1970:value];
                            [result setValue:date forKey:column.name];
                        }
                        else {
                            [result setValue:nil forKey:column.name];
                        }
                    }
                    else if ([@"@\"NSString\"" isEqual:column.type]) {
                        if (sqlite3_column_type(statement, column.index) != SQLITE_NULL) {
                            const char *value = (const char *)sqlite3_column_text(statement, column.index);
                            if (value) {
                                NSString *string = [NSString stringWithUTF8String:value];
                                [result setValue:string forKey:column.name];
                            }
                        }
                        else {
                            [result setValue:nil forKey:column.name];
                        }
                    }
                    else if ([@"@\"NSData\"" isEqual:column.type]) {
                        if (sqlite3_column_type(statement, column.index) != SQLITE_NULL) {
                            const void *value = sqlite3_column_blob(statement, column.index);
                            if (value) {
                                int length = sqlite3_column_bytes(statement, column.index);
                                NSData *data = [NSData dataWithBytes:value length:length];
                                [result setValue:data forKey:column.name];
                            }
                        }
                        else {
                            [result setValue:nil forKey:column.name];
                        }
                    }
                }
                [results addObject:result];
                break;
            case SQLITE_ERROR:
                if (error) {
                    NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                    *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                }
                return nil;
            case SQLITE_MISUSE:
                NSAssert(NO, @"Database misused.");
                break;
        }
    }
    return once ? result : results;
}

- (BOOL)executeStatement:(sqlite3_stmt *)statement error:(NSError **)error
{
    int status;
    while ((status = sqlite3_step(statement)) != SQLITE_DONE) {
        switch (status) {
            case SQLITE_BUSY:
                break;
            case SQLITE_ROW:
                NSAssert(NO, @"Result rows.");
                break;
            case SQLITE_ERROR:
                if (error) {
                    NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite3)];
                    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
                    *error = [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite3) userInfo:userInfo];
                }
                return NO;
            case SQLITE_MISUSE:
                NSAssert(NO, @"Database misused.");
                break;
        }
    }
    return YES;
}

@end
