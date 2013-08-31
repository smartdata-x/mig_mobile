//
//  MusicViewController.m
//  miglab_mobile
//
//  Created by pig on 13-8-13.
//  Copyright (c) 2013年 pig. All rights reserved.
//

#import "MusicViewController.h"
#import "MusicSourceMenuCell.h"
#import "CollectNum.h"

#import "OnlineViewController.h"
#import "LikeViewController.h"
#import "NearMusicViewController.h"
#import "LocalViewController.h"

@interface MusicViewController ()

@end

@implementation MusicViewController

@synthesize bodyTableView = _bodyTableView;
@synthesize tableTitles = _tableTitles;

@synthesize locationManager = _locationManager;
@synthesize collectNum = _collectNum;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCollectAndNearNumFailed:) name:NotificationNameCollectAndNearNumFailed object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCollectAndNearNumSuccess:) name:NotificationNameCollectAndNearNumSuccess object:nil];
        
    }
    return self;
}

-(void)dealloc{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationNameCollectAndNearNumFailed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationNameCollectAndNearNumSuccess object:nil];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //body
    _bodyTableView = [[UITableView alloc] init];
    _bodyTableView.frame = CGRectMake(11.5, 45 + 10, 297, kMainScreenHeight - 45 - 10 - 10 - 73 - 10);
    _bodyTableView.dataSource = self;
    _bodyTableView.delegate = self;
    _bodyTableView.backgroundColor = [UIColor clearColor];
    _bodyTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _bodyTableView.scrollEnabled = NO;
    
    UIImageView *bodyBgImageView = [[UIImageView alloc] init];
    bodyBgImageView.frame = _bodyTableView.frame;
    bodyBgImageView.image = [UIImage imageWithName:@"body_bg" type:@"png"];
    _bodyTableView.backgroundView = bodyBgImageView;
    [self.view addSubview:_bodyTableView];
    
    NSDictionary *dicMenu0 = [NSDictionary dictionaryWithObjectsAndKeys:@"music_source_menu_online", @"MenuImageName", @"在线推荐", @"MenuText", @"0", @"MenuTip", nil];
    NSDictionary *dicMenu1 = [NSDictionary dictionaryWithObjectsAndKeys:@"music_source_menu_like", @"MenuImageName", @"我喜欢的", @"MenuText", @"90", @"MenuTip", nil];
    NSDictionary *dicMenu2 = [NSDictionary dictionaryWithObjectsAndKeys:@"music_source_menu_nearby", @"MenuImageName", @"附近的好音乐", @"MenuText", @"909", @"MenuTip", nil];
    NSDictionary *dicMenu3 = [NSDictionary dictionaryWithObjectsAndKeys:@"music_source_menu_local", @"MenuImageName", @"本地音乐", @"MenuText", @"0", @"MenuTip", nil];
    _tableTitles = [NSArray arrayWithObjects:dicMenu0, dicMenu1, dicMenu2, dicMenu3, nil];
    
    //gps
    _locationManager = [[CLLocationManager alloc] init];
    if ([CLLocationManager locationServicesEnabled]) {
        [_locationManager setDelegate:self];
        [_locationManager setDistanceFilter:kCLDistanceFilterNone];
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [_locationManager startUpdatingLocation];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loadCollectedAndNearNumFromServer:(NSString *)tLocation{
    
    PLog(@"loadCollectedAndNearNumFromServer...");
    
    if ([UserSessionManager GetInstance].isLoggedIn && tLocation) {
        
        NSString *userid = [UserSessionManager GetInstance].userid;
        NSString *accesstoken = [UserSessionManager GetInstance].accesstoken;
        
        [self.miglabAPI doCollectAndNearNum:userid token:accesstoken taruid:userid radius:@"1000" pageindex:@"0" pagesize:@"10" location:tLocation];
        
    } else {
        
        [SVProgressHUD showErrorWithStatus:@"您还未登陆哦～"];
        
    }
    
}

#pragma notification

-(void)getCollectAndNearNumFailed:(NSNotification *)tNotification{
    
    PLog(@"getCollectAndNearNumFailed...");
    
}

-(void)getCollectAndNearNumSuccess:(NSNotification *)tNotification{
    
    PLog(@"getCollectAndNearNumSuccess...");
    
    NSDictionary *result = [tNotification userInfo];
    _collectNum = [result objectForKey:@"result"];
    NSString *strCollectNum = [NSString stringWithFormat:@"%d", _collectNum.mynum];
    NSString *strNearNum = [NSString stringWithFormat:@"%d", _collectNum.nearnum];
    
    //collected
    NSDictionary *dicMenu1 = [_tableTitles objectAtIndex:1];
    [dicMenu1 setValue:strCollectNum forKey:@"MenuTip"];
    
    //near
    NSDictionary *dicMenu2 = [_tableTitles objectAtIndex:2];
    [dicMenu2 setValue:strNearNum forKey:@"MenuTip"];
    
    [_bodyTableView reloadData];
    
}

#pragma CLLocationManagerDelegate

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    
    PLog(@"[newLocation description]: %@", [newLocation description]);
    
    //取得经纬度
    CLLocationCoordinate2D coordinate = newLocation.coordinate;
    CLLocationDegrees gLatitude = coordinate.latitude;
    CLLocationDegrees GLongitude = coordinate.longitude;
    NSString *strLatitude = [NSString stringWithFormat:@"%g", gLatitude];
    NSString *strLongitude = [NSString stringWithFormat:@"%g", GLongitude];
    NSLog(@"strLatitude: %@, strLongitude: %@", strLatitude, strLongitude);
    
    [_locationManager stopUpdatingLocation];
    
    NSString *strLocation = [NSString stringWithFormat:@"%@,%@", strLatitude, strLongitude];
    
    //
    [self loadCollectedAndNearNumFromServer:strLocation];
    
    
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    PLog(@"locationManager didFailWithError: %@", [error localizedDescription]);
}

