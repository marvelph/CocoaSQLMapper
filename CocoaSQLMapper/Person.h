//
//  Person.h
//  CocoaSQLMapper
//
//  Copyright 2010-2012 Kenji Nishishiro. All rights reserved.
//  Written by Kenji Nishishiro <marvel@programmershigh.org>.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject

@property (nonatomic) long long key;
@property (nonatomic) NSString *name;
@property (nonatomic) NSNumber *age;
@property (nonatomic) NSDate *dateOfBirth;
@property (nonatomic) BOOL married;

@end
