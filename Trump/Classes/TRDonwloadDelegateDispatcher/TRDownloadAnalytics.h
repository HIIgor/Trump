//
//  TRDownloadAnalytics.h
//  Trump
//
//  Created by igor xiang on 2021/7/7.
//

#import <Foundation/Foundation.h>
#import "TRDownloader.h"

NS_ASSUME_NONNULL_BEGIN
// 处理下载声明周期中的埋点,配合分发器使用
@interface TRDownloadAnalytics : NSObject <TRDownloaderDelegate>

@end

NS_ASSUME_NONNULL_END
