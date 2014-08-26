//
//  DetailPlayerViewController.m
//  miglab_mobile
//
//  Created by pig on 13-8-18.
//  Copyright (c) 2013年 pig. All rights reserved.
//

#import "DetailPlayerViewController.h"
#import "PPlayerManagerCenter.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UserSessionManager.h"
#import "GlobalDataManager.h"
#import "SVProgressHUD.h"
#import "PDatabaseManager.h"
#import "ShareChooseView.h"
#import "ShareViewController.h"
#import "WXApi.h"
#import <objc/runtime.h>
#import "TencentOpenAPI/QQApiInterface.h"
#import "apidefine.h"

@interface DetailPlayerViewController ()

@end

@implementation DetailPlayerViewController

@synthesize topPlayerInfoView = _topPlayerInfoView;

@synthesize lblSongInfo = _lblSongInfo;

@synthesize cdOfSongView = _cdOfSongView;

@synthesize bottomPlayerMenuView = _bottomPlayerMenuView;

@synthesize playerTimer = _playerTimer;
@synthesize checkUpdatePlayProcess = _checkUpdatePlayProcess;
@synthesize miglabAPI = _miglabAPI;
@synthesize isCurSongLike = _isCurSongLike;

//分享选择
@synthesize shareAchtionSheet = _shareAchtionSheet;
@synthesize screenCaptureImage = _screenCaptureImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        // doGetShareInfo
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getShareInfoSuccess:) name:NotificationNameGetShareInfoSuccess object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getShareInfoFailed:) name:NotificationNameGetShareInfoFailed object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoPlayerNext:) name:NotificationNamePlayerNext object:nil];
    }
    return self;
}

-(void)dealloc {
    
    // doGetShareInfo
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationNameGetShareInfoSuccess object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationNameGetShareInfoFailed object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navView.hidden = YES;
    
    //top
    _topPlayerInfoView = [[PCustomPlayerNavigationView alloc] initPlayerNavigationView:CGRectMake(0, -20 + self.topDistance, kMainScreenWidth, 44)];
    [_topPlayerInfoView.btnMenu addTarget:self action:@selector(doShowMenuViewAction:) forControlEvents:UIControlEventTouchUpInside];
    [_topPlayerInfoView.btnShare addTarget:self action:@selector(doShareAction:) forControlEvents:UIControlEventTouchUpInside];
    
#if !USE_SHARE
    _topPlayerInfoView.btnShare.hidden = YES;
#endif
    
    [self.view addSubview:_topPlayerInfoView];
    
    //song info label
    _lblSongInfo = [[UILabel alloc] init];
    _lblSongInfo.frame = CGRectMake(0, 70 + self.topDistance, kMainScreenWidth, 21);
    _lblSongInfo.backgroundColor = [UIColor clearColor];
    _lblSongInfo.textAlignment = kTextAlignmentCenter;
    _lblSongInfo.textColor = [UIColor whiteColor];
    _lblSongInfo.shadowOffset = CGSizeMake(0, 1);
    _lblSongInfo.text = @"咪呦努力加载";
    _lblSongInfo.font = [UIFont systemFontOfSize:20.0f];
    [self.view addSubview:_lblSongInfo];
    
    //song of cd view
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"PlayBodyView" owner:self options:nil];
    for (id oneObject in nib){
        if ([oneObject isKindOfClass:[PlayBodyView class]]){
            _cdOfSongView = (PlayBodyView *)oneObject;
        }//if
    }//for
    _cdOfSongView.frame = CGRectMake(0, 100 + self.topDistance, kMainScreenWidth, kMainScreenHeight - 100 - 90);
    
    _cdOfSongView.coverOfSongEGOImageView.placeholderImage = [UIImage imageWithName:@"song_cover" type:@"png"];
    _cdOfSongView.coverOfSongEGOImageView.tag = 2000;
    _cdOfSongView.coverOfSongEGOImageView.delegate = self;
    _cdOfSongView.coverOfSongEGOImageView.layer.cornerRadius = 98;
    _cdOfSongView.coverOfSongEGOImageView.layer.masksToBounds = YES;
    
    _cdOfSongView.btnCdOfSong.layer.cornerRadius = 98;
    _cdOfSongView.btnCdOfSong.layer.masksToBounds = YES;
    _cdOfSongView.btnCdOfSong.adjustsImageWhenHighlighted = NO;
    [_cdOfSongView.btnCdOfSong addTarget:self action:@selector(doPlayOrPauseAction:) forControlEvents:UIControlEventTouchUpInside];
    
    _cdOfSongView.lrcOfSongTextView.hidden = YES;
    
    //初始化进度指示
    [_cdOfSongView updateProcess:0.01];
    
    [self.view addSubview:_cdOfSongView];
    
    //bottom
    _bottomPlayerMenuView = [[PCustomPlayerMenuView alloc] initPlayerMenuView:CGRectMake(0, kMainScreenHeight + self.topDistance - 90, 320, 90)];
    [_bottomPlayerMenuView.btnRemove addTarget:self action:@selector(doDeleteAction:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomPlayerMenuView.btnLike addTarget:self action:@selector(doCollectAction:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomPlayerMenuView.btnNext addTarget:self action:@selector(doNextAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_bottomPlayerMenuView];
    
    _miglabAPI = [[MigLabAPI alloc] init];
    
    if ([GlobalDataManager GetInstance].isDetailPlayFirstLaunch) {
        
        //
        _shareGuideView = [[ShareGuideView alloc] initWithFrame:CGRectMake(0, 0, kMainScreenWidth, CGRectGetHeight(kMainScreenFrame))];
        [self.view addSubview:_shareGuideView];
        UITapGestureRecognizer *guideSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideShareGuideView)];
        [_shareGuideView addGestureRecognizer:guideSingleTap];
        
    }
    
}

