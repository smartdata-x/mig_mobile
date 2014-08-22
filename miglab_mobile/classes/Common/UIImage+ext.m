//
//  UIImage+ext.m
//  miglab_mobile
//
//  Created by Archer_LJ on 14-8-11.
//  Copyright (c) 2014年 pig. All rights reserved.
//

#import "UIImage+ext.h"
#import "GlobalDataManager.h"
#import "UIImage+BlurredFrame.h"

@implementation UIImage_ext

@synthesize imgContext = _imgContext;

+(UIImage_ext *)GetInstance {
    
    static UIImage_ext* instance = nil;

    @synchronized(self) {
        
        if (nil == instance) {
            
            instance = [[self alloc] init];
        }
    }
    
    return instance;
}

-(UIImage *)imageFromText:(UIImage *)image txt:(NSString *)text andFont:(UIFont *)font andFrame:(CGRect)frame{
    
    UIGraphicsBeginImageContext(image.size);
    [image drawAtPoint:CGPointZero];
    
    [[UIColor whiteColor] set];
    
    [text drawInRect:frame withFont:font];
    
    UIImage *finalImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return finalImg;
}

-(UIImage *)drawImageIntoImage:(UIImage *)dstImg andSrcImg:(UIImage *)srcImg andFrame:(CGRect)frame {
    
    UIGraphicsBeginImageContext(dstImg.size);
    
    [dstImg drawInRect:CGRectMake(0, 0, dstImg.size.width, dstImg.size.height)];
    
    [srcImg drawInRect:frame blendMode:kCGBlendModeNormal alpha:1.0];
    
    UIImage *finalImg = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return finalImg;
}

-(float)getFontSize:(NSString *)str andFontName:(NSString *)fontName andSize:(CGSize)size{
    
    CGFloat finalFontSize = MIN_LYRIC_FONT_SIZE;
    BOOL foundSize = NO;
    
    do {
        
        CGSize charSize = [str sizeWithFont:[UIFont fontWithName:fontName size:finalFontSize] constrainedToSize:CGSizeMake(size.width, CGFLOAT_MAX) lineBreakMode:UILineBreakModeCharacterWrap];
        
        if (charSize.height > size.height) {
            
            foundSize = YES;
        }
        else {
            
            finalFontSize += 1.0;
        }
        
    }while (!foundSize);
    
    return finalFontSize;
}

-(UIImage *)blurImage:(UIImage *)image andRect:(CGRect)blurRect {
    
    CIImage *inputImage = [CIImage imageWithCGImage:image.CGImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:kCIInputImageKey, inputImage, @"inputRadius", @(2), nil];
    
    CIImage *outputImage = filter.outputImage;
    
    if (!_imgContext) {
        
        _imgContext = [CIContext contextWithOptions:nil];
    }
    
    CGImageRef outImage = [_imgContext createCGImage:outputImage fromRect:blurRect];
    
    return [UIImage imageWithCGImage:outImage];
}

-(NSString *)addReturns:(NSString *)srcStr {
    
    NSMutableString *outStr = [[NSMutableString alloc] init];
    
    int count = [srcStr length];
    
    for (int i=0; i<count; i++) {
        
        [outStr appendFormat:@"%hu\\n", [srcStr characterAtIndex:i]];
    }
    
    return outStr;
}

