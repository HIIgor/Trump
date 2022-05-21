//
//  TRDownloadManager.m
//
//  Created by xiangyaguo on 2020/12/27.
//

#import "TRDownloadManager.h"
#import "TRDownloader_Internal.h"
#import "TRSourceCommon.h"

@interface TRDownloadManager ()

@property (nonatomic, strong) NSMapTable *tasks;

@end

@implementation TRDownloadManager

@dynamic downloadCount;
@dynamic currentDownloadCount;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.defaultDownloadPath = [NSString stringWithString:NSTemporaryDirectory()];
        self.tasks = [NSMapTable strongToWeakObjectsMapTable];
    }
    return self;
}

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static id sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
        [sharedManager setOperationQueueName:@"TRDownloadManager_Instance_Queue"];
    });
    return sharedManager;
}

- (TRDownloader *)startDownloadWithURL:(NSURL *)url customPath:(NSString *)customPathOrNil fileName:(NSString *)fileName delegate:(id<TRDownloaderDelegate>)delegate {
    if (!customPathOrNil) {
        customPathOrNil = self.defaultDownloadPath;
    }
    TRDownloader *downloader = [[TRDownloader alloc] initWithURL:url
                                                    downloadPath:customPathOrNil
                                                        fileName:fileName
                                                        delegate:delegate];
    [self.operationQueue addOperation:downloader];
    return downloader;
}

- (TRDownloader *)startDownloadWithURL:(NSURL *)url customPath:(NSString *)customPathOrNil fileName:(NSString *)fileName firstResponse:(void (^)(NSURLResponse *))firstResponseBlock progress:(void (^)(uint64_t, uint64_t, NSInteger, float))progressBlock error:(void (^)(NSError *))errorBlock complete:(void (^)(BOOL, NSString *))completeBlock {
    if (!customPathOrNil) {
        customPathOrNil = self.defaultDownloadPath;
    }
    TRDownloader *downloader = [[TRDownloader alloc] initWithURL:url
                                                    downloadPath:customPathOrNil
                                                        fileName:fileName
                                                   firstResponse:firstResponseBlock
                                                        progress:progressBlock
                                                           error:errorBlock
                                                        complete:completeBlock];
    [self.operationQueue addOperation:downloader];
    return downloader;
}

- (void)startDownload:(TRDownloader *)download {
    [self.operationQueue addOperation:download];
}

- (void)startDownloads:(NSMutableArray<TRDownloader *> *)downloads {
    [self.operationQueue cancelAllOperations];
    [self.operationQueue addOperations:downloads waitUntilFinished:NO];
}

- (void)cancelAllDownloadsAndRemoveFile:(BOOL)remove {
    [self.operationQueue cancelAllOperations];
    NSArray <TRDownloader *>*operationsArr = self.operationQueue.operations;
    [operationsArr enumerateObjectsUsingBlock:^(TRDownloader * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cancelDownloadAndRemoveFile:remove];
    }];
}

- (void)setOperationQueueName:(NSString *)queueName {
    self.operationQueue.name = queueName;
}

- (void)setMaxConcurrentDownload:(NSInteger)count {
    self.operationQueue.maxConcurrentOperationCount = count;
}

- (TRDownloader *)downloadTaskWithKey:(NSString *)key {
    return [self.tasks objectForKey:key];
}

- (void)setDownloadTask:(TRDownloader *)task forKey:(NSString *)key {
    [self.tasks setObject:task forKey:key];
}


#pragma mark - retry

