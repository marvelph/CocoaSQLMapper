//
//  SMBindParameter.h
//  CocoaSQLMapper
//
//  Copyright 2010-2011 Kenji Nishishiro. All rights reserved.
//  Written by Kenji Nishishiro <marvel@programmershigh.org>.
//

#import <Foundation/Foundation.h>

@interface SMBindParameter : NSObject

@property (nonatomic) int index;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *type;

@end