#pragma mark - UITableView delegate

// custom view for header. will be adjusted to default or specified header height
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIButton *btnEdit = [UIButton buttonWithType:UIButtonTypeCustom];
    btnEdit.frame = CGRectMake(230, 8, 58, 28);
    UIImage *editNorImage = [UIImage imageWithName:@"music_source_edit" type:@"png"];
    [btnEdit setImage:editNorImage forState:UIControlStateNormal];
    
    UIImageView *separatorImageView = [[UIImageView alloc] init];
    separatorImageView.frame = CGRectMake(4, 45, 290, 1);
    separatorImageView.image = [UIImage imageWithName:@"music_source_separator" type:@"png"];
    
    UIView *headerView = [[UIView alloc] init];
    headerView.frame = CGRectMake(0, 0, 297, 45);
    [headerView addSubview:btnEdit];
    [headerView addSubview:separatorImageView];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45;
}

// Called after the user changes the selection.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // ...
    if (indexPath.row == 0) {
        
        OnlineViewController *onlineViewController = [[OnlineViewController alloc] initWithNibName:@"OnlineViewController" bundle:nil];
        [self.topViewcontroller.navigationController pushViewController:onlineViewController animated:YES];
        
    } else if (indexPath.row == 1) {
        
        LikeViewController *likeViewController = [[LikeViewController alloc] initWithNibName:@"LikeViewController" bundle:nil];
        [self.topViewcontroller.navigationController pushViewController:likeViewController animated:YES];
        
    } else if (indexPath.row == 2) {
        
        NearMusicViewController *nearMusicViewController = [[NearMusicViewController alloc] initWithNibName:@"NearMusicViewController" bundle:nil];
        [self.topViewcontroller.navigationController pushViewController:nearMusicViewController animated:YES];
        
    } else if (indexPath.row == 3) {
        
        LocalViewController *localViewController = [[LocalViewController alloc] initWithNibName:@"LocalViewController" bundle:nil];
        [self.topViewcontroller.navigationController pushViewController:localViewController animated:YES];
        
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark - UITableView datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"MusicSourceMenuCell";
	MusicSourceMenuCell *cell = (MusicSourceMenuCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"MusicSourceMenuCell" owner:self options:nil];
        cell = (MusicSourceMenuCell *)[nibContents objectAtIndex:0];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
    
    NSDictionary *dicMenu = [_tableTitles objectAtIndex:indexPath.row];
    cell.menuImageView.image = [UIImage imageWithName:[dicMenu objectForKey:@"MenuImageName"]];
    cell.lblMenu.text = [dicMenu objectForKey:@"MenuText"];
    
    int nMenuTip = [[dicMenu objectForKey:@"MenuTip"] intValue];
    if (nMenuTip > 0) {
        cell.lblTipNum.text = [NSString stringWithFormat:@"%d", nMenuTip];
        cell.lblTipNum.hidden = NO;
    } else {
        cell.lblTipNum.hidden = YES;
    }
    
    NSLog(@"cell.frame.size.height: %f", cell.frame.size.height);
    
	return cell;
}

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 57;
}

@end
