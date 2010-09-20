//
//  SMDatabase.h
//  CocoaSQLMapper
//
//  Created by Kenji Nishishiro <marvel@programmershigh.org> on 10/09/19.
//  Copyright 2010 Kenji Nishishiro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

NSString *const SMDatabaseErrorDomain;

@interface SMDatabase : NSObject {
	sqlite3 *sqlite3_;
}

- (id)initWithPath:(NSString *)path error:(NSError **)error;
- (void)close;

- (id)queryObjectBySQL:(NSString *)sql parameter:(id)parameter resultClass:(Class)resultClass error:(NSError **)error;
- (NSArray *)queryArrayBySQL:(NSString *)sql parameter:(id)parameter resultClass:(Class)resultClass error:(NSError **)error;
- (long long)insertBySQL:(NSString *)sql parameter:(id)parameter error:(NSError **)error;
- (int)updateBySQL:(NSString *)sql parameter:(id)parameter error:(NSError **)error;
- (int)deleteBySQL:(NSString *)sql parameter:(id)parameter error:(NSError **)error;

@end
