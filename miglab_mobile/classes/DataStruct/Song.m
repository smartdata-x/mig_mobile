//
//  Song.m
//  miglab_mobile
//
//  Created by apple on 13-6-27.
//  Copyright (c) 2013年 pig. All rights reserved.
//

#import "Song.h"

@implementation Song

@synthesize songid = _songid;
@synthesize songname = _songname;
@synthesize artist = _artist;
@synthesize pubtime = _pubtime;
@synthesize album = _album;
@synthesize duration = _duration;
@synthesize songurl = _songurl;
@synthesize hqurl = _hqurl;
@synthesize lrcurl = _lrcurl;
@synthesize coverurl = _coverurl;
@synthesize like = _like;
@synthesize wordid = _wordid;
@synthesize songtype = _songtype;

@synthesize songCachePath = _songCachePath;

@synthesize whereIsTheSong = _whereIsTheSong;

+(id)initWithNSDictionary:(NSDictionary *)dict{
    
    Song *song = nil;
    
    @try {
        
        if (dict && [dict isKindOfClass:[NSDictionary class]]) {
            
            song = [[Song alloc] init];
            song.songid = [[dict objectForKey:@"id"] longLongValue];
            song.songname = [dict objectForKey:@"title"];
            song.artist = [dict objectForKey:@"artist"];
            song.pubtime = [dict objectForKey:@"pub_time"];
            song.album = [dict objectForKey:@"album"];
            song.duration = [dict objectForKey:@"time"];
//            song.songurl = [dict objectForKey:@"url"];
            song.songurl = [dict objectForKey:@"hqurl"];
            song.hqurl = [dict objectForKey:@"hqurl"];
            song.lrcurl = [dict objectForKey:@"lrcurl"];
            song.coverurl = [dict objectForKey:@"pic"];
            song.like = [dict objectForKey:@"like"];
            
        }
        
    }
    @catch (NSException *exception) {
        PLog(@"parser Song failed...please check");
    }
    
    return song;
}

-(void)log{
    
    PLog(@"Print Song: songid(%lld), songname(%@), artist(%@), pubtime(%@), album(%@), duration(%@), songurl(%@), hqurl(%@), lrcurl(%@), coverurl(%@), like(%@), wordid(%d), songtype(%d)", _songid, _songname, _artist, _pubtime, _album, _duration, _songurl, _hqurl, _lrcurl, _coverurl, _like, _wordid, _songtype);
    
}

@end