- (TRDownloader *)downloaderWithURL:(NSURL *)url
                         customPath:(NSString *)customPathOrNil
                           fileName:(NSString *)fileName
                              retry:(NSUInteger)retryTime
                      retryInterval:(NSTimeInterval)retryInterval
                           delegate:(id<TRDownloaderDelegate>)delegate {
    if (!customPathOrNil) {
        customPathOrNil = self.defaultDownloadPath;
    }
    void (^retryBlock)(TRDownloader *, NSError *) = ^(TRDownloader *downloader, NSError *error) {
        if (downloader.isCancelled) return;
        
        if ([self isErrorFatal:error]) {
            if ([delegate respondsToSelector:@selector(download:didStopWithError:)]) {
                [delegate download:downloader didStopWithError:error];
            }
        }
        
        NSMutableDictionary *retryOperationDict = self.operationsDict[url];
        int originalRetryCount = [retryOperationDict[@"originalRetryCount"] intValue];
        int retriesRemainingCount = [retryOperationDict[@"retriesRemainingCount"] intValue];
        if (!retriesRemainingCount) {
            TrumpLogInfo(@"AutoRetry: No more retries allowed! executing supplied failure block...");
            if ([delegate respondsToSelector:@selector(download:didStopWithError:)]) {
                [delegate download:downloader didStopWithError:error];
            }
            TrumpLogInfo(@"AutoRetry: done.");
            return;
        }
        
        TrumpLogInfo(@"AutoRetry: Request failed: %@, retry %d out of %d begining...",
                error.localizedDescription, originalRetryCount - retriesRemainingCount + 1, originalRetryCount);
        TRDownloader *retrydl = [self downloaderWithURL:url customPath:customPathOrNil fileName:fileName retry:retriesRemainingCount - 1 retryInterval:retryInterval delegate:delegate];
        retrydl.model = downloader.model;
        dispatch_block_t addRetrydl = ^{
            [self.operationQueue addOperation:retrydl];
        };
        
        int intervalToWait = self.retryDelayCalcBlock ? self.retryDelayCalcBlock(originalRetryCount, retriesRemainingCount, retryInterval) : 0;
        if (intervalToWait > 0) {
            TrumpLogInfo(@"AutoRetry: Delaying retry for %d seconds...", intervalToWait);
            dispatch_time_t delay = dispatch_time(0, (int64_t) (intervalToWait * NSEC_PER_SEC));
            dispatch_after(delay, dispatch_get_main_queue(), addRetrydl);
        } else {
            addRetrydl();
        }
    };
    
    NSMutableDictionary *operationDict = self.operationsDict[url];
    if (!operationDict) {
        operationDict = [NSMutableDictionary dictionary];
        operationDict[@"originalRetryCount"] = @(retryTime);
    }
    operationDict[@"retriesRemainingCount"] = @(retryTime);
    NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:self.operationsDict];
    newDict[url] = operationDict;
    self.operationsDict = newDict;
    TRDownloader *dl = [[TRDownloader alloc] initWithURL:url downloadPath:customPathOrNil fileName:fileName delegate:nil];
    __weak TRDownloader * wdl = dl;
    dl.firstResponseBlock = ^(NSURLResponse *response) {
        if ([delegate respondsToSelector:@selector(download:didReceiveFirstResponse:)]) {
            [delegate download:wdl didReceiveFirstResponse:response];
        }
    };
    dl.progressBlock = ^(uint64_t receivedLength, uint64_t totalLength, NSInteger remainingTime, float progress) {
        if ([delegate respondsToSelector:@selector(download:didReceiveData:onTotal:progress:)]) {
            [delegate download:wdl didReceiveData:receivedLength onTotal:totalLength progress:progress];
        }
    };
    dl.errorBlock = ^(NSError *error) {
        retryBlock(wdl, error);
    };
    dl.completeBlock = ^(BOOL downloadFinished, NSString *pathToFile) {
        if ([delegate respondsToSelector:@selector(download:didFinishWithSuccess:atPath:)]) {
            [delegate download:wdl didFinishWithSuccess:downloadFinished atPath:pathToFile];
        }
        
        NSMutableDictionary *successOperationDict = self.operationsDict[url];
        int originalRetryCount = [successOperationDict[@"originalRetryCount"] intValue];
        int retriesRemainingCount = [successOperationDict[@"retriesRemainingCount"] intValue];
        if (downloadFinished) {
            TrumpLogInfo(@"AutoRetry: success with %d retries, running success block...", originalRetryCount - retriesRemainingCount);
        }
    };
    
    return wdl;
}

