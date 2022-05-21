//
//  TRDownloader_Internal.h
//  Pods
//
//  Created by igor xiang on 2021/7/6.
//

#ifndef TRDownloader_Internal_h
#define TRDownloader_Internal_h

#import "TRDownloader.h"

@interface TRDownloader ()

@property (nonatomic, copy) void (^firstResponseBlock)(NSURLResponse *response);
@property (nonatomic, copy) void (^progressBlock)(uint64_t receivedLength, uint64_t totalLength, NSInteger remainingTime, float progress);
@property (nonatomic, copy) void (^errorBlock)(NSError *error);
@property (nonatomic, copy) void (^completeBlock)(BOOL downloadFinished, NSString *pathToFile);

@end

#endif /* TRDownloader_Internal_h */
