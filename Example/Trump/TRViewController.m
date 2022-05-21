//
//  TRViewController.m
//  Trump
//
//  Created by Igor Xiang on 04/29/2021.
//  Copyright (c) 2021 Igor Xiang. All rights reserved.
//

#import "TRViewController.h"
#import <Trump/Trump.h>
#import <SSZipArchive/SSZipArchive.h>
#import "TRDDNavInterceptor.h"
#import "TRSafetyInterceptor.h"
#import "TRFalconInterceptor.h"
#import <CoreText/CoreText.h>

@interface TRViewController ()

@property (nonatomic, weak) UIImageView *imgView0;
@property (nonatomic, weak) UIImageView *imgView1;
@property (nonatomic, weak) UIImageView *imgView2;
@property (nonatomic, weak) UILabel *label;
@property (nonatomic, assign) CGFloat fontsize;
@end

@implementation TRViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.fontsize = 20;
    NSArray <TRSourceProtocol> *interceptors = [NSArray <TRSourceProtocol> arrayWithObjects: [TRSafetyInterceptor new], [TRDDNavInterceptor new], [TRFalconInterceptor new], nil];
    [TRSourceManager startWithInterceptors:interceptors];

    CGFloat width = CGRectGetWidth(self.view.bounds) / 3;
    UIImageView *imgView0 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 200, width, width)];
    UIImageView *imgView1 = [[UIImageView alloc] initWithFrame:CGRectMake(width, 200, width, width)];
    UIImageView *imgView2 = [[UIImageView alloc] initWithFrame:CGRectMake(width * 2, 200, width, width)];
    imgView0.layer.borderColor = [UIColor redColor].CGColor;
    imgView1.layer.borderColor = [UIColor yellowColor].CGColor;
    imgView2.layer.borderColor = [UIColor greenColor].CGColor;
    imgView0.layer.borderWidth = 1;
    imgView1.layer.borderWidth = 1;
    imgView2.layer.borderWidth = 1;

    self.imgView0 = imgView0;
    self.imgView1 = imgView1;
    self.imgView2 = imgView2;
    [self.view addSubview:self.imgView0];
    [self.view addSubview:self.imgView1];
    [self.view addSubview:self.imgView2];
    
    [self prepareFont];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 220 + width, width * 3, 40)];
    UIFont *font = [UIFont fontWithName:@"造字工房坚黑体" size:self.fontsize];
    label.font = font;
    label.text = @"点我点我!";
    label.textAlignment = NSTextAlignmentCenter;
    label.userInteractionEnabled = YES;
    UITapGestureRecognizer *click = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(click)];
    [label addGestureRecognizer:click];
    self.label = label;
    [self.view addSubview:label];
    
    TRSource *source = [TRSourceManager sourceWithModule:@"Safety" file:@"images.zip" isDir:YES];
    
    
    NSString *imgpath0 = [source subfilePathForName:@"address_from@2x.png"];
    self.imgView0.image = [UIImage imageWithContentsOfFile:imgpath0];
    
    NSString *imagePath1 = [source subfilePathForName:@"combined_shape@2x.png"];
    self.imgView1.image = [UIImage imageWithContentsOfFile:imagePath1];
    
    NSString *imagePath2 = [source subfilePathForName:@"fd_CenterIcon@3x.png"];
    self.imgView2.image = [UIImage imageWithContentsOfFile:imagePath2];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
    [self.imgView2 addGestureRecognizer:tap];
    self.imgView2.userInteractionEnabled = YES;
}

- (void)prepareFont {
    TRSource *source = [TRSourceManager sourceWithModule:@"Falcon" file:@"造字工房坚黑体.ttf"];
    CGDataProviderRef fontDataProvider = CGDataProviderCreateWithFilename([source.filePath UTF8String]);
    CGFontRef customfont = CGFontCreateWithDataProvider(fontDataProvider);
    CGDataProviderRelease(fontDataProvider);
    NSString *fontName = (__bridge NSString *)CGFontCopyFullName(customfont);
    CFErrorRef error;
    CTFontManagerRegisterGraphicsFont(customfont, &error);
    if (error){
        // 为了可以重复注册
        CTFontManagerUnregisterGraphicsFont(customfont, &error);
        CTFontManagerRegisterGraphicsFont(customfont, &error);
    }
    CGFontRelease(customfont);
}

- (void)tap {
    [[TRSourceManager defaultManager] requestSourceWithModule:@"Safety" fileName:@"images.zip" completion:^(NSString * _Nonnull fileDir, NSString * _Nonnull fileName, TRSourceResultType type) {
        if (type == TRSourceDownloadSuccess) {
            NSLog(@"主动下载完成 ~ fileToPath - %@ filename - %@", fileDir, fileName);
            NSString *fileToPath = [fileDir stringByAppendingPathComponent:fileName];
            [SSZipArchive unzipFileAtPath:fileToPath toDestination:fileDir];
            TRSource *source = [TRSourceManager sourceWithModule:@"DDSafety" file:@"images.zip" isDir:YES];
            NSLog(@"file dir - %@", source.filePath);
            
            NSString *imgpath0 = [source subfilePathForName:@"address_from@2x.png"];
            self.imgView0.image = [UIImage imageWithContentsOfFile:imgpath0];
            
            NSString *imagePath1 = [source subfilePathForName:@"combined_shape@2x.png"];
            self.imgView1.image = [UIImage imageWithContentsOfFile:imagePath1];
            
            NSString *imagePath2 = [source subfilePathForName:@"fd_CenterIcon@3x.png"];
            self.imgView2.image = [UIImage imageWithContentsOfFile:imagePath2];
        }
    }];
    

}

- (void)click {
        [[TRSourceManager defaultManager] requestSourceWithModule:@"Falcon" fileName:@"造字工房坚黑体.ttf" completion:^(NSString * _Nonnull fileDir, NSString * _Nonnull fileName, TRSourceResultType type) {
            if (type == TRSourceDownloadSuccess || type == TRSourceLocalExists) {
                NSString * fontPath = [fileDir stringByAppendingPathComponent:fileName];
                CGDataProviderRef fontDataProvider = CGDataProviderCreateWithFilename([fontPath UTF8String]);
                CGFontRef customfont = CGFontCreateWithDataProvider(fontDataProvider);
                CGDataProviderRelease(fontDataProvider);
                NSString *fontName = (__bridge NSString *)CGFontCopyFullName(customfont);
                CFErrorRef error;
                CTFontManagerRegisterGraphicsFont(customfont, &error);
                if (error){
                    // 为了可以重复注册
                    CTFontManagerUnregisterGraphicsFont(customfont, &error);
                    CTFontManagerRegisterGraphicsFont(customfont, &error);
                }
                CGFontRelease(customfont);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.label.font = [UIFont fontWithName:fontName size:self.fontsize++];
                });
            }
        }];
}

@end
