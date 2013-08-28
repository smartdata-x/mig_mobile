//
//  MigLabAPI.m
//  miglab_mobile
//
//  Created by pig on 13-6-23.
//  Copyright (c) 2013年 pig. All rights reserved.
//

#import "MigLabAPI.h"
#import "MigLabConfig.h"

#import "AFHTTPRequestOperation.h"
#import "AFHTTPClient.h"
#import "AFJSONRequestOperation.h"
#import "UserSessionManager.h"
#import "Song.h"
#import "Channel.h"
#import "Word.h"
#import "Mood.h"
#import "NearbyUser.h"
#import "ConfigFileInfo.h"

@implementation MigLabAPI

/*
 SSO的登录
 http://sso.miglab.com/cgi-bin/sp.fcgi?sp
 */
-(void)doAuthLogin:(NSString *)tusername password:(NSString *)tpassword{
    
    PLog(@"username: %@, password: %@", tusername, tpassword);
    
    if (!tusername || tusername.length == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUsernameIsNull object:nil userInfo:nil];
        return;
    }
    
    if (!tpassword || tpassword.length == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNamePasswordIsNull object:nil userInfo:nil];
        return;
    }
    
    [self doSsoLoginFirst:tusername password:tpassword];
    
}

/*
 <!--请求Get-->
 http://sso.miglab.com/cgi-bin/sp.fcgi?sp
 */
-(void)doSsoLoginFirst:(NSString *)tusername password:(NSString *)tpassword{
    
    PLog(@"LOGIN_SSO_SP_URL: %@", LOGIN_SSO_SP_URL);
    
    NSURL *url = [NSURL URLWithString:LOGIN_SSO_SP_URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            PLog(@"result: %@", result);
            
            NSArray *resultList = [result componentsSeparatedByString:@"?"];
            if ([resultList count] == 2) {
                
                NSString *postUrl = [resultList objectAtIndex:0];
                NSString *postContent = [resultList objectAtIndex:1];
                NSString *secondPostContent = [NSString stringWithFormat:@"username=%@&password=%@&%@", tusername, tpassword, postContent];
                
                [self doSsoLoginSecond:postUrl param:secondPostContent];
                
            } else {
                
                PLog(@"doSsoLoginFirst failure...");
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameLoginFailed object:nil userInfo:nil];
                
            }
            
        }
        @catch (NSException *exception) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameLoginFailed object:nil userInfo:nil];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"failure: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameLoginFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 将第一步返回值URL和RequestID解析出来
 <!--请求POST-->
 http://sso.miglab.com/cgi-bin/idp.fcgi
 */
-(void)doSsoLoginSecond:(NSString *)ssoSecondUrl param:(NSString *)strParam{
    
    NSString *loginSsoSecondUrl = ssoSecondUrl;
    PLog(@"loginSsoSecondUrl: %@", loginSsoSecondUrl);
    
    NSURL *url = [NSURL URLWithString:loginSsoSecondUrl];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[strParam dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            PLog(@"result: %@", result);
            NSArray *resultList = [result componentsSeparatedByString:@"?"];
            if ([resultList count] == 2) {
                
                NSString *postUrl = [resultList objectAtIndex:0];
                NSString *postContent = [resultList objectAtIndex:1];
                
                [self doSsoLoginThird:postUrl param:postContent];
                
            } else {
                
                PLog(@"doSsoLoginSecond failure...");
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameLoginFailed object:nil userInfo:nil];
                
            }
            
        }
        @catch (NSException *exception) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameLoginFailed object:nil userInfo:nil];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"failure: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameLoginFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 将第二步内容得URL和内容解析出来
 <!--请求POST-->
 http://fm.miglab.com/cgi-bin/sp.fcgi
 */
-(void)doSsoLoginThird:(NSString *)ssoThirdUrl param:(NSString *)strParam{
    
    NSString *loginSsoThirdUrl = ssoThirdUrl;
    PLog(@"loginSsoThirdUrl: %@", loginSsoThirdUrl);
    
    NSURL *url = [NSURL URLWithString:loginSsoThirdUrl];
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[strParam dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            NSString *strAccessToken = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            PLog(@"result AccessToken: %@, strAccessToken: %@", result, strAccessToken);
            NSDictionary *dicResult = [NSDictionary dictionaryWithObjectsAndKeys:strAccessToken, @"AccessToken", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameLoginSuccess object:nil userInfo:dicResult];
            
        }
        @catch (NSException *exception) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameLoginFailed object:nil userInfo:nil];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"failure: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameLoginFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 获取用户信息
 <!--请求Get-->
 http://open.fm.miglab.com/api/userinfo.fcgi
 */