- (void)hideShareGuideView
{
    _shareGuideView.hidden = YES;
    [GlobalDataManager GetInstance].isDetailPlayFirstLaunch = NO;
}

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    
    //doHateSong
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hateSongFailed:) name:NotificationNameHateSongFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hateSongSuccess:) name:NotificationNameHateSongSuccess object:nil];
    
    //doCollectSong
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectSongFailed:) name:NotificationNameCollectSongFailed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectSongSuccess:) name:NotificationNameCollectSongSuccess object:nil];
    
    //data
    _isCurSongLike = [[PPlayerManagerCenter GetInstance].currentSong.like intValue];
    
    [self initSongInfo];
    
}

-(void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:animated];
    
    //doHateSong
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationNameHateSongFailed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationNameHateSongSuccess object:nil];
    
    //doCollectSong
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationNameCollectSongFailed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationNameCollectSongSuccess object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationNamePlayerNext object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)doShowMenuViewAction:(id)sender{
    
    PLog(@"doShowMenuViewAction...");
    
    [self timerStop];
    
//    [self.navigationController popViewControllerAnimated:YES];
    [self dismissModalViewControllerAnimated:YES];
    
}

-(IBAction)doShareAction:(id)sender{
    
    PLog(@"doShareAction...");
    
    //截屏
    CGSize size = CGSizeMake(kMainScreenWidth, kMainScreenHeight);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [[self.view layer] renderInContext:UIGraphicsGetCurrentContext()];
    _screenCaptureImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //
//    _shareAchtionSheet = [[UIActionSheet alloc] initWithTitle:@"\n\n\n\n\n\n\n\n\n\n" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    _shareAchtionSheet = [[UIActionSheet alloc] initWithTitle:@"\n\n\n\n\n" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    
    ShareChooseView *shareSelectedView = [[ShareChooseView alloc] initShareChooseView];
    
    [shareSelectedView.btnFirst addTarget:self action:@selector(doGotoShareView:) forControlEvents:UIControlEventTouchUpInside];
    
    [shareSelectedView.btnSecond addTarget:self action:@selector(doGotoShareView:) forControlEvents:UIControlEventTouchUpInside];
    
    [shareSelectedView.btnThird addTarget:self action:@selector(doGotoShareView:) forControlEvents:UIControlEventTouchUpInside];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(doGotoShareViewWithLongPress:)];
    longPress.minimumPressDuration = 0.8;
    [shareSelectedView.btnThird addGestureRecognizer:longPress];
    
    [shareSelectedView.btnFour addTarget:self action:@selector(doGotoShareView:) forControlEvents:UIControlEventTouchUpInside];
    shareSelectedView.btnFour.hidden = YES;
    shareSelectedView.lblFour.hidden = YES;
    
    [shareSelectedView.btnFive addTarget:self action:@selector(doGotoShareView:) forControlEvents:UIControlEventTouchUpInside];
    shareSelectedView.btnFive.hidden = YES;
    shareSelectedView.lblFive.hidden = YES;
    
    [shareSelectedView.btnSix addTarget:self action:@selector(doGotoShareView:) forControlEvents:UIControlEventTouchUpInside];
    shareSelectedView.btnSix.hidden = YES;
    shareSelectedView.lblSix.hidden = YES;
    
    [_shareAchtionSheet addSubview:shareSelectedView];
    
    [_shareAchtionSheet showInView:self.view];
    
}

