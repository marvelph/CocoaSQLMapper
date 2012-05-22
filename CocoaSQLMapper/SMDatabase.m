//
//  SMDatabase.m
//  CocoaSQLMapper
//
//  Copyright 2010-2012 Kenji Nishishiro. All rights reserved.
//  Written by Kenji Nishishiro <marvel@programmershigh.org>.
//

#import "SMDatabase.h"

#import <sqlite3.h>
#import <objc/runtime.h>

NSString *const SMDatabaseErrorDomain = @"SMDatabaseErrorDomain";

@interface SMBindParameter : NSObject

@property (nonatomic) int index;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *type;

@end

@implementation SMBindParameter

@synthesize index = _index;
@synthesize name = _name;
@synthesize type = _type;

@end

@interface SMColumn : NSObject

@property (nonatomic) int index;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *type;

@end

@implementation SMColumn

@synthesize index = _index;
@synthesize name = _name;
@synthesize type = _type;

@end

@implementation SMDatabase {
    sqlite3 *_sqlite;
}

- (id)initWithPath:(NSString *)path error:(NSError **)error
{
    NSParameterAssert(path);
    
    if (self = [super init]) {
        if (sqlite3_open([path UTF8String], &_sqlite) != SQLITE_OK) {
            if (error) {
                *error = [self errorWithLastSQLiteError];
            }
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    sqlite3_close(_sqlite);
}

- (id)selectObjectBySQL:(NSString *)SQL parameter:(id)parameter resultClass:(Class)resultClass error:(NSError **)error
{
    NSParameterAssert(SQL);
    NSParameterAssert(resultClass);
    
    sqlite3_stmt *statement = [self prepareSQL:SQL error:error];
    if (!statement) {
        return nil;
    }
    
    @try {
        if (parameter) {
            if (![self bindStatement:statement parameter:parameter error:error]) {
                return nil;
            }
        }
        
        __block id result = nil;
        if (![self fetchStatement:statement block:^BOOL(id rst, NSError **err) {
            NSAssert(!result, @"Multiple result rows.");
            
            result = rst;
            return YES;
        } resultClass:resultClass error:error]) {
            return nil;
        }
        
        return result;
    }
    @finally {
        sqlite3_finalize(statement);
    }
}

- (NSArray *)selectArrayBySQL:(NSString *)SQL parameter:(id)parameter resultClass:(Class)resultClass error:(NSError **)error
{
    NSParameterAssert(SQL);
    NSParameterAssert(resultClass);
    
    sqlite3_stmt *statement = [self prepareSQL:SQL error:error];
    if (!statement) {
        return nil;
    }
    
    @try {
        if (parameter) {
            if (![self bindStatement:statement parameter:parameter error:error]) {
                return nil;
            }
        }
        
        NSMutableArray* results = [NSMutableArray array];
        if (![self fetchStatement:statement block:^BOOL(id rst, NSError **err) {
            [results addObject:rst];
            return YES;
        } resultClass:resultClass error:error]) {
            return nil;
        }
        return results;
    }
    @finally {
        sqlite3_finalize(statement);
    }
}

- (BOOL)selectWithBlock:(BOOL (^)(id result, NSError **err))block bySQL:(NSString *)SQL parameter:(id)parameter resultClass:(Class)resultClass error:(NSError **)error
{
    NSParameterAssert(SQL);
    NSParameterAssert(resultClass);
    
    sqlite3_stmt *statement = [self prepareSQL:SQL error:error];
    if (!statement) {
        return NO;
    }
    
    @try {
        if (parameter) {
            if (![self bindStatement:statement parameter:parameter error:error]) {
                return NO;
            }
        }
        
        return [self fetchStatement:statement block:block resultClass:resultClass error:error];
    }
    @finally {
        sqlite3_finalize(statement);
    }
}

- (long long int)insertBySQL:(NSString *)SQL parameter:(id)parameter error:(NSError **)error
{
    if (![self executeBySQL:SQL parameter:parameter error:error]) {
        return 0;
    }
    return sqlite3_last_insert_rowid(_sqlite);
}

- (int)updateBySQL:(NSString *)SQL parameter:(id)parameter error:(NSError **)error
{
    if (![self executeBySQL:SQL parameter:parameter error:error]) {
        return 0;
    }
    return sqlite3_changes(_sqlite);
}

- (int)deleteBySQL:(NSString *)SQL parameter:(id)parameter error:(NSError **)error
{
    if (![self executeBySQL:SQL parameter:parameter error:error]) {
        return 0;
    }
    return sqlite3_changes(_sqlite);
}

- (BOOL)executeBySQL:(NSString *)SQL parameter:(id)parameter error:(NSError **)error
{
    NSParameterAssert(SQL);
    
    sqlite3_stmt *statement = [self prepareSQL:SQL error:error];
    if (!statement) {
        return NO;
    }
    
    @try {
        if (parameter) {
            if (![self bindStatement:statement parameter:parameter error:error]) {
                return NO;
            }
        }
        
        return [self executeStatement:statement error:error];
    }
    @finally {
        sqlite3_finalize(statement);
    }
}

- (BOOL)transactionWithBlock:(BOOL (^)(NSError **err))block error:(NSError **)error
{
    if (![self executeBySQL:@"BEGIN TRANSACTION" parameter:nil error:error]) {
        return NO;
    }
    
    if (block(error)) {
        return [self executeBySQL:@"COMMIT TRANSACTION" parameter:nil error:error];
    }
    else {
        [self executeBySQL:@"ROLLBACK TRANSACTION" parameter:nil error:error];
        return NO;
    }
}

- (NSError *)errorWithLastSQLiteError
{
    NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(_sqlite)];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:SMDatabaseErrorDomain code:sqlite3_errcode(_sqlite) userInfo:userInfo];
}