-(void)doGetUserInfo:(NSString *)tUserName accessToken:(NSString *)tAccessToken{
    
    NSString *getUserInfoUrl = [NSString stringWithFormat:@"%@?username=%@&token=%@", GET_USER_INFO, tUserName, tAccessToken];
    PLog(@"getUserInfoUrl: %@", getUserInfoUrl);
    
    NSURL *url = [NSURL URLWithString:getUserInfoUrl];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary *dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            PLog(@"dicJson: %@", dicJson);
            
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get user information operation succeeded");
                
                PUser* user = [PUser initWithNSDictionary:[dicJson objectForKey:@"result"]];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:user, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetUserInfoSuccess object:nil userInfo:dicResult];
                
            } else {
                
                PLog(@"get user information operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetUserInfoFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetUserInfoFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"failure: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetUserInfoFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 注册用户
 <!--请求POST-->
 HTTP_REGISTER
 */
-(void)doRegister:(NSString*)tusername password:(NSString*)tpassword nickname:(NSString*)tnickname source:(SourceType)tsourcetype{
    
    NSString* registerUrl = HTTP_REGISTER;
    PLog(@"registerUrl: %@", registerUrl);
    
    NSURL* url = [NSURL URLWithString:registerUrl];
    AFHTTPClient* httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];

    NSString* httpBody = [NSString stringWithFormat:@"username=%@&password=%@&nickname=%@&source=%d", tusername, tpassword, tnickname, tsourcetype];
    PLog(@"httpBody: %@", httpBody);
    
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary *dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            PLog(@"dicJson: %@", dicJson);
            
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if (1 == status) {
                
                PLog(@"register operation succeeded");
                
                PUser* user = [PUser initWithNSDictionary:[dicJson objectForKey:@"result"]];
                NSDictionary *dicResult = [NSDictionary dictionaryWithObjectsAndKeys:user, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRegisterSuccess object:nil userInfo:dicResult];
                
            } else if (0 == status || -1 == status) {
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                PLog(@"register operation failed: %@", msg);
                NSDictionary *dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRegisterFailed object:nil userInfo:dicResult];
                
            } else {
                
                NSString* msg = @"未知错误:(";
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRegisterFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRegisterFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"register failure: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRegisterFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 生成游客信息
 <!--请求Get-->
 HTTP_GUEST
 */
-(void)doGetGuestInfo {
    
    PLog(@"guest url: %@", HTTP_GUEST);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:HTTP_GUEST]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            PLog(@"dicJson: %@", dicJson);
            
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get guest operation succeeded");
                
                PUser* user = [PUser initWithNSDictionary:[dicJson objectForKey:@"result"]];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:user, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetGuestSuccess object:nil userInfo:dicResult];
                
            }
            else {
                
                PLog(@"get guest operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetUserInfoFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetUserInfoFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"get guest failure: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetUserInfoFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 更新用户信息
 <!--请求POST-->
 HTTP_UPDATEUSER
 */
-(void)doUpdateUserInfo:(NSString*)uid token:(NSString *)ttoken username:(NSString *)tusername nickname:(NSString *)tnickname gender:(NSString *)tgender birthday:(NSString *)tbirthday location:(NSString *)tlocation source:(NSString *)tsource head:(NSString *)thead {
    
    PLog(@"update user information url: %@", HTTP_UPDATEUSER);
    
    AFHTTPClient* httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:HTTP_UPDATEUSER]];
    
    NSString* httpBody = [NSString stringWithFormat:@"uid=%@&token=%@&username=%@&nickname=%@&gender=%@&birthday=%@&location=%@&source=%@&head=%@", uid, ttoken, tusername, tnickname, tgender, tbirthday, tlocation, tsource, thead];
    PLog(@"update user information body: %@", httpBody);
    
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] init];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"update user information operation succeed");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationUpdateUserSuccess object:nil userInfo:nil];
                
            }
            else {
                
                PLog(@"update user information operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationUpdateUserFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationUpdateUserFailed object:nil userInfo:dicResult];
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"update user information failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationUpdateUserFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 获取默认推荐歌曲接口
 <!--请求Get-->
 http://open.fm.miglab.com/api/song.fcgi?token=AAOfv3WG35avZspzKhoeodwv2MFd8zYxOUFENUNCMUFBNjgwMDAyRTI2&uid=10001
 */
-(void)doGetDefaultMusic:(NSString *)ttype token:(NSString *)ttoken uid:(int)tuid {

    NSString* musicUrl = HTTP_DEFAULTMUSIC;
    PLog(@"musicUrl: %@", musicUrl);
    
    NSURL* url = [NSURL URLWithString:musicUrl];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        @try {
            
            NSDictionary* dicJson = JSON;
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status)
            {
                Song* song = [Song initWithNSDictionary:[dicJson objectForKey:@"result"]];
                NSDictionary* dicSong = [NSDictionary dictionaryWithObjectsAndKeys:song, @"song", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetDefaultMusicSuccess object:nil userInfo:dicSong];
            }
            else
            {
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicError = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetDefaultMusicFailed object:nil userInfo:dicError];
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicError = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetDefaultMusicFailed object:nil userInfo:dicError];
            
        }
            
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
    
        PLog(@"failure: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetDefaultMusicFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
}

/*
添加歌曲到收藏列表
 <!--请求POST-->
 HTTP_ADDFAVORITE
 */
-(void)doCollectSong:(NSString *)ttoken uid:(NSString *)tuid songid:(long)tsongid{
    
    PLog(@"collect song url: %@", HTTP_COLLECTSONG);
    
    AFHTTPClient* httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:HTTP_COLLECTSONG]];
    
    NSString* httpBody = [NSString stringWithFormat:@"token=%@&uid=%@&songid=%ld", ttoken, tuid, tsongid];
    
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        @try {
            
            NSDictionary* dicJson = JSON;
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"doAddFavorite operation succeed");
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameCollectSongSuccess object:nil userInfo:nil];
                
            } else {
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                PLog(@"doAddFavorite operation failed: %@", msg);
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameCollectSongFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameCollectSongFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        PLog(@"doAddFavorite failure: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameCollectSongFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 添加黑名单
 <!--请求POST-->
 HTTP_ADDBLACKLIST
 */
-(void)doHateSong:(NSString *)ttoken uid:(NSString *)tuid sid:(long)tsid{
    
    PLog(@"do hate song url: %@", HTTP_HATESONG);
    
    AFHTTPClient* httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:HTTP_HATESONG]];
    
    NSString* httpBody = [NSString stringWithFormat:@"token=%@&uid=%@&songid=%ld", ttoken, tuid, tsid];
    
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        @try {
            
            NSDictionary* dicJson = JSON;
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"doHateSong operation succeed");
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameHateSongSuccess object:nil userInfo:nil];
                
            }
            else {
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                PLog(@"doHateSong operation failed: %@", msg);
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameHateSongFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameHateSongFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        PLog(@"doHateSong failure: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameHateSongFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 赠送歌曲
 <!--请求POST-->
 HTTP_PRESENTMUSIC
 */
-(void)doPresentMusic:(NSString *)senduid touid:(NSString *)ttouid token:(NSString *)ttoken sid:(long)tsid{
    
    PLog(@"present music url: %@", HTTP_PRESENTMUSIC);
    
    AFHTTPClient* httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:HTTP_PRESENTMUSIC]];
    
    NSString* httpBody = [NSString stringWithFormat:@"senduid=%@&touid=%@&token=%@&songid=%ld", senduid, ttouid, ttoken, tsid];
    
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        @try {
            
            NSDictionary* dicJson = JSON;
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"operation succeeded");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNamePresentMusicSuccess object:nil userInfo:nil];
                
            }
            else {
                
                PLog(@"operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNamePresentMusicFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNamePresentMusicFailed object:nil userInfo:dicResult];
            
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        PLog(@"failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNamePresentMusicFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 分享歌曲
 <!--请求POST-->
 HTTP_SHAREMUSIC
 */
-(void)doShareMusic:(NSString *)uid token:(NSString *)ttoken sid:(long)tsid platform:(int)tplatform{
    
    PLog(@"share music url: %@", HTTP_SHAREMUSIC);
    
    AFHTTPClient* httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:HTTP_SHAREMUSIC]];
    
    NSString* httpBody = [NSString stringWithFormat:@"uid=%@&token=%@&songid=%ld&platform=%d", uid, ttoken, tsid, tplatform];
    
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        @try {
            
            NSDictionary* dicJson = JSON;
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"operation succeeded");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameShareMusicSuccess object:nil userInfo:nil];
                
            }
            else {
                
                PLog(@"operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameShareMusicFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameShareMusicFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        PLog(@"failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameShareMusicFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 上传用户本地歌曲信息
 <!--请求POST-->
 HTTP_UPLOADMUSIC
 */
-(void)doUploadMusic:(NSString *)uid token:(NSString *)ttoken sid:(long)tsid enter:(int)tenter urlcode:(int)turlcode content:(long)tcontent{
    
    PLog(@"upload music url:%@", HTTP_UPLOADMUSIC);
    
    AFHTTPClient* httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:HTTP_UPLOADMUSIC]];
    
    NSString* httpBody = @"hehe";//TODO JSON

    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        @try {
            
            NSDictionary* dicJson = JSON;
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"operation succeeded");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUploadMusicSuccess object:nil userInfo:nil];
            }
            else {
                
                PLog(@"operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUploadMusicFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUploadMusicFailed object:nil userInfo:dicResult];
            
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        PLog(@"failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUploadMusicFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}


/*
 获取附近用户
 <!--请求GET-->
 HTTP_NEARBYUSER
 */
-(void)doGetNearbyUser:(NSString *)uid token:(NSString *)ttoken page:(int)tpage{
    
    NSString* url = [NSString stringWithFormat:@"%@&token=%@&uid=%@&page=%d", HTTP_NEARBYUSER,  ttoken, uid, tpage];
    PLog(@"get nearby user url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        @try {
            
            NSDictionary* dicJson = JSON;
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"operation succeeded");
                
                //TODO add user
                
            }
            else {
                
                PLog(@"operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameNearbyUserFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameNearbyUserFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        PLog(@"failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameNearbyUserFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 获取用户歌单
 <!--请求GET-->
 HTTP_GETUSERLIST
 */
-(void)doGetListFromUser:(NSString *)uid sid:(long)tsid token:(NSString *)ttoken{
    
    NSString* url = [NSString stringWithFormat:@"%@&token=%@&uid=%@&sid=%ld", HTTP_GETUSERLIST, ttoken, uid, tsid];
    PLog(@"get list from user url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        @try {
            
            NSDictionary* dicJson = JSON;
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"operation succeeded");
                
                Song* song = [Song initWithNSDictionary:[dicJson objectForKey:@"result"]];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:song, @"song", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUserListSuccess object:nil userInfo:dicResult];
                
            }
            else {
                
                PLog(@"operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUserListFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUserListFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        PLog(@"failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUserListFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 获取用户正在听的歌曲
 <!--请求GET-->
 HTTP_GETPLAYINGMUSIC
 */
-(void)doGetPlayingMusicFromUser:(NSString *)uid token:(NSString *)ttoken begin:(int)tbegin page:(int)tpage{
    
    NSString* url = [NSString stringWithFormat:@"%@&token=%@&uid=%@", HTTP_GETPLAYINGMUSIC, ttoken, uid];
    PLog(@"playing music url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        @try {
            
            NSDictionary* dicJson = JSON;
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"operation succeeded");
                
                Song* song = [Song initWithNSDictionary:[dicJson objectForKey:@"result"]];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:song, @"song", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNamePlayingMusicSuccess object:nil userInfo:dicResult];
                
            }
            else {
                
                PLog(@"operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNamePlayingMusicFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNamePlayingMusicFailed object:nil userInfo:dicResult];
            
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        PLog(@"failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNamePlayingMusicFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 获取频道目录
 <!--请求GET-->
 HTTP_GETCHANNEL
 */
-(void)doGetChannel:(NSString*)uid token:(NSString *)ttoken num:(int)tnum {
    
    NSString* url = [NSString stringWithFormat:@"%@?num=%d&token=%@&uid=%@", HTTP_GETCHANNEL, tnum, ttoken, uid];
    PLog(@"get channel url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            PLog(@"dicJson: %@", dicJson);
            
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get channel operation succeeded");
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                NSArray* dicChannels = [dicTemp objectForKey:@"channle"];
                
                NSMutableArray* channel = [[NSMutableArray alloc] init];
                
                for (int i=0; i<[dicChannels count]; i++) {
                    
                    Channel *tempChannel = [Channel initWithNSDictionary:[dicChannels objectAtIndex:i]];
                    [tempChannel log];
                    
                    [channel addObject:tempChannel];
                }
                
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:channel, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetChannelSuccess object:nil userInfo:dicResult];
                
            }
            else {
                
                PLog(@"get channel operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetChannelFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetChannelFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetChannelFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 获取频道歌曲
 <!--请求GET-->
 HTTP_GETCHANNELMUSIC
 */
-(void)doGetMusicFromChannel:(NSString*)uid token:(NSString *)ttoken channel:(int)tchannel {
    
    NSString* url = [NSString stringWithFormat:@"%@?uid=%@&token=%@&channel=%d", HTTP_GETCHANNELMUSIC, uid, ttoken, tchannel];
    PLog(@"get channel music url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            PLog(@"dicJson: %@", dicJson);
            
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get music from channel operation succeeded");
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                NSArray* arrChannels = [dicTemp objectForKey:@"channel"];
                
                NSMutableArray* songList = [[NSMutableArray alloc] init];
                
                for (int i=0; i<[arrChannels count]; i++) {
                    
                    Song *tempsong = [Song initWithNSDictionary:[arrChannels objectAtIndex:i]];
                    [tempsong log];
                    
                    [songList addObject:tempsong];
                }
                
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:songList, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetChannelMusicSuccess object:nil userInfo:dicResult];
                
            }
            else {
                
                PLog(@"get music from channel operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetChannelMusicFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetChannelMusicFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"get music from channel failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetChannelMusicFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 获取心情词描述
 <!--请求GET-->
 HTTP_MODESCENE
 */
-(void)doGetWorkOfMood:(NSString*)uid token:(NSString*)ttoken{
    
    NSString* url = [NSString stringWithFormat:@"%@?decword=mood&token=%@&uid=%@", HTTP_MOODSCENE, ttoken, uid];
    PLog(@"get mood url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get mood operation succeeded");
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                NSArray* wordlist = [dicTemp objectForKey:@"word"];
                int wordcount = [wordlist count];
                
                NSMutableArray* moodList = [[NSMutableArray alloc] init];
                
                for (int i=0; i<wordcount; i++) {
                    
                    Word *tempword = [Word initWithNSDictionary:[wordlist objectAtIndex:i]];
                    tempword.mode = @"mm";
                    [tempword log];
                    
                    [moodList addObject:tempword];
                }
                
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:moodList, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameMoodSuccess object:nil userInfo:dicResult];
                
            } else {
                
                PLog(@"get mood operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameMoodFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameMoodFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"get mood failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameMoodFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 获取场景词描述
 <!--请求GET-->
 HTTP_MOODSCENE
 */
-(void)doGetWorkOfScene:(NSString*)uid token:(NSString*)ttoken{
    
    NSString* url = [NSString stringWithFormat:@"%@?decword=scene&token=%@&uid=%@", HTTP_MOODSCENE, ttoken, uid];
    PLog(@"get scene url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get scene operation succeeded");
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                NSArray* wordlist = [dicTemp objectForKey:@"word"];
                int wordcount = [wordlist count];
                
                NSMutableArray* moodList = [[NSMutableArray alloc] init];
                
                for (int i=0; i<wordcount; i++) {
                    
                    Word *tempword = [Word initWithNSDictionary:[wordlist objectAtIndex:i]];
                    tempword.mode = @"ms";
                    [tempword log];
                    
                    [moodList addObject:tempword];
                }
                
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:moodList, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameSceneSuccess object:nil userInfo:dicResult];
                
            } else {
                
                PLog(@"get scene operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameSceneFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameSceneFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"get scene failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameSceneFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 获取心情，场景歌曲
 <!--请求GET-->
 HTTP_MODEMUSIC
 */
-(void)doGetModeMusic:(NSString*)uid token:(NSString *)ttoken wordid:(NSString *)twordid mood:(NSString *)tmood num:(int)tnum{
    
    NSString* url = [NSString stringWithFormat:@"%@?wordid=%@&mode=%@&token=%@&uid=%@&num=%d", HTTP_MODEMUSIC, twordid, tmood, ttoken, uid, tnum];
    PLog(@"get mode music url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
//            NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
//            PLog(@"doGetModeMusic result: %@", result);
//            NSData *tempData = [result dataUsingEncoding:NSUTF8StringEncoding];
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get mode music operation succeeded");
                
                int tempwordid = 0;
                if ([tmood isEqualToString:@"mm"]) {
                    tempwordid = [twordid intValue];
                }
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                NSArray *songlist = [dicTemp objectForKey:@"song"];
                int songcount = [songlist count];
                
                NSMutableArray* songInfoList = [[NSMutableArray alloc] init];
                for (int i=0; i<songcount; i++) {
                    
                    Song *song = [Song initWithNSDictionary:[songlist objectAtIndex:i]];
                    song.wordid = tempwordid;
                    [song log];
                    
                    [songInfoList addObject:song];
                }
                
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:songInfoList, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameModeMusicSuccess object:nil userInfo:dicResult];
                
            }
            else {
                
                PLog(@"get mode music operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameModeMusicFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameModeMusicFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"get mood music failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameModeMusicFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

-(void)doGetModeMusic:(NSString *)uid token:(NSString *)ttoken wordid:(NSString *)twordid mood:(NSString *)tmood{
    [self doGetModeMusic:uid token:ttoken wordid:twordid mood:tmood num:10];
}

/*
 获取心绪地图
 <!--请求GET-->
 HTTP_MODEMAP
 */
-(void)doGetMoodMap:(NSString *)uid token:(NSString *)ttoken{
    
    NSString* url = [NSString stringWithFormat:@"%@?token=%@&uid=%@", HTTP_MOODMAP, ttoken, uid];
    PLog(@"get mood map url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get mood map operation succeeded");
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                NSArray *moodlist = [dicTemp objectForKey:@"mood"];
                int moodcount = [moodlist count];
                
                NSMutableArray* moodInfoList = [[NSMutableArray alloc] init];
                for (int i=0; i<moodcount; i++) {
                    
                    Mood *mood = [Mood initWithNSDictionary:[moodlist objectAtIndex:i]];
                    [mood log];
                    
                    [moodInfoList addObject:mood];
                }
                
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:moodInfoList, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameMoodMapSuccess object:nil userInfo:dicResult];
                
            }
            else {
                
                PLog(@"get mood map operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameMoodMapFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameMoodMapFailed object:nil userInfo:dicResult];
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameMoodMapFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 获取心绪类别名称
 <!--请求GET-->
 HTTP_MOODPARENT
 */
-(void)doGetMoodParent:(NSString *)uid token:(NSString *)ttoken{
    
    NSString* url = [NSString stringWithFormat:@"%@?token=%@&uid=%@", HTTP_MOODPARENT, ttoken, uid];
    PLog(@"get mood parent url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get mood parent operation succeeded");
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                NSArray *moodlist = [dicTemp objectForKey:@"mood"];
                int moodcount = [moodlist count];
                
                NSMutableArray* moodInfoList = [[NSMutableArray alloc] init];
                for (int i=0; i<moodcount; i++) {
                    
                    Mood *mood = [Mood initWithNSDictionary:[moodlist objectAtIndex:i]];
                    [mood log];
                    
                    [moodInfoList addObject:mood];
                }
                
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:moodInfoList, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameMoodParentSuccess object:nil userInfo:dicResult];
                
            }
            else {
                
                PLog(@"get mood parent operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameMoodParentFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameMoodParentFailed object:nil userInfo:dicResult];
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameMoodParentFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 提交用户当前状态
 <!--请求POST-->
 HTTP_ADDMOODRECORD
 */
-(void)doAddMoodRecord:(NSString*)uid token:(NSString*)ttoken wordid:(int)twordid songid:(long long)tsongid{
    
    PLog(@"add mood record url: %@", HTTP_ADDMOODRECORD);
    
    AFHTTPClient* httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:HTTP_ADDMOODRECORD]];
    
    NSString* httpBody = [NSString stringWithFormat:@"token=%@&uid=%@&wordid=%d&songid=%lld", ttoken, uid, twordid, tsongid];
    PLog(@"add mood record body: %@", httpBody);
    
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"add mood record operation succeeded");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameAddMoodRecordSuccess object:nil userInfo:nil];
            } else {
                
                PLog(@"add mood record operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameAddMoodRecordFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameAddMoodRecordFailed object:nil userInfo:dicResult];
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameAddMoodRecordFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 设置用户位置 (2013-7-22)
 HTTP_SETUSERPOS
 POST
 */
-(void)doSetUserPos:(NSString*)uid token:(NSString*)ttoken location:(NSString *)tlocation{
    
    PLog(@"set user pos url: %@", HTTP_SETUSERPOS);
    
    AFHTTPClient* httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:HTTP_SETUSERPOS]];
    
    NSString* httpBody = [NSString stringWithFormat:@"token=%@&uid=%@&location=%@", ttoken, uid, tlocation];
    PLog(@"set user pos body: %@", httpBody);
    
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"set user pos operation succeeded");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameSetUserPosSuccess object:nil userInfo:nil];
            } else {
                
                PLog(@"set user pos operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameSetUserPosFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameSetUserPosFailed object:nil userInfo:dicResult];
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameSetUserPosFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 查找附近的人 (2013-7-22)
 HTTP_SEARCHNEARBY
 GET
 */
-(void)doSearchNearby:(NSString*)uid token:(NSString*)ttoken location:(NSString *)tlocation radius:(int)tradius{
    
    NSString* url = [NSString stringWithFormat:@"%@?token=%@&uid=%@&location=%@&radius=%d", HTTP_SEARCHNEARBY, ttoken, uid, tlocation, tradius];
    PLog(@"search nearby url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
//            NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
//            PLog(@"result: %@", result);
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"search nearby operation succeeded");
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                NSArray *nearuserlist = [dicTemp objectForKey:@"nearUser"];
                int nearusercount = [nearuserlist count];
                
                NSMutableArray *nearbyUserInfoList = [[NSMutableArray alloc] init];
                for (int i=0; i<nearusercount; i++) {
                    
                    NearbyUser *nearbyuser = [NearbyUser initWithNSDictionary:[nearuserlist objectAtIndex:i]];
                    [nearbyuser log];
                    
                    [nearbyUserInfoList addObject:nearbyuser];
                }
                
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:nearbyUserInfoList, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameSearchNearbySuccess object:nil userInfo:dicResult];
                
            }
            else {
                
                PLog(@"search nearby operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameSearchNearbyFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameSearchNearbyFailed object:nil userInfo:dicResult];
            
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameSearchNearbyFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 非注册用户获取播放列表（2013-08－17）
 */
-(void)doGetDefaultGuestSongs{
    
    NSString* url = [NSString stringWithFormat:@"%@", HTTP_GETDEFAULTGUESTSONGS];
    PLog(@"get default guest songs url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get default guest songs operation succeeded");
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                NSArray *songlist = [dicTemp objectForKey:@"song"];
                int songcount = [songlist count];
                
                NSMutableArray* songInfoList = [[NSMutableArray alloc] init];
                for (int i=0; i<songcount; i++) {
                    
                    Song *song = [Song initWithNSDictionary:[songlist objectAtIndex:i]];
                    [song log];
                    
                    [songInfoList addObject:song];
                }
                
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:songInfoList, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetDefaultGuestSongsSuccess object:nil userInfo:dicResult];
                
            }
            else {
                
                PLog(@"get default guest songs operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetDefaultGuestSongsFailed object:nil userInfo:dicResult];
                
            }
            
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败:(";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetDefaultGuestSongsFailed object:nil userInfo:dicResult];
            
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"get default guest songs failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetDefaultGuestSongsFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
    
}

/*
 获取收藏的歌曲
 <!--请求GET-->
 HTTP_CLTSONGS
 */
-(void)doGetCollectedSongs:(NSString *)uid token:(NSString *)ttoken taruid:(NSString*)ttaruid {
    
    NSString* url = [NSString stringWithFormat:@"%@?uid=%@&token=%@&taruid=%@", HTTP_GETCLTSONGS, uid, ttoken, ttaruid];
    PLog(@"get collected songs url:%@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get collected songs succeeded");
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                NSArray* songlist = [dicTemp objectForKey:@"song"];
                int songcount = [songlist count];
                
                NSMutableArray* songInfoList = [[NSMutableArray alloc] init];
                
                for (int i=0; i<songcount; i++) {
                    
                    Song* song = [Song initWithNSDictionary:[songlist objectAtIndex:i]];
                    [song log];
                    
                    [songInfoList addObject:song];
                }
                
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:songInfoList, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetCollectedSongsSuccess object:nil userInfo:dicResult];
            }
            else {
                
                PLog(@"get collected music failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetCollectedSongsFailed object:nil userInfo:dicResult];
         
            }
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败...";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetCollectedSongsFailed object:nil userInfo:dicResult];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"get collected songs failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetCollectedSongsFailed object:nil userInfo:nil];
    }];
    
    [operation start];
}

/*
 获取豆瓣的频道歌曲
 <!--请求GET-->
 HTTP_GETDBCHANNELSONG
 */
-(void)doGetDoubanChannelSong:(NSString*)uid token:(NSString*)ttoken channel:(NSString*)tchannel {
    
    NSString* url = [NSString stringWithFormat:@"%@?uid=%@&token=%@&channel=%@", HTTP_GETDBCHANNELSONG, uid, ttoken, tchannel];
    PLog(@"get douban channel song url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get douban channel song operation succeeded");
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                NSArray* songlist = [dicTemp objectForKey:@"channel"];
                int songcount = [songlist count];
                
                NSMutableArray* songInfoList = [[NSMutableArray alloc] init];
                for (int i=0; i<songcount; i++) {
                    
                    Song* song = [Song initWithNSDictionary:[songlist objectAtIndex:i]];
                    [song log];
                    
                    [songInfoList addObject:song];
                }
                
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:songInfoList, @"result", nil];
        
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetDbChannelSongSuccess object:nil userInfo:dicResult];
        
            }
            else {
                
                PLog(@"get douban channel song opeation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetDbChannelSongFailed object:nil userInfo:dicResult];
            }
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetDbChannelSongFailed object:nil userInfo:dicResult];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"get douban channel song failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetDbChannelSongFailed object:nil userInfo:nil];
    }];
    
    [operation start];
    
}

/*
 通过整体纬度获取音乐
 <!--请求GET-->
 HTTP_GETTYPESONGS
 */
-(void)doGetTypeSongs:(NSString*)uid token:(NSString*)ttoken moodid:(NSString*)tmoodid moodindex:(NSString*)tmoodindex sceneid:(NSString*)tsceneid sceneindex:(NSString*)tsceneindex channelid:(NSString*)tchannelid channelindex:(NSString*)tchannelindex {
    
    NSString* url = [NSString stringWithFormat:@"%@?uid=%@&token=%@&moodid=%@&moodindex=%@&sceneid=%@&sceneindex=%@&channelid=%@&channelindex=%@", HTTP_GETTYPESONGS, uid, ttoken, tmoodid, tmoodindex, tsceneid, tsceneindex, tchannelid, tchannelindex];
    PLog(@"get type songs url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"get type songs operation succeeded");
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                NSArray* songlist = [dicTemp objectForKey:@"song"];
                int songcount = [songlist count];
                
                NSMutableArray* songInfos = [[NSMutableArray alloc] init];
                
                for(int i=0; i<songcount; i++) {
                    
                    Song* song = [Song initWithNSDictionary:[songlist objectAtIndex:i]];
                    
                    [songInfos addObject:song];
                }
                
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:songInfos, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetTypeSongsSuccess object:nil userInfo:dicResult];
            }
            else {
                
                PLog(@"get type songs operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetTypeSongsFailed object:nil userInfo:dicResult];
            }
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetTypeSongsFailed object:nil userInfo:dicResult];
            
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"get type songs failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameGetTypeSongsFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
}

/*
 提交本地歌曲信息(2013-08-19)
 <!--请求POST-->
 HTTP_RECORDLOCALSONGS
 */
-(void)doRecordLocalSongs:(NSString*)uid token:(NSString*)ttoken source:(NSString*)tsource urlcode:(NSString*)turlcode name:(NSString*)tname content:(NSString*)tcontent {
    
    NSString* url = [NSString stringWithFormat:@"%@?uid=%@&token=%@&source=%@&urlcode=%@&name=%@", HTTP_RECORDLOCALSONGS, uid, ttoken, tsource, turlcode, tname];
    PLog(@"record local songs url: %@", url);
    
    AFHTTPClient* httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:url]];
    
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[tcontent dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFJSONRequestOperation* operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        @try {
            
            NSDictionary* dicJson = JSON;
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"record local songs operation succeeded");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRecordLocalSongsSuccess object:nil userInfo:nil];
            }
            else {
                
                PLog(@"record local songs operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRecordLocalSongsFailed object:nil userInfo:dicResult];
            }
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据信息失败";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRecordLocalSongsFailed object:nil userInfo:dicResult];
            
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        PLog(@"record local songs failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRecordLocalSongsFailed object:nil userInfo:nil];
        
    }];
    
    [operation start];
}

/*
 获取推送消息
 <!--请求GET-->
 HTTP_GETPUSHMSG
 */
-(void)doGetPushMsg:(NSString*)uid token:(NSString*)ttoken pageindex:(NSString*)tpageindex rec:(NSString*)trec {
    
    NSString* url = [NSString stringWithFormat:@"%@?uid=%@&token=%@&Page_index=%@&Rec_per_page=%@", HTTP_GETPUSHMSG, uid, ttoken, tpageindex, trec];
    PLog(@"get push message url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if (1 == status) {
                
                PLog(@"get push message operation succeeded");
                
            }
        }
        @catch (NSException *exception) {
            
            ;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        
    }];
    
    [operation start];
}

