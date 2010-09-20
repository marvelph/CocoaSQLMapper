//
//  SMColumn.h
//  CocoaSQLMapper
//
//  Created by Kenji Nishishiro <marvel@programmershigh.org> on 10/09/19.
//  Copyright 2010 Kenji Nishishiro. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMColumn : NSObject {
	int index_;
	NSString *name_;
	NSString *type_;
}

@property (nonatomic, assign) int index;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *type;

@end