-(IBAction)doGotoShareView:(id)sender{
    
    UIButton *btnShare = sender;
    PLog(@"btnShare.tag: %d", btnShare.tag);
    
    switch (btnShare.tag) {
        case 201:
        {
            //qqzone
            [self doShare2QQZone];
        }
            break;
        case 202:
        {
            //sinaweibo
            [self doShare2SinaWeibo];
        }
            break;
        case 203:
        {
            //weixin
            [self doShare2WeiXin];
        }
            break;
        case 204:
        {
            //tencentweibo
            [self doShare2TencentWeibo];
        }
            break;
        case 205:
        {
            //renren
            [self doShare2Renren];
        }
            break;
        case 206:
        {
            //sms
            [self doSHare2Sms];
            return;
        }
            break;
            
        default:
            break;
    }//switch
    
    [_shareAchtionSheet dismissWithClickedButtonIndex:0 animated:YES];
    
    //
//    ShareViewController *shareViewController = [[ShareViewController alloc] init];
    //    [self.navigationController pushViewController:shareViewController animated:YES];
//    [self presentModalViewController:shareViewController animated:YES];
    
}

-(IBAction)doGotoShareViewWithLongPress:(id)sender {
    
    UILongPressGestureRecognizer *recogSender = (UILongPressGestureRecognizer *)sender;
    
    if (recogSender.state == UIGestureRecognizerStateBegan) {
        
        //weixin
        Song *currentSong = [PPlayerManagerCenter GetInstance].currentSong;
        
        NSString* uid = [UserSessionManager GetInstance].userid;
        NSString* accesstoken = [UserSessionManager GetInstance].accesstoken;
        NSString* tsongid = [NSString stringWithFormat:@"%lld", currentSong.songid];
        NSString* ttype = STR_USER_SOURCE_SINA;
        NSString* tlatitude = [GlobalDataManager GetInstance].lastLatitude;
        NSString* tlongitude = [GlobalDataManager GetInstance].lastLongitude;
        
        [_miglabAPI doGetShareInfo:uid token:accesstoken songid:tsongid type:ttype latitude:tlatitude longitude:tlongitude];
        
        [_shareAchtionSheet dismissWithClickedButtonIndex:0 animated:YES];
    }
}

-(void)doShare2QQZone{
    
    PLog(@"doShare2QQZone...");
    
    Song *currentSong = [PPlayerManagerCenter GetInstance].currentSong;
    
    TencentHelper *tencentHelper = [TencentHelper sharedInstance];
    tencentHelper.delegate = self;
    //[tencentHelper addTopic:currentSong];
    [tencentHelper addQQZoneWithLyricImage:currentSong];
}

