//
//  TRExplictDownloadCallback.h
//  Trump
//
//  Created by igor xiang on 2021/7/7.
//

#import <Foundation/Foundation.h>
#import "TRDownloader.h"
#import "TRSourceManager.h"

NS_ASSUME_NONNULL_BEGIN
// 存储主动触发任务下载完成的回调,配合分发器使用
@interface TRExplictDownloadCallback : NSObject <TRDownloaderDelegate>

- (instancetype)initWithCallBack:(TRSourceResultCallback)callback;

@end

NS_ASSUME_NONNULL_END
