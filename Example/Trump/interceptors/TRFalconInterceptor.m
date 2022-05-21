//
//  TRFalconInterceptor.m
//  Trump_Example
//
//  Created by igor xiang on 2021/5/12.
//  Copyright © 2021 Igor Xiang. All rights reserved.
//

#import "TRFalconInterceptor.h"
#import <SSZipArchive/SSZipArchive.h>
#import <CoreText/CoreText.h>

@implementation TRFalconInterceptor

- (void)didFinishDownloadFile:(NSString *)filename atPath:(NSString *)path {
    NSLog(@"文件下载完成~~~~~ %@, %@  %@", [self moduleName], filename, path );
    
    
    NSString * fontPath = [path stringByAppendingPathComponent:filename];
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
}

- (BOOL)shouldPreloadFile:(NSString *)filename {
    return YES;
}

- (nonnull NSString *)moduleName {
    return @"Falcon";
}

@end
