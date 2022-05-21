//
//  TRDownloader.m
//  Demo
//
//  Created by xiangyaguo on 2020/12/27.
//

static const double kBufferSize = 0;
static const double kDefaultRequestTimeout = 30;
static const long long kNumberOfSamples = 5;

#import <CommonCrypto/CommonCrypto.h>
#import "TRDownloader.h"


NSString * const TRDownloaderrorDomain = @"com.hiigor.TRDownload";
NSString * const TRDownloaderrorHTTPStatusKey = @"TRDownloaderrorHTTPStatusKey";
NSString * const TRDownloadBreakContinueCacheDir = @"Trump_Cache"; // 断点续传功能目录

@interface TRDownloader ()
// Public
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableURLRequest *fileRequest;
@property (nonatomic, copy) NSURL *downloadURL;
@property (nonatomic, copy) NSString *pathToFile;
@property (nonatomic, copy, readonly) NSString *pathToFileCache;
@property (nonatomic, copy) NSString *pathToDownloadDirectory;
@property (nonatomic, assign) TRDownloadState state;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
// Download
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSMutableData *receivedDataBuffer;
@property (nonatomic, strong) NSFileHandle *fileHandle;
//下载速度、剩余时间
@property (nonatomic, strong) NSMutableArray *samplesOfDownloadedBytes;
@property (nonatomic, assign) uint64_t beginContentLength;
@property (nonatomic, assign) uint64_t expectedDataLength;
@property (nonatomic, assign) uint64_t receivedDataLength;
@property (nonatomic, assign) uint64_t previousTotal;
@property (nonatomic, assign) NSInteger speedRate;
@property (nonatomic, assign) NSInteger remainingTime;
// Blocks
@property (nonatomic, copy) void (^firstResponseBlock)(NSURLResponse *response);
@property (nonatomic, copy) void (^progressBlock)(uint64_t receivedLength, uint64_t totalLength, NSInteger remainingTime, float progress);
@property (nonatomic, copy) void (^errorBlock)(NSError *error);
@property (nonatomic, copy) void (^completeBlock)(BOOL downloadFinished, NSString *pathToFile);

+ (NSNumber *)freeDiskSpace;

- (void)finishOperationWithState:(TRDownloadState)state;
- (void)notifyFromCompletionWithError:(NSError *)error pathToFile:(NSString *)pathToFile;
- (void)updateTransferRate;
- (BOOL)removeFileWithError:(NSError *__autoreleasing *)error;

@end

@implementation TRDownloader
@synthesize fileName = _fileName;
@dynamic pathToFile;
@dynamic remainingTime;


#pragma mark - init 
- (instancetype)initWithURL:(NSURL *)url
               downloadPath:(NSString *)pathToDL
                   fileName:(NSString *)fileName
                   delegate:(id<TRDownloaderDelegate>)delegateOrNil; {
    if (self = [super init]) {
        self.downloadURL = url;
        self.delegate = delegateOrNil;
        self.pathToDownloadDirectory = pathToDL;
        self.fileName = fileName;
        self.beginContentLength = 0;
        self.fileRequest = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kDefaultRequestTimeout];
        self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.sessionConfiguration.timeoutIntervalForRequest = kDefaultRequestTimeout;
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 5;
        self.session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration delegate:self delegateQueue:self.operationQueue];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url downloadPath:(NSString *)pathToDL fileName:(NSString *)fileName firstResponse:(void (^)(NSURLResponse *))firstResponseBlock progress:(void (^)(uint64_t, uint64_t, NSInteger, float))progressBlock error:(void (^)(NSError *))errorBlock complete:(void (^)(BOOL, NSString *))completeBlock {
    self = [self initWithURL:url downloadPath:pathToDL fileName:fileName delegate:nil];
    if (self) {
        self.firstResponseBlock = firstResponseBlock;
        self.progressBlock = progressBlock;
        self.errorBlock = errorBlock;
        self.completeBlock = completeBlock;
    }
    return self;
}

