//
//  TRSafetyInterceptor.m
//  Trump_Example
//
//  Created by igor xiang on 2021/5/8.
//  Copyright © 2021 Igor Xiang. All rights reserved.
//

#import "TRSafetyInterceptor.h"
#import <SSZipArchive/SSZipArchive.h>

@implementation TRSafetyInterceptor

- (void)didFinishDownloadFile:(NSString *)filename atPath:(NSString *)path {
    NSLog(@"文件下载完成~~~~~ %@, %@  %@", [self moduleName], filename, path );
}

- (BOOL)shouldPreloadFile:(NSString *)filename {
    return NO;
}

- (nonnull NSString *)moduleName {
    return @"DDSafety";
}

@end
