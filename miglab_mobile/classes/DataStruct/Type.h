//
//  Type.h
//  miglab_mobile
//
//  Created by pig on 13-8-18.
//  Copyright (c) 2013年 pig. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Type : NSObject

@property (nonatomic, assign) int typeid;
@property (nonatomic, retain) NSString *name;

//类别
+(id)initWithNSDictionary:(NSDictionary*)dict;
-(void)log;

@end