#pragma mark - NSOperation override
- (void)start {
    if (![NSURLConnection canHandleRequest:self.fileRequest]) {
        NSError *error = [NSError errorWithDomain:TRDownloaderrorDomain code:TRDownloaderrorInvalidURL userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Invaild URL provided: %@",self.fileRequest.URL]}];
        [self notifyFromCompletionWithError:error pathToFile:nil];
        return;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    //创建目录
    NSError *err = nil;
    if (![fm createDirectoryAtPath:[self.pathToDownloadDirectory stringByAppendingPathComponent:TRDownloadBreakContinueCacheDir] withIntermediateDirectories:YES attributes:nil error:&err]) {
        [self notifyFromCompletionWithError:err pathToFile:nil];
        return;
    }
    //检查文件是否已经存在，如果存在设置HTTP `bytes` header
    if (![fm fileExistsAtPath:self.pathToFileCache]) {
        [fm createFileAtPath:self.pathToFileCache contents:nil attributes:nil];
    } else {
        uint64_t fileSize = [[fm attributesOfItemAtPath:self.pathToFileCache error:nil] fileSize];
        NSString *range = [NSString stringWithFormat:@"bytes=%lld-", fileSize];
        [self.fileRequest setValue:range forHTTPHeaderField:@"Range"];
        self.receivedDataLength += fileSize;
        self.beginContentLength = fileSize;
    }
    
    NSString *fileDir = [self.pathToDownloadDirectory stringByAppendingPathComponent:[self additionFileComponentOfFile:self.fileName]];
    if (![fm fileExistsAtPath:fileDir]) {
        BOOL create = [fm createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:&err];
        if (!create) {
            [self notifyFromCompletionWithError:err pathToFile:nil];
        }
    }
    
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.pathToFileCache];
    self.receivedDataBuffer = [[NSMutableData alloc] init];
    self.samplesOfDownloadedBytes = [NSMutableArray array];
    self.dataTask = [self.session dataTaskWithRequest:self.fileRequest];
    if (self.dataTask) {
        [self willChangeValueForKey:@"isExecuting"];
        self.state = TRDownloadStateDownloading;
        [self didChangeValueForKey:@"isExecuting"];
        
        [self.fileHandle seekToEndOfFile];
        [self.dataTask resume];
    }
}

- (BOOL)isExecuting {
    return self.state == TRDownloadStateDownloading;
}

- (BOOL)isCancelled {
    return self.state == TRDownloadStateCanceled;
}

- (BOOL)isFinished {
    return self.state == TRDownloadStateDone || self.state == TRDownloadStateFailed;
}

#pragma mark - NSURLSession delegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    long long expectedContentLength = [response expectedContentLength];
    self.expectedDataLength = self.receivedDataLength + expectedContentLength;
    NSHTTPURLResponse *httpRes = (NSHTTPURLResponse *)response;
    NSError *err = nil;
    if (httpRes.statusCode >= 400) {
        err = [NSError errorWithDomain:TRDownloaderrorDomain code:TRDownloaderrorHTTPError userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Err HTTP status code %ld (%@)",(long)httpRes.statusCode,[NSHTTPURLResponse localizedStringForStatusCode:httpRes.statusCode]],TRDownloaderrorHTTPStatusKey: @(httpRes.statusCode)}];
    }
    long long expectedLength = @(self.expectedDataLength).longLongValue;
    if ([TRDownloader freeDiskSpace].longLongValue < expectedLength && expectedLength != -1) {
        err = [NSError errorWithDomain:TRDownloaderrorDomain code:TRDownloaderrorNotEnoughFreeDiskSpace userInfo:@{ NSLocalizedDescriptionKey:@"Not enough free disk space" }];
    }
    if (!err) {
        // 允许处理服务器的响应，才会继续接收服务器返回的数据
        completionHandler(NSURLSessionResponseAllow);
        [self.receivedDataBuffer setData:[NSData data]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.firstResponseBlock) {
                self.firstResponseBlock(response);
            }
            if ([self.delegate respondsToSelector:@selector(download:didReceiveFirstResponse:)]) {
                [self.delegate download:self didReceiveFirstResponse:response];
            }
        });
    } else {
        completionHandler(NSURLSessionResponseCancel);
        [self notifyFromCompletionWithError:err pathToFile:self.pathToFile];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [self.receivedDataBuffer appendData:data];
    self.receivedDataLength += data.length;
    NSLog(@"--->%@ | %.2f%% - Received: %ld - Total: %ld",
          self.pathToFile, (float) self.receivedDataLength / self.expectedDataLength * 100,
          (long) self.receivedDataLength, (long) self.expectedDataLength);
    if (self.receivedDataBuffer && self.receivedDataBuffer.length > kBufferSize && [self isExecuting]) {
        
        [self.fileHandle writeData:self.receivedDataBuffer];
        
        [self.receivedDataBuffer setData:[NSData data]];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.progressBlock) {
            self.progressBlock(self.receivedDataLength, self.expectedDataLength, self.remainingTime, self.progress);
        }
        if ([self.delegate respondsToSelector:@selector(download:didReceiveData:onTotal:progress:)]) {
            [self.delegate download:self didReceiveData:self.receivedDataLength onTotal:self.expectedDataLength progress:self.progress];
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self notifyFromCompletionWithError:error pathToFile:self.pathToFile];
        NSLog(@"%@",error.userInfo);
    } else if ([self isExecuting]) {
        [self.fileHandle writeData:self.receivedDataBuffer];
        [[NSFileManager defaultManager] moveItemAtPath:self.pathToFileCache toPath:self.pathToFile error:nil];
        self.receivedDataBuffer = nil;
        
        [self notifyFromCompletionWithError:nil pathToFile:self.pathToFile];
    }
    [self.fileHandle closeFile];
}

