//
//  TRSourceAnalytics.m
//  Trump
//
//  Created by igor xiang on 2021/7/7.
//

#import "TRDownloadAnalytics.h"
#import "TRSourceModel.h"


@implementation TRDownloadAnalytics

- (void)download:(TRDownloader *)blobDownload didReceiveFirstResponse:(NSURLResponse *)response {
    TRSourceInfo *info = blobDownload.model;
    //TODO: 开始时间放到TRDownloader中
    info.beginTime = [[NSDate date] timeIntervalSince1970];
}

- (void)download:(TRDownloader *)blobDownload didReceiveData:(uint64_t)receivedLength onTotal:(uint64_t)totalLength progress:(float)progress {
    TRSourceInfo *info = blobDownload.model;
    info.totalLength = totalLength;
    info.receivedLength = receivedLength;
}

- (void)download:(TRDownloader *)blobDownload didStopWithError:(NSError *)error {
    TRSourceInfo *info = blobDownload.model;
    NSString *code = [NSString stringWithFormat:@"%@", error.userInfo[TRDownloaderrorHTTPStatusKey]];
    NSString *resume = blobDownload.beginContentLength > 0 ? @"1" : @"0";
    NSString *dl_size = [NSString stringWithFormat:@"%llu", info.receivedLength - info.beginContentLength];
    NSString *total_size = [NSString stringWithFormat:@"%llu", info.totalLength];
    NSString *dur = [NSString stringWithFormat:@"%.lf", [[NSDate date] timeIntervalSince1970] - info.beginTime];
    NSString *trigger = info.isExplicitTrigger ? @"1" : @"0";
//    [YourEventSDK event:@"tech_assets_downloader_task" parameters:@{
//        @"key" : info.module ?: @"",
//        @"ret_code" : code ?: @"",
//        @"resume" : resume,
//        @"dl_size" : dl_size,
//        @"total_size" : total_size,
//        @"dur" : dur,
//        @"trigger" : trigger
//    }];
}

- (void)download:(TRDownloader *)blobDownload didFinishWithSuccess:(BOOL)downloadFinished atPath:(NSString *)pathToFile {
    if (downloadFinished) {
        TRSourceInfo *info = blobDownload.model;
        NSString *code = [NSString stringWithFormat:@"%td", ((NSHTTPURLResponse *)blobDownload.dataTask.response).statusCode];
        NSString *resume = blobDownload.beginContentLength > 0 ? @"1" : @"0";
        NSString *dl_size = [NSString stringWithFormat:@"%llu", info.receivedLength - info.beginContentLength];
        NSString *total_size = [NSString stringWithFormat:@"%llu", info.totalLength];
        NSString *dur = [NSString stringWithFormat:@"%.lf", [[NSDate date] timeIntervalSince1970] - info.beginTime];
        NSString *trigger = info.isExplicitTrigger ? @"1" : @"0";
//        [YourEventSDK event:@"tech_assets_downloader_task" parameters:@{
//            @"key" : info.module ?: @"",
//            @"ret_code" : code ?: @"",
//            @"resume" : resume,
//            @"dl_size" : dl_size,
//            @"total_size" : total_size,
//            @"dur" : dur,
//            @"trigger" : trigger
//        }];
    }
}

@end
