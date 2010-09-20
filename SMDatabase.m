//
//  SMDatabase.m
//  CocoaSQLMapper
//
//  Created by Kenji Nishishiro <marvel@programmershigh.org> on 10/09/19.
//  Copyright 2010 Kenji Nishishiro. All rights reserved.
//

#import "SMDatabase.h"
#import "SMBindParameter.h"
#import "SMColumn.h"
#import <objc/objc-runtime.h>

NSString *const SMDatabaseErrorDomain = @"SMDatabaseErrorDomain";

@implementation SMDatabase

- (id)initWithPath:(NSString *)path error:(NSError **)error {
	NSParameterAssert(path);
	
	if (self = [super init]) {
		if (sqlite3_open([path UTF8String], &sqlite3_) != SQLITE_OK) {
			if (error) {
				NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
				NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																 forKey:NSLocalizedDescriptionKey];
				*error = [NSError errorWithDomain:SMDatabaseErrorDomain
											 code:sqlite3_errcode(sqlite3_)
										 userInfo:userInfo];
			}
			
			sqlite3_close(sqlite3_);
			sqlite3_ = NULL;
		}
	}
	return self;
}

- (void)close {
	NSAssert(sqlite3_, @"Database already closed.");
	
	sqlite3_close(sqlite3_);
	sqlite3_ = NULL;
}

- (id)queryObjectBySQL:(NSString *)sql
			 parameter:(id)parameter
		   resultClass:(Class)resultClass
				 error:(NSError **)error {
	NSAssert(sqlite3_, @"Database already closed.");
	NSParameterAssert(sql);
	NSParameterAssert(resultClass);
	
	sqlite3_stmt *statement;
	if (sqlite3_prepare(sqlite3_, [sql UTF8String], -1, &statement, NULL) != SQLITE_OK) {
		if (error) {
			NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
															 forKey:NSLocalizedDescriptionKey];
			*error = [NSError errorWithDomain:SMDatabaseErrorDomain
										 code:sqlite3_errcode(sqlite3_)
									 userInfo:userInfo];
		}
		return nil;
	}
	
	if (parameter) {
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
					
					SMBindParameter *bindParameter = [[[SMBindParameter alloc] init] autorelease];
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
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"q" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_int64(statement, bindParameter.index, [number longLongValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"c" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_int(statement, bindParameter.index, [number boolValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"f" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_double(statement, bindParameter.index, [number floatValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"d" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_double(statement, bindParameter.index, [number doubleValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"@\"NSDate\"" isEqual:bindParameter.type]) {
				NSDate *date = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_double(statement, bindParameter.index, [date timeIntervalSince1970]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"@\"NSString\"" isEqual:bindParameter.type]) {
				NSString *string = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_text(statement, bindParameter.index, [string UTF8String], -1, SQLITE_TRANSIENT) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"@\"NSData\"" isEqual:bindParameter.type]) {
				NSData *data = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_blob(statement, bindParameter.index, [data bytes], [data length], SQLITE_TRANSIENT) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
		}
	}
	
	NSMutableArray *columns = [NSMutableArray array];
	int numberOfColumns = sqlite3_column_count(statement);
	for (int index = 0; index < numberOfColumns; index++) {
		NSString *name = [NSString stringWithUTF8String:sqlite3_column_name(statement, index)];
		objc_property_t property = class_getProperty(resultClass, [name UTF8String]);
		if (property) {
			NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(property)];
			NSRange range = [attributes rangeOfString:@","];
			NSString *type = [attributes substringWithRange:NSMakeRange(1, range.location - 1)];
			
			SMColumn *column = [[[SMColumn alloc] init] autorelease];
			column.index = index;
			column.name = name;
			column.type = type;
			[columns addObject:column];
		}
	}
	
	id result = nil;
	int status;
	while ((status = sqlite3_step(statement)) != SQLITE_DONE) {
		switch (status) {
			case SQLITE_BUSY:
				break;
			case SQLITE_ROW:
				NSAssert(!result, @"Multiple result rows.");
				
				result = [[[resultClass alloc] init] autorelease];
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
						NSTimeInterval value = sqlite3_column_double(statement, column.index);
						NSDate *date = [NSDate dateWithTimeIntervalSince1970:value];
						[result setValue:date forKey:column.name];
					}
					else if ([@"@\"NSString\"" isEqual:column.type]) {
						const char *value = (const char *)sqlite3_column_text(statement, column.index);
						if (value) {
							NSString *string = [NSString stringWithUTF8String:value];
							[result setValue:string forKey:column.name];
						}
					}
					else if ([@"@\"NSData\"" isEqual:column.type]) {
						const void *value = sqlite3_column_blob(statement, column.index);
						if (value) {
							int length = sqlite3_column_bytes(statement, column.index);
							NSData *data = [NSData dataWithBytes:value length:length];
							[result setValue:data forKey:column.name];
						}
					}
				}
				break;
			case SQLITE_ERROR:
				if (error) {
					NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
					NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																	 forKey:NSLocalizedDescriptionKey];
					*error = [NSError errorWithDomain:SMDatabaseErrorDomain
												 code:sqlite3_errcode(sqlite3_)
											 userInfo:userInfo];
				}
				
				sqlite3_finalize(statement);
				return result;
			case SQLITE_MISUSE:
				NSAssert(NO, @"Database misused.");
				break;
		}
	}
	sqlite3_finalize(statement);
	return result;
}

