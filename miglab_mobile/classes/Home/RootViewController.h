//
//  RootViewController.h
//  miglab_mobile
//
//  Created by pig on 13-8-17.
//  Copyright (c) 2013年 pig. All rights reserved.
//

#import "BaseViewController.h"
#import "RootNavigationMenuView.h"
#import "MigLabAPI.h"

@interface RootViewController : BaseViewController

//启动图标志
@property (assign) BOOL isFirstWillAppear;
@property (assign) BOOL isFirstDidAppear;

@property (nonatomic, retain) RootNavigationMenuView *rootNavMenuView;
@property (nonatomic, retain) NSMutableDictionary *dicViewControllerCache;
@property (nonatomic, assign) int currentShowViewTag;

@property (nonatomic, retain) MigLabAPI *miglabAPI;

-(IBAction)segmentAction:(id)sender;
-(UIViewController *)getControllerBySegIndex:(int)segindex;

@end
