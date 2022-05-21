//
//  TRDownloader.h
//  Demo
//
//  Created by xiangyaguo on 2020/12/27.
//


#import <Foundation/Foundation.h>

extern NSString * const TRDownloaderrorDomain;
extern NSString * const TRDownloaderrorHTTPStatusKey;

typedef NS_ENUM(NSUInteger, TRDownloaderror) {
    TRDownloaderrorInvalidURL = 1 << 2,//无效的URL
    TRDownloaderrorHTTPError = 1 << 3,//HTTP请求错误
    TRDownloaderrorNotEnoughFreeDiskSpace = 1 << 4//剩余磁盘空间不足
};

typedef NS_ENUM(NSUInteger, TRDownloadState) {
    TRDownloadStateReady = 0,
    TRDownloadStateDownloading,
    TRDownloadStateDone,
    TRDownloadStateCanceled,
    TRDownloadStateFailed
};

@class TRDownloader;
@protocol TRDownloaderDelegate <NSObject>

@optional
- (void)download:(TRDownloader *)blobDownload didReceiveFirstResponse:(NSURLResponse *)response;

- (void)download:(TRDownloader *)blobDownload didReceiveData:(uint64_t)receivedLength onTotal:(uint64_t)totalLength progress:(float)progress;

- (void)download:(TRDownloader *)blobDownload didStopWithError:(NSError *)error;

- (void)download:(TRDownloader *)blobDownload didFinishWithSuccess:(BOOL)downloadFinished atPath:(NSString *)pathToFile;

@end


@protocol TRDownloaderDelegate;
@interface TRDownloader : NSOperation<NSURLSessionDataDelegate>

@property (nonatomic, strong, readonly) NSURLSession *session;

@property (nonatomic, strong, readonly) NSURLSessionDataTask *dataTask;

@property (nonatomic, strong) NSRunLoop *runloop;

@property (nonatomic, strong) id model;

@property (nonatomic, strong) id <TRDownloaderDelegate> delegate;

@property (nonatomic, copy, readonly) NSString *pathToDownloadDirectory;

@property (nonatomic, copy, readonly) NSString *pathToFile;

@property (nonatomic, copy, readonly) NSURL *downloadURL;

@property (nonatomic, strong, readonly) NSMutableURLRequest *fileRequest;

@property (nonatomic, assign, readonly) u_int64_t beginContentLength;

@property (nonatomic, copy) NSString *fileName;

@property (nonatomic, assign, readonly) NSInteger speedRate;

@property (nonatomic, assign, readonly) NSInteger remainingTime;

@property (nonatomic, assign, readonly) float progress;

@property (nonatomic, assign, readonly) TRDownloadState state;


- (instancetype)initWithURL:(NSURL *)url
               downloadPath:(NSString *)pathToDL
                   fileName:(NSString *)fileName
                   delegate:(id<TRDownloaderDelegate>)delegateOrNil;


- (instancetype)initWithURL:(NSURL *)url
               downloadPath:(NSString *)pathToDL
                   fileName:(NSString *)fileName  
              firstResponse:(void (^)(NSURLResponse *response))firstResponseBlock
                   progress:(void (^)(uint64_t receivedLength, uint64_t totalLength, NSInteger remainingTime, float progress))progressBlock
                      error:(void (^)(NSError *error))errorBlock
                   complete:(void (^)(BOOL downloadFinished, NSString *pathToFile))completeBlock;

- (void)cancelDownloadAndRemoveFile:(BOOL)remove;

- (void)addDependentDownload:(TRDownloader *)download;

@end



