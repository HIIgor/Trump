//
//  TRSourceManager.h
//  Trump
//
//  Created by igor xiang on 2021/4/29.
//

#import <Foundation/Foundation.h>
#import <Trump/TRSource.h>

@protocol TRSourceProtocol;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TRSourceResultType) { // 在本地,参数错误,下载成功,下载失败,下载已经到达最大限制
    TRSourceLocalExists,
    TRSourceParamsInvalid,
    TRSourceDownloadSuccess,
    TRSourceDownloadFail,
    TRSourceReachedMaxSize
};

extern UInt64 kTrumpDownloadSizeAlready;

typedef void (^TRSourceResultCallback)(NSString * fileDir, NSString *fileName, TRSourceResultType type);

@interface TRSourceManager : NSObject

+ (instancetype)defaultManager;

+ (void)startWithInterceptors:(NSArray <TRSourceProtocol> * )interceptors;

#pragma mark - source

/// 获取一个TRSource对象
/// @param module 业务方
/// @param file 文件名
+ (TRSource *)sourceWithModule:(NSString *)module file:(NSString *)file;


/// 获取一个TRSource对象
/// @param module 业务方
/// @param file 文件名
/// @param isDir 是否为文件夹
+ (TRSource *)sourceWithModule:(NSString *)module file:(NSString *)file isDir:(BOOL)isDir;


/// 获取对应module下的所有TRSource对象
/// @param module 模块名
+ (NSArray *)sourcesWithModule:(NSString *)module;

#pragma mark - fetch

/// 主动触发下载任务完成后处理回调
/// @param module 模块名
/// @param name 文件名
/// @param completion 下载完成回调
- (void)requestSourceWithModule:(NSString *)module fileName:(NSString *)name completion:(TRSourceResultCallback)completion;


/// 主动触发下载任务
/// @param module 模块名
/// @param name 文件名
/// @discussion 此方法不带回调,所以会在下载完成后调用拦截器的回调方法
- (void)requestSourceWithModule:(NSString *)module fileName:(NSString *)name;


/// 下载当前模块下的所有文件
/// @param module 模块名
/// @discussion 此方法不带回调,所以会在下载完成后调用拦截器的回调方法
- (void)requestSourceWithModule:(NSString *)module;
@end

NS_ASSUME_NONNULL_END
