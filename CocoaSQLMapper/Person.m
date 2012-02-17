//
//  Person.m
//  CocoaSQLMapper
//
//  Copyright 2010-2012 Kenji Nishishiro. All rights reserved.
//  Written by Kenji Nishishiro <marvel@programmershigh.org>.
//

#import "Person.h"

@implementation Person

@synthesize key;
@synthesize name;
@synthesize age;
@synthesize dateOfBirth;
@synthesize married;

- (NSString *)description {
	return [NSString stringWithFormat:@"key=%qi, name=%@, age=%@, dateOfBirth=%@, married=%i", self.key, self.name, self.age, self.dateOfBirth, self.married];
}

@end
