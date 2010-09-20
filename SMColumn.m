//
//  SMColumn.m
//  CocoaSQLMapper
//
//  Created by Kenji Nishishiro <marvel@programmershigh.org> on 10/09/19.
//  Copyright 2010 Kenji Nishishiro. All rights reserved.
//

#import "SMColumn.h"

@implementation SMColumn

@synthesize index = index_;
@synthesize name = name_;
@synthesize type = type_;

- (void)dealloc {
	[name_ release];
	[type_ release];
	[super dealloc];
}

@end