- (void)createOperationsDict {
    [self setOperationsDict:[[NSDictionary alloc] init]];
}

- (RetryDelayCalcBlock)retryDelayCalcBlock {
    if (!_retryDelayCalcBlock) {
        _retryDelayCalcBlock = ^int(int totalRetries, int currentRetry, int delayInSecondsSpecified) {
            return delayInSecondsSpecified;
        };
    }
    return _retryDelayCalcBlock;
}

- (NSDictionary *)operationsDict {
    if (!_operationsDict) {
        _operationsDict = [[NSDictionary alloc] init];
    }
    return _operationsDict;
}

// subclass and overide this method if necessary
- (BOOL)isErrorFatal:(NSError *)error {
    switch (error.code) {
        case kCFHostErrorHostNotFound:
        case kCFHostErrorUnknown: // Query the kCFGetAddrInfoFailureKey to get the value returned from getaddrinfo; lookup in netdb.h
            // HTTP errors
        case kCFErrorHTTPAuthenticationTypeUnsupported:
        case kCFErrorHTTPBadCredentials:
        case kCFErrorHTTPParseFailure:
        case kCFErrorHTTPRedirectionLoopDetected:
        case kCFErrorHTTPBadURL:
        case kCFErrorHTTPBadProxyCredentials:
        case kCFErrorPACFileError:
        case kCFErrorPACFileAuth:
        case kCFStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod:
            // Error codes for CFURLConnection and CFURLProtocol
        case kCFURLErrorUnknown:
        case kCFURLErrorCancelled:
        case kCFURLErrorBadURL:
        case kCFURLErrorUnsupportedURL:
        case kCFURLErrorHTTPTooManyRedirects:
        case kCFURLErrorBadServerResponse:
        case kCFURLErrorUserCancelledAuthentication:
        case kCFURLErrorUserAuthenticationRequired:
        case kCFURLErrorZeroByteResource:
        case kCFURLErrorCannotDecodeRawData:
        case kCFURLErrorCannotDecodeContentData:
        case kCFURLErrorCannotParseResponse:
        case kCFURLErrorInternationalRoamingOff:
        case kCFURLErrorCallIsActive:
        case kCFURLErrorDataNotAllowed:
        case kCFURLErrorRequestBodyStreamExhausted:
        case kCFURLErrorFileDoesNotExist:
        case kCFURLErrorFileIsDirectory:
        case kCFURLErrorNoPermissionsToReadFile:
        case kCFURLErrorDataLengthExceedsMaximum:
            // SSL errors
        case kCFURLErrorServerCertificateHasBadDate:
        case kCFURLErrorServerCertificateUntrusted:
        case kCFURLErrorServerCertificateHasUnknownRoot:
        case kCFURLErrorServerCertificateNotYetValid:
        case kCFURLErrorClientCertificateRejected:
        case kCFURLErrorClientCertificateRequired:
        case kCFURLErrorCannotLoadFromNetwork:
            // Cookie errors
        case kCFHTTPCookieCannotParseCookieFile:
            // Errors originating from CFNetServices
        case kCFNetServiceErrorUnknown:
        case kCFNetServiceErrorCollision:
        case kCFNetServiceErrorNotFound:
        case kCFNetServiceErrorInProgress:
        case kCFNetServiceErrorBadArgument:
        case kCFNetServiceErrorCancel:
        case kCFNetServiceErrorInvalid:
            // Special case
        case 101: // null address
        case 102: // Ignore "Frame Load Interrupted" errors. Seen after app store links.
        case TRDownloaderrorNotEnoughFreeDiskSpace:
            return YES;
        default:
            break;
    }
    return NO;
}

@end
