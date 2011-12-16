//
//  SMColumn.h
//  CocoaSQLMapper
//
//  Copyright 2010-2011 Kenji Nishishiro. All rights reserved.
//  Written by Kenji Nishishiro <marvel@programmershigh.org>.
//

#import <Foundation/Foundation.h>

@interface SMColumn : NSObject

@property (nonatomic) int index;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *type;

@end
