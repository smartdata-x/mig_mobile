//
//  AppDelegate.h
//  miglab_mobile
//
//  Created by pig on 13-6-1.
//  Copyright (c) 2013年 pig. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDMenuController.h"
#import "HomeViewController.h"
#import "LeftViewController.h"
#import "RightViewController.h"
#import "WXApi.h"

#import "PTabBarViewController.h"

#import "RootViewController.h"

@class SinaWeibo;

@interface AppDelegate : UIResponder <UIApplicationDelegate, WXApiDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navController;
@property (nonatomic, strong) RootViewController *rootController;

@property (nonatomic, retain) DDMenuController *menuController;
@property (nonatomic, retain) HomeViewController *homeViewController;
@property (nonatomic, retain) LeftViewController *leftViewController;
@property (nonatomic, retain) RightViewController *rightViewController;

@property (nonatomic, retain) SinaWeibo *sinaweibo;

@property (nonatomic, retain) PTabBarViewController *tabBarController;

@end