-(void)doShare2SinaWeibo{
    
    PLog(@"doShare2SinaWeibo...");
    
    Song *currentSong = [PPlayerManagerCenter GetInstance].currentSong;
    
    SinaWeiboHelper *sinaWeiboHelper = [SinaWeiboHelper sharedInstance];
    sinaWeiboHelper.delegate = self;
    [sinaWeiboHelper updateSinaWeibo:currentSong];
    
}

-(void)doShare2WeiXin{
    
    PLog(@"doShare2WeiXin...");
    
    //分享到微信朋友圈
    if (![WXApi isWXAppInstalled]) {
        NSLog(@"你的iPhone上还没有安装微信，无法使用此功能，请先下载");
        return;
    }
    
    if (![WXApi isWXAppSupportApi]) {
        NSLog(@"你当前的微信版本过低，无法支持此功能，请更新微信至最新版本");
        return;
    }
    
    Song *currentSong = [PPlayerManagerCenter GetInstance].currentSong;
    UIImage *defaultSongCoverImage = _cdOfSongView.coverOfSongEGOImageView.image;
    UIImage *upimage = [UIImage imageWithName:@"share_songcover_share_layer" type:@"png"];
    UIImage *shareImage = [PCommonUtil maskImage:defaultSongCoverImage withImage:upimage];
    
    //需要注意的是，SendMessageToWXReq的scene成员，如果scene填WXSceneSession，那么消息会发送至微信的会话内。如果scene填WXSceneTimeline发送到朋友圈，默认值为WXSceneSession
    /*
     WXMediaMessage *message = [WXMediaMessage message];
     message.title = [UserSessionManager GetInstance].currentRunUser.nickname;
     message.description = descText;
     
     WXImageObject *ext = [WXImageObject object];
     ext.imageData = UIImagePNGRepresentation(image);
     message.mediaObject = ext;
     
     SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
     req.bText = NO;
     req.message = message;
     req.scene = scene;//选择发送到朋友圈，默认值为WXSceneSession，发送到会话
     
     [WXApi sendReq:req];
     */
    
    //
    WXMediaMessage *message = [WXMediaMessage message];
    
#if USE_ARTIST_SONGNAME
    message.title = currentSong.artist;
    message.description = [NSString stringWithFormat:@"%@ - %@", currentSong.artist, currentSong.songname];
#else
    message.title = currentSong.songname;
    message.description = [NSString stringWithFormat:@"%@", currentSong.artist];
#endif
    [message setThumbImage:shareImage];
    
    WXMusicObject *ext = [WXMusicObject object];
#ifdef WEIXIN_REAL_SONG_ADDRESS
    ext.musicUrl = currentSong.songurl;
#else
    ext.musicUrl = [NSString stringWithFormat:SHARE_WEIXIN_ADDRESS_1LONG, currentSong.songid];
    PLog(@"musicUrl %@",ext.musicUrl);
    ext.musicDataUrl = currentSong.songurl;
#endif
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneTimeline;
    [WXApi sendReq:req];
    
}

