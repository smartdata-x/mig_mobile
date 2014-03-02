//
//  MessageInfoCell.m
//  miglab_mobile
//
//  Created by pig on 13-8-25.
//  Copyright (c) 2013年 pig. All rights reserved.
//

#import "MessageInfoCell.h"

@implementation MessageInfoCell

@synthesize btnAvatar = _btnAvatar;
@synthesize lblMessageType = _lblMessageType;
@synthesize lblContent = _lblContent;
@synthesize msginfo = _msginfo;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)updateMessageInfoCellData:(MessageInfo *)msg {
    
    _msginfo = msg;
    NSString* username = _msginfo.userInfo.nickname;
    
    _btnAvatar.imageURL = [NSURL URLWithString:msg.userInfo.headurl];
    _btnAvatar.layer.cornerRadius = _btnAvatar.frame.size.width / 2;
    _btnAvatar.layer.masksToBounds = YES;
    
    if(_msginfo.messagetype == 2) {
        //送歌曲
        
        _lblMessageType.text = [NSString stringWithFormat:@"%@送了一首歌曲给你", username];
    }
    else if(_msginfo.messagetype == 3) {
        //评论歌曲
        
        _lblMessageType.text = [NSString stringWithFormat:@"%@评论了你个歌曲", username];
    }
    else {
        // 打招呼
        
        _lblMessageType.text = [NSString stringWithFormat:@"%@给你打了一个招呼", username];
    }
    
    _lblContent.text = _msginfo.content;
}

@end
