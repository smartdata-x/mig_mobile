//
//  MusicViewController.h
//  miglab_mobile
//
//  Created by pig on 13-8-13.
//  Copyright (c) 2013年 pig. All rights reserved.
//

#import "PlayerViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "CollectNum.h"

@interface MusicViewController : PlayerViewController<UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, retain) UITableView *bodyTableView;
@property (nonatomic, retain) NSArray *tableTitles;

//gps定位
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CollectNum *collectNum;

-(void)loadCollectedAndNearNumFromServer:(NSString *)tLocation;

-(void)getCollectAndNearNumFailed:(NSNotification *)tNotification;
-(void)getCollectAndNearNumSuccess:(NSNotification *)tNotification;

@end
