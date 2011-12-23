//
//  Person.m
//  CocoaSQLMapper
//
//  Copyright 2010-2011 Kenji Nishishiro. All rights reserved.
//  Written by Kenji Nishishiro <marvel@programmershigh.org>.
//

#import "Person.h"

@implementation Person

@synthesize key = _key;
@synthesize name = _name;
@synthesize age = _age;
@synthesize dateOfBirth = _dateOfBirth;
@synthesize married = _married;

- (NSString *)description {
	return [NSString stringWithFormat:@"key=%qi, name=%@, age=%@, dateOfBirth=%@, married=%i", _key, _name, _age, _dateOfBirth, _married];
}

@end