/*
 更新音乐纬度配置文件
 <!--请求GET-->
 HTTP_UPDATECONFIGFILE
 */
-(void)doUpdateConfigfile:(NSString*)uid token:(NSString*)ttoken version:(NSString*)tversion {
    
    NSString* url = [NSString stringWithFormat:@"%@?uid=%@&token=%@&version=%@", HTTP_UPDATECONFIGFILE, uid, ttoken, tversion];
    PLog(@"update config file url: %@", url);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"update config file operation succeeded");
                
                NSDictionary* dicTemp = [dicJson objectForKey:@"result"];
                ConfigFileInfo* cfi = [ConfigFileInfo initWithNSDictionary:dicTemp];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:cfi, @"result", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUpdateConfigSuccess object:nil userInfo:dicResult];
                
            }
            else {
                
                PLog(@"update config file operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUpdateConfigFailed object:nil userInfo:dicResult];
            }
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUpdateConfigFailed object:nil userInfo:dicResult];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"update config file failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameUpdateConfigFailed object:nil userInfo:nil];
    }];
    
    [operation start];
}

/*
 记录用户试听歌曲状态
 <!--请求POST-->
 HTTP_RECORDCURSONG
 */
-(void)doRecordCurrentSong:(NSString*)uid token:(NSString*)ttoken lastsong:(NSString*)tlastsong cursong:(NSString*)tcursong mood:(NSString*)tmood name:(NSString*)tname singer:(NSString*)tsinger state:(NSString*)tstate {
    
    PLog(@"record current song url: %@", HTTP_RECORDCURSONG);
    
    AFHTTPClient* httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:HTTP_RECORDCURSONG]];
    
    NSString* httpBody = [NSString stringWithFormat:@"uid=%@&token=%@&lastsong=%@&cursong=%@&mood=%@&name=%@&singer=%@&state=%@", uid, ttoken, tlastsong, tcursong, tmood, tname, tsinger, tstate];
    PLog(@"record current song body: %@", httpBody);
    
    NSMutableURLRequest* request = [httpClient requestWithMethod:@"POST" path:nil parameters:nil];
    [request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        @try {
            
            NSDictionary* dicJson = [NSJSONSerialization JSONObjectWithData:responseObject options:nil error:nil];
            int status = [[dicJson objectForKey:@"status"] intValue];
            
            if(1 == status) {
                
                PLog(@"record current song operation succeeded");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRecordCurSongSuccess object:nil userInfo:nil];
            }
            else {
                
                PLog(@"record current song operation failed");
                
                NSString* msg = [dicJson objectForKey:@"msg"];
                NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRecordCurSongFailed object:nil userInfo:dicResult];
                
            }
        }
        @catch (NSException *exception) {
            
            NSString* msg = @"解析返回数据失败";
            NSDictionary* dicResult = [NSDictionary dictionaryWithObjectsAndKeys:msg, @"msg", nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRecordCurSongFailed object:nil userInfo:dicResult];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        PLog(@"update config file failure: %@", error);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNameRecordCurSongFailed object:nil userInfo:nil];
    }];
    
    [operation start];
}

@end