-(UIImage *)createLyricShareImage:(LyricShare *)ls song:(Song *)tsong {
    
    NSString* fontname = @"Helvetica";
    
    UIImage* bgImg;
    UIImage* mainIconImg = [UIImage imageNamed:@"main_logo_white.png"];
    UIImage* iconImg = [UIImage imageNamed:@"code.png"];
    int imgWidth, imgHeight;
    CGRect songNameRect, artistRect, lyricRect, weatherRect, modeRect, temperatureRect, dateRect, addressRect, mainIconRect, toastRect, iconRect;
    CGRect rcGroupUp, rcGroupDown, rcGroupBottom;
    
    if (1) {
        
        bgImg = [UIImage imageNamed:@"sleep_bg.png"];
        
        imgWidth = bgImg.size.width;
        imgHeight = bgImg.size.height;
        
        rcGroupUp = CGRectMake(484, 44, 156, 156);
        rcGroupDown = CGRectMake(484, 210, 156, 156);
        rcGroupBottom = CGRectMake(0, 1035, imgWidth, 140);
        
        lyricRect = CGRectMake(0, 366, imgWidth, imgHeight - 366 - 140);
        
        songNameRect = CGRectMake(60, 44, 58, 166);
        artistRect = CGRectMake(158, 210, 40, 166);
        weatherRect = CGRectMake(484, 74, 156, 48);
        modeRect = CGRectMake(484, 122, 156, 48);
        temperatureRect = CGRectMake(484, 234, 156, 48);
        dateRect = CGRectMake(484, 282, 156, 25);
        addressRect = CGRectMake(484, 307, 156, 35);
        
        mainIconRect = CGRectMake(38, imgHeight - 140 - 21, 130, 98);
        toastRect = CGRectMake(38 + 140, imgHeight - 140, imgWidth - 38 - 140 - 38 - 96, 140);
        iconRect = CGRectMake(38 + 140 + toastRect.size.width, toastRect.origin.y, 96, 96);
    }
    else {
        
        bgImg = [UIImage imageNamed:@"sleep_bg_ip4.png"];
    }
    
    bgImg = [bgImg applyLightEffectAtFrame:rcGroupUp];
    bgImg = [bgImg applyLightEffectAtFrame:rcGroupDown];
    bgImg = [bgImg applyLightEffectAtFrame:rcGroupBottom];
    //bgImg = [self blurImage:bgImg andRect:rcGroupUp];
    //bgImg = [self blurImage:bgImg andRect:rcGroupDown];
    //bgImg = [self blurImage:bgImg andRect:rcGroupBottom];
    
    NSString *szSongName = tsong.songname;
    NSString *szArtist = tsong.artist;
    NSString *szLyric = ls.lyric;
    NSString *szMode = @"睡觉中";
    NSString *szTemperature = ls.temprature;
    NSString *szDate = @"2014/08/19";
    NSString *szAddress = ls.address;
    NSString *szToast = MIGTIP_THE_GOAL;
    
#if 1
    
    szSongName = @"你爱我像谁";
    szAddress = @"张卫健";
    szLyric = @"我什么都没有\n只是有一点吵\n如果你感到寂寞\n我带给你热闹\n为你绕一绕\n没有什么大不了\n却可以让你微笑\n其实我很烦恼\n只是你看不到\n如果我也不开心\n怕你转身就逃\n爱上一个人\n一定要让他相信\n这世界多么美好";
    szTemperature = @"22.c";
    szAddress = @"HangZhou";
    
#endif
    
    float fSongName = 58;
    float fArtist = 40;
    float fLyric = 30;
    float fMode = 40;
    float fTemperature = 40;
    float fDate = 22;
    float fAddress = 24;
    float fToast = 24;
    
    UIGraphicsBeginImageContext(CGSizeMake(imgWidth, imgHeight));
    
    [bgImg drawInRect:CGRectMake(0, 0, imgWidth, imgHeight)];
    
    [mainIconImg drawInRect:mainIconRect];
    [iconImg drawInRect:iconRect];
    
    [[UIColor whiteColor] set];
    
    if (MIG_NOT_EMPTY_STR(szSongName)) {
        
        [szSongName drawInRect:songNameRect withFont:[UIFont fontWithName:fontname size:fSongName] lineBreakMode:UILineBreakModeWordWrap alignment:NSTextAlignmentCenter];
    }
    
    if (MIG_NOT_EMPTY_STR(szArtist)) {
        
        [szArtist drawInRect:artistRect withFont:[UIFont fontWithName:fontname size:fArtist] lineBreakMode:UILineBreakModeWordWrap alignment:NSTextAlignmentCenter];
    }
    
    if (MIG_NOT_EMPTY_STR(szLyric)) {
        
        [szLyric drawInRect:lyricRect withFont:[UIFont fontWithName:fontname size:fLyric] lineBreakMode:UILineBreakModeWordWrap alignment:NSTextAlignmentCenter];
    }
    
    if (MIG_NOT_EMPTY_STR(szMode)) {
        
        [szMode drawInRect:modeRect withFont:[UIFont fontWithName:fontname size:fMode] lineBreakMode:UILineBreakModeWordWrap alignment:NSTextAlignmentCenter];
    }
    
    if (MIG_NOT_EMPTY_STR(szTemperature)) {
        
        [szTemperature drawInRect:temperatureRect withFont:[UIFont fontWithName:fontname size:fTemperature] lineBreakMode:UILineBreakModeWordWrap alignment:NSTextAlignmentCenter];
    }
    
    if (MIG_NOT_EMPTY_STR(szDate)) {
        
        [szDate drawInRect:dateRect withFont:[UIFont fontWithName:fontname size:fDate] lineBreakMode:UILineBreakModeWordWrap alignment:NSTextAlignmentCenter];
    }
    
    if (MIG_NOT_EMPTY_STR(szAddress)) {
        
        [szAddress drawInRect:addressRect withFont:[UIFont fontWithName:fontname size:fAddress] lineBreakMode:UILineBreakModeWordWrap alignment:NSTextAlignmentCenter];
    }
    
    if (MIG_NOT_EMPTY_STR(szToast)) {
        
        [szToast drawInRect:toastRect withFont:[UIFont fontWithName:fontname size:fToast]];
    }
    
    UIImage* shareImg = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    UIImageWriteToSavedPhotosAlbum(shareImg, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    return shareImg;
}

-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    NSString *msg = nil;
    
    if (error == nil) {
        
        msg = @"cheng";
    }
    else {
        
        msg = @"shibai";
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"save" message:msg delegate:self cancelButtonTitle:@"sure" otherButtonTitles:nil];
    
    [alert show];
}

@end