#pragma mark - Public method
- (void)cancelDownloadAndRemoveFile:(BOOL)remove {
    if (remove) {
        NSError *error;
        if (![self removeFileWithError:&error]) {
            [self notifyFromCompletionWithError:error pathToFile:nil];
            return;
        }
    }
    
    [self cancel];
}

- (BOOL)removeFileWithError:(NSError *__autoreleasing *)error {
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:self.pathToFile]) {
        return [fm removeItemAtPath:self.pathToFile error:error];
    }
    return YES;
}

- (void)addDependentDownload:(TRDownloader *)download {
    [self addDependency:download];
}

#pragma mark - Internal Method
- (void)finishOperationWithState:(TRDownloadState)state {
    [self.dataTask cancel];
    [self.fileHandle closeFile];
    
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    self.state = state;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    
    [self.session finishTasksAndInvalidate];
}

- (void)cancel {
    [self willChangeValueForKey:@"isFinished"];
    [self finishOperationWithState:TRDownloadStateDone];
    [self didChangeValueForKey:@"isFinished"];
    [self.session finishTasksAndInvalidate];
}

- (void)notifyFromCompletionWithError:(NSError *)error pathToFile:(NSString *)pathToFile {
    BOOL success = error == nil;
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.errorBlock) {
                self.errorBlock(error);
            }
            if ([self.delegate respondsToSelector:@selector(download:didStopWithError:)]) {
                [self.delegate download:self didStopWithError:error];
            }
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completeBlock) {
            self.completeBlock(success, pathToFile);
        }
        if ([self.delegate respondsToSelector:@selector(download:didFinishWithSuccess:atPath:)]) {
            [self.delegate download:self didFinishWithSuccess:success atPath:pathToFile];
        }
    });
    
    TRDownloadState finalState = success ? TRDownloadStateDone : TRDownloadStateFailed;
    [self finishOperationWithState:finalState];
}

- (void)updateTransferRate {
    if (self.samplesOfDownloadedBytes.count > kNumberOfSamples) {
        [self.samplesOfDownloadedBytes removeObjectAtIndex:0];
    }
    
    // Add the sample
    [self.samplesOfDownloadedBytes addObject:[NSNumber numberWithUnsignedLongLong:self.receivedDataLength - self.previousTotal]];
    self.previousTotal = self.receivedDataLength;
    // Compute the speed rate on the average of the last seconds samples
    self.speedRate = [[self.samplesOfDownloadedBytes valueForKeyPath:@"@avg.longValue"] longValue];
}


+ (NSNumber *)freeDiskSpace {
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [dic objectForKey:NSFileSystemFreeSize];
}

#pragma mark - Custom Getters

- (void)setFileName:(NSString *)fileName {
    _fileName = fileName;
}

- (NSString *)fileName {
    return _fileName ? _fileName : [[NSURL URLWithString:[self.downloadURL absoluteString]] lastPathComponent];
}

- (NSString *)pathToFile {
    return [[self.pathToDownloadDirectory stringByAppendingPathComponent:[self additionFileComponentOfFile:self.fileName]] stringByAppendingPathComponent:self.fileName];
}

- (NSString *)pathToFileCache {
    return [[self.pathToDownloadDirectory stringByAppendingPathComponent:TRDownloadBreakContinueCacheDir] stringByAppendingPathComponent:self.fileName];
}

- (NSInteger)remainingTime {
    return self.speedRate > 0 ? ((NSInteger) (self.expectedDataLength - self.receivedDataLength) / self.speedRate) : -1;
}

- (float)progress {
    return (_expectedDataLength == 0) ? 0 : (float) self.receivedDataLength / (float) self.expectedDataLength;
}

- (NSString *)additionFileComponentOfFile:(NSString *)filename {
    const char *cStr = [filename UTF8String];
    unsigned char digest[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest); // This is the md5 call

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];

    return  output;
}

@end
