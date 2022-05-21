//
//  TRDownloaderDelegateDispatcher.m
//  Trump
//
//  Created by igor xiang on 2021/7/7.
//

#import "TRDownloaderDelegateDispatcher.h"

@interface TRDownloaderDelegateDispatcher ()

@property (nonatomic, copy) NSArray *interceptors;

@end

@implementation TRDownloaderDelegateDispatcher

- (instancetype)initWithInterceptors:(NSArray <TRDownloaderDelegate> *)interceptors {
    self = [super init];
    if (self) {
        _interceptors = interceptors;
    }
    
    return self;
}

#pragma mark - delegate

- (void)download:(TRDownloader *)blobDownload didReceiveFirstResponse:(NSURLResponse *)response {
    for (id obj in self.interceptors) {
        if ([obj respondsToSelector:@selector(download:didReceiveFirstResponse:)]) {
            [obj download:blobDownload didReceiveFirstResponse:response];
        }
    }
}

- (void)download:(TRDownloader *)blobDownload didReceiveData:(uint64_t)receivedLength onTotal:(uint64_t)totalLength progress:(float)progress {
    for (id obj in self.interceptors) {
        if ([obj respondsToSelector:@selector(download:didReceiveData:onTotal:progress:)]) {
            [obj download:blobDownload didReceiveData:receivedLength onTotal:totalLength progress:progress];
        }
    }
}

- (void)download:(TRDownloader *)blobDownload didStopWithError:(NSError *)error {
    for (id obj in self.interceptors) {
        if ([obj respondsToSelector:@selector(download:didStopWithError:)]) {
            [obj download:blobDownload didStopWithError:error];
        }
    }
}

- (void)download:(TRDownloader *)blobDownload didFinishWithSuccess:(BOOL)downloadFinished atPath:(NSString *)pathToFile {
    for (id obj in self.interceptors) {
        if ([obj respondsToSelector:@selector(download:didFinishWithSuccess:atPath:)]) {
            [obj download:blobDownload didFinishWithSuccess:downloadFinished atPath:pathToFile];
        }
    }
}

@end