- (NSArray *)queryArrayBySQL:(NSString *)sql
				   parameter:(id)parameter
				 resultClass:(Class)resultClass
					   error:(NSError **)error {
	NSAssert(sqlite3_, @"Database already closed.");
	NSParameterAssert(sql);
	NSParameterAssert(resultClass);
	
	sqlite3_stmt *statement;
	if (sqlite3_prepare(sqlite3_, [sql UTF8String], -1, &statement, NULL) != SQLITE_OK) {
		if (error) {
			NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																 forKey:NSLocalizedDescriptionKey];
			*error = [NSError errorWithDomain:SMDatabaseErrorDomain
										 code:sqlite3_errcode(sqlite3_)
									 userInfo:userInfo];
		}
		return nil;
	}
	
	if (parameter) {
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
					
					SMBindParameter *bindParameter = [[[SMBindParameter alloc] init] autorelease];
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
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"q" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_int64(statement, bindParameter.index, [number longLongValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"c" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_int(statement, bindParameter.index, [number boolValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"f" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_double(statement, bindParameter.index, [number floatValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"d" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_double(statement, bindParameter.index, [number doubleValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"@\"NSDate\"" isEqual:bindParameter.type]) {
				NSDate *date = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_double(statement, bindParameter.index, [date timeIntervalSince1970]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"@\"NSString\"" isEqual:bindParameter.type]) {
				NSString *string = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_text(statement, bindParameter.index, [string UTF8String], -1, SQLITE_TRANSIENT) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"@\"NSData\"" isEqual:bindParameter.type]) {
				NSData *data = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_blob(statement, bindParameter.index, [data bytes], [data length], SQLITE_TRANSIENT) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
		}
	}
	
	NSMutableArray *columns = [NSMutableArray array];
	int numberOfColumns = sqlite3_column_count(statement);
	for (int index = 0; index < numberOfColumns; index++) {
		NSString *name = [NSString stringWithUTF8String:sqlite3_column_name(statement, index)];
		objc_property_t property = class_getProperty(resultClass, [name UTF8String]);
		if (property) {
			NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(property)];
			NSRange range = [attributes rangeOfString:@","];
			NSString *type = [attributes substringWithRange:NSMakeRange(1, range.location - 1)];
			
			SMColumn *column = [[[SMColumn alloc] init] autorelease];
			column.index = index;
			column.name = name;
			column.type = type;
			[columns addObject:column];
		}
	}
	
	NSMutableArray* results = [NSMutableArray array];
	int status;
	while ((status = sqlite3_step(statement)) != SQLITE_DONE) {
		switch (status) {
			case SQLITE_BUSY:
				break;
			case SQLITE_ROW:
				;
				id result = [[[resultClass alloc] init] autorelease];
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
						NSTimeInterval value = sqlite3_column_double(statement, column.index);
						NSDate *date = [NSDate dateWithTimeIntervalSince1970:value];
						[result setValue:date forKey:column.name];
					}
					else if ([@"@\"NSString\"" isEqual:column.type]) {
						const char *value = (const char *)sqlite3_column_text(statement, column.index);
						if (value) {
							NSString *string = [NSString stringWithUTF8String:value];
							[result setValue:string forKey:column.name];
						}
					}
					else if ([@"@\"NSData\"" isEqual:column.type]) {
						const void *value = sqlite3_column_blob(statement, column.index);
						if (value) {
							int length = sqlite3_column_bytes(statement, column.index);
							NSData *data = [NSData dataWithBytes:value length:length];
							[result setValue:data forKey:column.name];
						}
					}
				}
				[results addObject:result];
				break;
			case SQLITE_ERROR:
				if (error) {
					NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
					NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																		 forKey:NSLocalizedDescriptionKey];
					*error = [NSError errorWithDomain:SMDatabaseErrorDomain
												 code:sqlite3_errcode(sqlite3_)
											 userInfo:userInfo];
				}
				
				sqlite3_finalize(statement);
				return results;
			case SQLITE_MISUSE:
				NSAssert(NO, @"Database misused.");
				break;
		}
	}
	sqlite3_finalize(statement);
	return results;
}

