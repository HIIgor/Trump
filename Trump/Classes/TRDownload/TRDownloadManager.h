//
//  TRDownloadManager.h
//
//  Created by xiangyaguo on 2020/12/27.
//
/**
 TRDownloadManager 是 TRDownloader的管理类，通过NSOperationQueue来添加、移除下载类
 它提供了开始和取消一个下载操作的方法，同时可以定义最大下载量
 使用单例来创建类的实例
 */

@class TRDownloader;
@protocol TRDownloaderDelegate;

#import <Foundation/Foundation.h>

typedef int (^RetryDelayCalcBlock)(int, int, int); // int totalRetriesAllowed, int retriesRemaining, int delayBetweenIntervalsModifier

@interface TRDownloadManager : NSObject

@property (nonatomic, strong) NSOperationQueue *operationQueue;

/**
 defaultDownloadPath用于未设置customPath下
 默认值为`/tmp`
 */
@property (nonatomic, copy) NSString *defaultDownloadPath;

//当前队列的总下载数
@property (nonatomic, assign) NSUInteger downloadCount;

//当前队列中正在执行的下载数
@property (nonatomic, assign) NSUInteger currentDownloadCount;

@property (nonatomic, strong) NSDictionary *operationsDict;

@property (nonatomic, copy) RetryDelayCalcBlock retryDelayCalcBlock;

+ (instancetype)defaultManager;

/**
 !* 根据指定的URL，自定义的下载路径，可选代理来创建一个下载类（TRDownloader类型），该类是NSOperation的子类，执行于后台线程中。
 @param1 url 文件的下载路径。
 @param2 customPathOrNil 文件下载到路径（可为nil，为空时，使用默认路径）
 @param3 delegate 设置代理（可不设）
 @return TRDownloader 返回创建并执行的下载对象
 */
- (TRDownloader *)startDownloadWithURL:(NSURL *)url
                            customPath:(NSString *)customPathOrNil
                              fileName:(NSString *)fileName
                              delegate:(id<TRDownloaderDelegate>)delegate;

/**
 !* 根据指定的URL，自定义的下载路径，可选代理来创建一个下载类（TRDownloader类型），该类是NSOperation的子类，执行于后台线程中。
 @param1 url 文件的下载路径。
 @param2 customPathOrNil 文件下载到路径（可为nil，为空时，使用默认路径）
 @parma3 retryTime 重试次数
 @param4 retryInterval 重试间隔时间
 @param5 delegate 设置代理（可不设）
 @return TRDownloader 返回创建的下载对象
 */
- (TRDownloader *)downloaderWithURL:(NSURL *)url
                         customPath:(NSString *)customPathOrNil
                           fileName:(NSString *)fileName
                              retry:(NSUInteger)retryTime
                      retryInterval:(NSTimeInterval)retryInterval
                           delegate:(id<TRDownloaderDelegate>)delegate;

/**
 !* 提供与`startDownloadWithURL: customPath: delegate:`相似的方法，block的形式更新View
 @param1 url 文件的下载路径。
 @param2 customPathOrNil 文件下载到路径（可为nil，为空时，使用默认路径）
 @param3 fileName 文件名
 @param4 firstResponseBlock block回调，第一次请求服务器返回的参数
 @param5 progressBlock 进度block回调，（如果剩余时间尚未计算，remainingTime = -1）
 @param6 errorBlock 错误信息返回，当下载请求发生错误时调用
 @param7 completeBlock 下载完成回调block
 @return TRDownloader 返回创建并执行的下载对象
 */
- (TRDownloader *)startDownloadWithURL:(NSURL *)url
                            customPath:(NSString *)customPathOrNil
                              fileName:(NSString *)fileName
                         firstResponse:(void(^)(NSURLResponse *response))firstResponseBlock
                              progress:(void(^)(uint64_t receivedLength, uint64_t totalLength, NSInteger remainingTime, float progress))progressBlock
                                 error:(void(^)(NSError *error))errorBlock
                              complete:(void(^)(BOOL downloadFinished, NSString *fileToPath))completeBlock;

//一个请求任务开始下载
- (void)startDownload:(TRDownloader *)download;

//多个请求任务开始下载
- (void)startDownloads:(NSMutableArray <TRDownloader *>*)downloads;

- (void)setOperationQueueName:(NSString *)queueName;

- (void)setMaxConcurrentDownload:(NSInteger)count;

- (void)cancelAllDownloadsAndRemoveFile:(BOOL)remove;

#pragma mark - 同一个文件下载任务唯一
- (TRDownloader *)downloadTaskWithKey:(NSString *)key;

- (void)setDownloadTask:(TRDownloader *)task forKey:(NSString *)key;

@end
