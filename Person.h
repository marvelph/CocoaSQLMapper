//
//  Person.h
//  CocoaSQLMapper
//
//  Created by Kenji Nishishiro <marvel@programmershigh.org> on 10/09/19.
//  Copyright 2010 Kenji Nishishiro. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Person : NSObject {
	NSInteger key_;
	NSString *name_;
	NSInteger age_;
	NSDate *dateOfBirth_;
}

@property (nonatomic) NSInteger key;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSInteger age;
@property (nonatomic, copy) NSDate *dateOfBirth;

@end