-(void)doShare2WeiXinWithLongPress:(LyricShare *)ls{
    
    PLog(@"doShare2WeiXinWithLongPress...");
    
    //分享到微信朋友圈
    if (![WXApi isWXAppInstalled]) {
        NSLog(@"你的iPhone上还没有安装微信，无法使用此功能，请先下载");
        return;
    }
    
    if (![WXApi isWXAppSupportApi]) {
        NSLog(@"你当前的微信版本过低，无法支持此功能，请更新微信至最新版本");
        return;
    }
    
    Song *currentSong = [PPlayerManagerCenter GetInstance].currentSong;
    
    NSString *shareText = [NSString stringWithFormat:MIGTIP_WEIBO_SHARE_TEXT_4S, [UserSessionManager GetInstance].currentUserGene.mood.name, currentSong.songname, currentSong.artist, [NSString stringWithFormat:SHARE_WEIBO_ADDRESS_1LONG, currentSong.songid]];
    
    UIImage* shareLyricImage = [[UIImage_ext GetInstance] createLyricShareImage:ls song:currentSong];
    
    UIImage *defaultSongCoverImage = _cdOfSongView.coverOfSongEGOImageView.image;
    UIImage *upimage = [UIImage imageWithName:@"share_songcover_share_layer" type:@"png"];
    UIImage *shareImage = [PCommonUtil maskImage:defaultSongCoverImage withImage:upimage];
    
    //
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = shareText;
    [message setThumbImage:shareImage];

    WXImageObject *ext = [WXImageObject object];
    ext.imageData = UIImagePNGRepresentation(shareLyricImage);

    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneTimeline;
    [WXApi sendReq:req];
    
}

-(void)doShare2TencentWeibo{
    
    PLog(@"doShare2TencentWeibo...");
    
    Song *currentSong = [PPlayerManagerCenter GetInstance].currentSong;
    
    TencentHelper *tencentHelper = [TencentHelper sharedInstance];
    tencentHelper.delegate = self;
    [tencentHelper addWeibo:currentSong];
    
}

-(void)doShare2Renren{
    
    PLog(@"doShare2Renren...");
    
}

-(void)doSHare2Sms{
    
    PLog(@"doSHare2Sms...");
    
}

//

#pragma UIAlertViewDelegate


#pragma UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    PLog(@"actionSheet clickedButtonAtIndex: %d", buttonIndex);
}

-(IBAction)doDeleteAction:(id)sender{
    
    PLog(@"DetailPlayerViewController doDeleteAction...");
    
    if ([UserSessionManager GetInstance].isLoggedIn) {
        
        Song *currentSong = [PPlayerManagerCenter GetInstance].currentSong;
        NSString *accesstoken = [UserSessionManager GetInstance].accesstoken;
        NSString *userid = [UserSessionManager GetInstance].currentUser.userid;
        [_miglabAPI doHateSong:userid token:accesstoken sid:currentSong.songid];
        
        int currentSongIndex = [PPlayerManagerCenter GetInstance].currentSongIndex;
        if (currentSongIndex >=0 && currentSongIndex < [[PPlayerManagerCenter GetInstance].songList count]) {
            [[PPlayerManagerCenter GetInstance].songList removeObjectAtIndex:currentSongIndex];
            [[PDatabaseManager GetInstance] deleteSongInfo:currentSong.songid];
        }
        
        [self doNextAction:nil];
        
    } else {
        [SVProgressHUD showErrorWithStatus:MIGTIP_UNLOGIN];
    }
    
}

-(IBAction)doCollectAction:(id)sender{
    
    PLog(@"DetailPlayerViewController doCollectAction...");
    
    UserSessionManager *userSessionManager = [UserSessionManager GetInstance];
    if (userSessionManager.isLoggedIn) {
        
        NSString *userid = [UserSessionManager GetInstance].userid;
        NSString *accesstoken = [UserSessionManager GetInstance].accesstoken;
        Song *currentSong = [PPlayerManagerCenter GetInstance].currentSong;
        NSString *songid = [NSString stringWithFormat:@"%lld", currentSong.songid];
        NSString *moodid = [NSString stringWithFormat:@"%d", userSessionManager.currentUserGene.mood.typeid];
        NSString *typeid = [NSString stringWithFormat:@"%d", userSessionManager.currentUserGene.type.typeid];
        
        if (_isCurSongLike > 0) {
            
            [_miglabAPI doDeleteCollectedSong:userid token:accesstoken songid:songid];
            _isCurSongLike = 0;
        } else {
            
            [_miglabAPI doCollectSong:userid token:accesstoken sid:songid modetype:moodid typeid:typeid];
            _isCurSongLike = 1;
        }
        
    } else {
        [SVProgressHUD showErrorWithStatus:MIGTIP_UNLOGIN];
    }
    
}