- (sqlite3_stmt *)prepareSQL:(NSString *)SQL error:(NSError **)error
{
    sqlite3_stmt *statement;
    if (sqlite3_prepare(_sqlite, [SQL UTF8String], -1, &statement, NULL) != SQLITE_OK) {
        if (error) {
            *error = [self errorWithLastSQLiteError];
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
        int error_code = SQLITE_OK;
        if ([@"i" isEqual:bindParameter.type]) {
            NSNumber *number = [parameter valueForKey:bindParameter.name];
            error_code = sqlite3_bind_int(statement, bindParameter.index, [number intValue]);
        }
        else if ([@"q" isEqual:bindParameter.type]) {
            NSNumber *number = [parameter valueForKey:bindParameter.name];
            error_code = sqlite3_bind_int64(statement, bindParameter.index, [number longLongValue]);
        }
        else if ([@"c" isEqual:bindParameter.type]) {
            NSNumber *number = [parameter valueForKey:bindParameter.name];
            error_code = sqlite3_bind_int(statement, bindParameter.index, [number boolValue]);
        }
        else if ([@"f" isEqual:bindParameter.type]) {
            NSNumber *number = [parameter valueForKey:bindParameter.name];
            error_code = sqlite3_bind_double(statement, bindParameter.index, [number floatValue]);
        }
        else if ([@"d" isEqual:bindParameter.type]) {
            NSNumber *number = [parameter valueForKey:bindParameter.name];
            error_code = sqlite3_bind_double(statement, bindParameter.index, [number doubleValue]);
        }
        else if ([@"@\"NSNumber\"" isEqual:bindParameter.type]) {
            NSNumber *number = [parameter valueForKey:bindParameter.name];
            if (number) {
                switch (*[number objCType]) {
                    case 'i':
                        error_code = sqlite3_bind_int(statement, bindParameter.index, [number intValue]);
                        break;
                    case 'q':
                        error_code = sqlite3_bind_int64(statement, bindParameter.index, [number longLongValue]);
                        break;
                    case 'c':
                        error_code = sqlite3_bind_int(statement, bindParameter.index, [number boolValue]);
                        break;
                    case 'f':
                        error_code = sqlite3_bind_double(statement, bindParameter.index, [number floatValue]);
                        break;
                    case 'd':
                        error_code = sqlite3_bind_double(statement, bindParameter.index, [number doubleValue]);
                        break;
                }
            }
            else {
                error_code = sqlite3_bind_null(statement, bindParameter.index);
            }
        }
        else if ([@"@\"NSDate\"" isEqual:bindParameter.type]) {
            NSDate *date = [parameter valueForKey:bindParameter.name];
            if (date) {
                error_code = sqlite3_bind_double(statement, bindParameter.index, [date timeIntervalSince1970]);
            }
            else {
                error_code = sqlite3_bind_null(statement, bindParameter.index);
            }
        }
        else if ([@"@\"NSString\"" isEqual:bindParameter.type]) {
            NSString *string = [parameter valueForKey:bindParameter.name];
            if (string) {
                error_code = sqlite3_bind_text(statement, bindParameter.index, [string UTF8String], -1, SQLITE_TRANSIENT);
            }
            else {
                error_code = sqlite3_bind_null(statement, bindParameter.index);
            }
        }
        else if ([@"@\"NSData\"" isEqual:bindParameter.type]) {
            NSData *data = [parameter valueForKey:bindParameter.name];
            if (data) {
                error_code = sqlite3_bind_blob(statement, bindParameter.index, [data bytes], (int)[data length], SQLITE_TRANSIENT);
            }
            else {
                error_code = sqlite3_bind_null(statement, bindParameter.index);
            }
        }
        if (error_code != SQLITE_OK) {
            if (error) {
                *error = [self errorWithLastSQLiteError];
            }
            return NO;
        }
    }
    return YES;
}

- (BOOL)fetchStatement:(sqlite3_stmt *)statement block:(BOOL (^)(id rst, NSError **err))block resultClass:(Class)resultClass error:(NSError **)error
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
    
    int status;
    id result;
    while ((status = sqlite3_step(statement)) != SQLITE_DONE) {
        switch (status) {
            case SQLITE_BUSY:
                break;
            case SQLITE_ROW:
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
                    else if ([@"@\"NSNumber\"" isEqual:column.type]) {
                        switch (sqlite3_column_type(statement, column.index)) {
                            case SQLITE_INTEGER: {
                                long long value = sqlite3_column_int64(statement, column.index);
                                NSNumber *number = [NSNumber numberWithLongLong:value];
                                [result setValue:number forKey:column.name];
                                break;
                            }
                            case SQLITE_FLOAT: {
                                double value = sqlite3_column_double(statement, column.index);
                                NSNumber *number = [NSNumber numberWithDouble:value];
                                [result setValue:number forKey:column.name];
                            }
                            case SQLITE_NULL:
                                [result setValue:nil forKey:column.name];
                                break;
                            default: {
                                int value = sqlite3_column_int(statement, column.index);
                                NSNumber *number = [NSNumber numberWithInt:value];
                                [result setValue:number forKey:column.name];
                            }
                        }
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
                if (!block(result, error)) {
                    return NO;
                }
                break;
            case SQLITE_ERROR:
                if (error) {
                    *error = [self errorWithLastSQLiteError];
                }
                return NO;
            case SQLITE_MISUSE:
                NSAssert(NO, @"Database misused.");
                break;
        }
    }
    return YES;
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
                    *error = [self errorWithLastSQLiteError];
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