- (long long)insertBySQL:(NSString *)sql
			   parameter:(id)parameter
				   error:(NSError **)error {
	NSAssert(sqlite3_, @"Database already closed.");
	NSParameterAssert(sql);
	
	sqlite3_stmt *statement;
	if (sqlite3_prepare(sqlite3_, [sql UTF8String], -1, &statement, NULL) != SQLITE_OK) {
		if (error) {
			NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																 forKey:NSLocalizedDescriptionKey];
			*error = [NSError errorWithDomain:SMDatabaseErrorDomain
										 code:sqlite3_errcode(sqlite3_)
									 userInfo:userInfo];
		}
		return 0;
	}
	
	if (parameter) {
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
					
					SMBindParameter *bindParameter = [[[SMBindParameter alloc] init] autorelease];
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
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"q" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_int64(statement, bindParameter.index, [number longLongValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"c" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_int(statement, bindParameter.index, [number boolValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"f" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_double(statement, bindParameter.index, [number floatValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"d" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_double(statement, bindParameter.index, [number doubleValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"@\"NSDate\"" isEqual:bindParameter.type]) {
				NSDate *date = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_double(statement, bindParameter.index, [date timeIntervalSince1970]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"@\"NSString\"" isEqual:bindParameter.type]) {
				NSString *string = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_text(statement, bindParameter.index, [string UTF8String], -1, SQLITE_TRANSIENT) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"@\"NSData\"" isEqual:bindParameter.type]) {
				NSData *data = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_blob(statement, bindParameter.index, [data bytes], [data length], SQLITE_TRANSIENT) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
		}
	}
	
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
					NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
					NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																		 forKey:NSLocalizedDescriptionKey];
					*error = [NSError errorWithDomain:SMDatabaseErrorDomain
												 code:sqlite3_errcode(sqlite3_)
											 userInfo:userInfo];
				}
				
				sqlite3_finalize(statement);
				return 0;
			case SQLITE_MISUSE:
				NSAssert(NO, @"Database misused.");
				break;
		}
	}
	sqlite3_finalize(statement);
	return sqlite3_last_insert_rowid(sqlite3_);
}

- (int)updateBySQL:(NSString *)sql
		 parameter:(id)parameter
			 error:(NSError **)error {
	NSAssert(sqlite3_, @"Database already closed.");
	NSParameterAssert(sql);
	
	sqlite3_stmt *statement;
	if (sqlite3_prepare(sqlite3_, [sql UTF8String], -1, &statement, NULL) != SQLITE_OK) {
		if (error) {
			NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
			NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																 forKey:NSLocalizedDescriptionKey];
			*error = [NSError errorWithDomain:SMDatabaseErrorDomain
										 code:sqlite3_errcode(sqlite3_)
									 userInfo:userInfo];
		}
		return 0;
	}
	
	if (parameter) {
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
					
					SMBindParameter *bindParameter = [[[SMBindParameter alloc] init] autorelease];
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
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"q" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_int64(statement, bindParameter.index, [number longLongValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"c" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_int(statement, bindParameter.index, [number boolValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"f" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_double(statement, bindParameter.index, [number floatValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"d" isEqual:bindParameter.type]) {
				NSNumber *number = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_double(statement, bindParameter.index, [number doubleValue]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"@\"NSDate\"" isEqual:bindParameter.type]) {
				NSDate *date = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_double(statement, bindParameter.index, [date timeIntervalSince1970]) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"@\"NSString\"" isEqual:bindParameter.type]) {
				NSString *string = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_text(statement, bindParameter.index, [string UTF8String], -1, SQLITE_TRANSIENT) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
			else if ([@"@\"NSData\"" isEqual:bindParameter.type]) {
				NSData *data = [parameter valueForKey:bindParameter.name];
				if (sqlite3_bind_blob(statement, bindParameter.index, [data bytes], [data length], SQLITE_TRANSIENT) != SQLITE_OK) {
					if (error) {
						NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
						NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																			 forKey:NSLocalizedDescriptionKey];
						*error = [NSError errorWithDomain:SMDatabaseErrorDomain
													 code:sqlite3_errcode(sqlite3_)
												 userInfo:userInfo];
					}
					
					sqlite3_finalize(statement);
				}
			}
		}
	}
	
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
					NSString *description = [NSString stringWithUTF8String:sqlite3_errmsg(sqlite3_)];
					NSDictionary *userInfo = [NSDictionary dictionaryWithObject:description
																		 forKey:NSLocalizedDescriptionKey];
					*error = [NSError errorWithDomain:SMDatabaseErrorDomain
												 code:sqlite3_errcode(sqlite3_)
											 userInfo:userInfo];
				}
				
				sqlite3_finalize(statement);
				return 0;
			case SQLITE_MISUSE:
				NSAssert(NO, @"Database misused.");
				break;
		}
	}
	sqlite3_finalize(statement);
	return sqlite3_changes(sqlite3_);
}

- (int)deleteBySQL:(NSString *)sql
		 parameter:(id)parameter
			 error:(NSError **)error {
	return [self updateBySQL:sql parameter:parameter error:error];
}

@end
