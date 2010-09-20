//
//  Person.m
//  CocoaSQLMapper
//
//  Created by Kenji Nishishiro <marvel@programmershigh.org> on 10/09/19.
//  Copyright 2010 Kenji Nishishiro. All rights reserved.
//

#import "Person.h"

@implementation Person

@synthesize key = key_;
@synthesize name = name_;
@synthesize age = age_;
@synthesize dateOfBirth = dateOfBirth_;

- (void)dealloc {
	[name_ release];
	[dateOfBirth_ release];
	[super dealloc];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"key=%ld, name=%@, age=%ld, dateOfBirth=%@", (long)key_, name_, (long)age_, dateOfBirth_];
}

@end
