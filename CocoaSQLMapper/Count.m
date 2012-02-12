//
//  Count.m
//  CocoaSQLMapper
//
//  Copyright 2010-2012 Kenji Nishishiro. All rights reserved.
//  Written by Kenji Nishishiro <marvel@programmershigh.org>.
//

#import "Count.h"

@implementation Count

@synthesize value = _value;

- (NSString *)description {
	return [NSString stringWithFormat:@"value=%i", _value];
}

@end
