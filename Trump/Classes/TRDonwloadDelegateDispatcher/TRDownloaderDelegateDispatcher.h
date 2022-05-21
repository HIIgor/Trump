//
//  TRDownloaderDelegateDispatcher.h
//  Trump
//
//  Created by igor xiang on 2021/7/7.
//

#import <Foundation/Foundation.h>
#import "TRDownloader.h"

NS_ASSUME_NONNULL_BEGIN

/// 下载资源处理逻辑中间层,做delegate的分发
@interface TRDownloaderDelegateDispatcher : NSObject <TRDownloaderDelegate>

- (instancetype)initWithInterceptors:(NSArray <TRDownloaderDelegate> *)interceptors;

@end

NS_ASSUME_NONNULL_END
