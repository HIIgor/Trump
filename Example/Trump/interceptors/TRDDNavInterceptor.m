//
//  TRDDNavInterceptor.m
//  Trump_Example
//
//  Created by igor xiang on 2021/5/8.
//  Copyright © 2021 Igor Xiang. All rights reserved.
//

#import "TRDDNavInterceptor.h"
#import <SSZipArchive/SSZipArchive.h>

@implementation TRDDNavInterceptor

- (void)didFinishDownloadFile:(NSString *)filename atPath:(NSString *)dir {
    NSLog(@"文件下载完成~~~~~ %@, %@  %@", [self moduleName], filename, dir);
}

- (BOOL)shouldPreloadFile:(NSString *)filename {
    return YES;
}

- (nonnull NSString *)moduleName {
    return @"DDBachVoiceService";
}


@end