-(IBAction)doPlayOrPauseAction:(id)sender{
    
    PLog(@"DetailPlayerViewController doPlayOrPauseAction...");
    
    [[PPlayerManagerCenter GetInstance] doPlayOrPause];
    
    [self initSongInfo];
    
}

-(IBAction)doNextAction:(id)sender{
    
    PLog(@"DetailPlayerViewController doNextAction...");
    
    [[PPlayerManagerCenter GetInstance] doNext];
    
    _isCurSongLike = [[PPlayerManagerCenter GetInstance].currentSong.like intValue];
    
    [self initSongInfo];
    
}

-(void)hateSongFailed:(NSNotification *)tNotification{
    [SVProgressHUD showErrorWithStatus:@"歌曲拉黑失败:("];
}

-(void)hateSongSuccess:(NSNotification *)tNotification{
    //[SVProgressHUD showSuccessWithStatus:@"歌曲拉黑成功:)"];
}

-(void)collectSongFailed:(NSNotification *)tNotification{
    [SVProgressHUD showErrorWithStatus:@"歌曲收藏失败:("];
}

-(void)collectSongSuccess:(NSNotification *)tNotification{
    
    //[SVProgressHUD showSuccessWithStatus:@"歌曲收藏成功:)"];
    [self initSongInfo];
}

-(void)getShareInfoSuccess:(NSNotification *)tNotification {
    
    NSDictionary *dicResult = (NSDictionary*)tNotification.userInfo;
    NSDictionary *dicLyric = [dicResult objectForKey:@"result"];
    
    LyricShare* ls = [LyricShare initWithNSDictionary:dicLyric];
    
    [self doShare2WeiXinWithLongPress:ls];
}

-(void)getShareInfoFailed:(NSNotification *)tNotification {
    
    [SVProgressHUD showErrorWithStatus:MIGTIP_SHARING_FAILED];
}

-(void)initSongInfo{
    
    UserGene *usergene = [UserSessionManager GetInstance].currentUserGene;
    Song *currentSong = [PPlayerManagerCenter GetInstance].currentSong;
    
    // 根据歌曲的类型显示字
    NSString* songtype = currentSong.type;
    NSString* tempText = usergene.type.desc;
    
    if ([songtype isEqualToString:@"mm"]) {
        
        tempText = usergene.mood.name;
    }
    else if([songtype isEqualToString:@"ms"]) {
        
        tempText = usergene.scene.name;
    }
    
    _topPlayerInfoView.lblPlayingSongInfo.text = tempText;
    
    // 显示歌曲名称和演唱者
    _lblSongInfo.text = [NSString stringWithFormat:@"%@ - %@", currentSong.artist, currentSong.songname];
    _cdOfSongView.coverOfSongEGOImageView.imageURL = [NSURL URLWithString:currentSong.coverurl];
    
    // 显示红心
    if (_isCurSongLike > 0) {
        
        _bottomPlayerMenuView.btnLike.imageView.image = [UIImage imageWithName:@"btn_like_sel" type:@"png"];
    }
    else {
        
        _bottomPlayerMenuView.btnLike.imageView.image = [UIImage imageWithName:@"btn_like_nor" type:@"png"];
    }
    
    
//    _cdOfSongView.lrcOfSongTextView.text = usergene.scene.desc;
    
    [self timerStart];
    
}

-(void)configNowPlayingInfoCenter{
    
    if (NSClassFromString(@"MPNowPlayingInfoCenter")) {
        
        Song *currentSong = [PPlayerManagerCenter GetInstance].currentSong;
        
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        [dict setObject:currentSong.songname forKey:MPMediaItemPropertyTitle];
        [dict setObject:currentSong.artist forKey:MPMediaItemPropertyArtist];
        MPMediaItemArtwork * mArt = [[MPMediaItemArtwork alloc] initWithImage:_cdOfSongView.coverOfSongEGOImageView.image];
        [dict setObject:mArt forKey:MPMediaItemPropertyArtwork];
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dict];
        
    }
    
}

//播放时间刷新
-(void)timerStop{
    
    @synchronized(self){
        if (_playerTimer) {
            if ([_playerTimer isValid]) {
                [_playerTimer invalidate];
            }
            _playerTimer = nil;
        }
    }
    
}

-(void)timerStart{
    
    [self timerStop];
    _playerTimer = [NSTimer scheduledTimerWithTimeInterval:PlayerTimerFunctionInterval target:self selector:@selector(playerTimerFunction) userInfo:nil repeats:YES];
    
}

-(void)playerTimerFunction{

//    PLog(@"playerTimerFunction...");
    
    //更新播放信息
    [self doUpdateForPlaying];
    
}

//播放时刷新所有对于view的数据
-(void)doUpdateForPlaying{
    
    [_topPlayerInfoView doUpdatePlayingTip];
    [_cdOfSongView doRotateSongCover];
    [self doUpdateProcess];
    
}

//根据圆圈的比率，刷新圆盘进度
-(void)doUpdateProcess{
    
    if (_checkUpdatePlayProcess < 10) {
        _checkUpdatePlayProcess++;
        return;
    }
    _checkUpdatePlayProcess = 0;
    
    PAAMusicPlayer *aaMusicPlayer = [[PPlayerManagerCenter GetInstance] getPlayer:WhichPlayer_AVAudioPlayer];
    long duration = aaMusicPlayer.getDuration;
    long currentTime = aaMusicPlayer.getCurrentTime;
    float playProcess = (duration > 0) ? (float)currentTime / (float)duration : 0;
    
    [_cdOfSongView updateProcess:playProcess];
    
    //如果未播放就停止
    if (![aaMusicPlayer isMusicPlaying]) {
        [self timerStop];
    }
    
}

-(void)autoPlayerNext:(NSNotification *)tNotification {
    
    _isCurSongLike = [[PPlayerManagerCenter GetInstance].currentSong.like intValue];
    [self initSongInfo];
}

#pragma mark EGOImageViewDelegate
- (void)imageViewLoadedImage:(EGOImageView*)imageView{
    
}

- (void)imageViewFailedToLoadImage:(EGOImageView*)imageView error:(NSError*)error{
    
}

#pragma mark EGOImageButtonDelegate
- (void)imageButtonLoadedImage:(EGOImageButton*)imageButton{
    
}

- (void)imageButtonFailedToLoadImage:(EGOImageButton*)imageButton error:(NSError*)error{
    
}

#pragma mark SinaWeiboHelperDelegate method

- (void)sinaWeiboUpdateHelper:(SinaWeiboHelper *)sinaWeiboHelper didFailWithError:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus:@"sorry, 分享新浪微博失败～"];
}

- (void)sinaWeiboUpdateHelper:(SinaWeiboHelper *)sinaWeiboHelper didFinishLoadingWithResult:(NSDictionary *)result
{
    [SVProgressHUD showSuccessWithStatus:@"分享新浪微博成功～"];
}

#pragma mark TencentHelperDelegate method

- (void)tencentAddTopicHelper:(TencentHelper *)tencentHelper didFailWithError:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus:@"sorry, 发表说说失败～"];
}

- (void)tencentAddTopicHelper:(TencentHelper *)tencentHelper didFinishLoadingWithResult:(NSDictionary *)result
{
    [SVProgressHUD showSuccessWithStatus:@"发表说说成功～"];
}

- (void)tencentAddWeiboHelper:(TencentHelper *)tencentHelper didFailWithError:(NSError *)error
{
    [SVProgressHUD showErrorWithStatus:@"sorry, 发布微博失败～"];
}

- (void)tencentAddWeiboHelper:(TencentHelper *)tencentHelper didFinishLoadingWithResult:(NSDictionary *)result
{
    [SVProgressHUD showSuccessWithStatus:@"发布微博成功～"];
}

@end
