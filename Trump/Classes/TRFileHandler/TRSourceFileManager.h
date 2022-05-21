//
//  TRSourceFileManager.h
//  Trump
//
//  Created by igor xiang on 2021/4/29.
//

#import <Foundation/Foundation.h>
#import "TRSourceLocalInfo.h"

NS_ASSUME_NONNULL_BEGIN

/// 文件管理模块
@interface TRSourceFileManager : NSObject

+ (instancetype)defaultManager;


/// 为模块创建各自的文件路径
/// @param module 模块名
- (NSString *)createFolderForModule:(NSString *)module;


/// 根据模块名获取文件的路径
/// @param module 模块名
/// @param file 文件名
/// @param isDir 该路径是否为文件夹
- (NSString *)pathForModule:(NSString *)module file:(NSString *)file isDir:(BOOL)isDir;


/// 对文件做唯一性判断,若未通过则将其删除
/// @param path 文件路径
/// @param md5 md5值
- (BOOL)verifyAndDeleteFileIfNotPassed:(NSString *)path md5:(NSString *)md5;


/// 对文件做唯一性判断
/// @param path 文件路径
/// @param md5 md5值
- (BOOL)verifyFile:(NSString *)path md5:(NSString *)md5;


/// 下载完成后本地记录
/// @param path 文件所在目录
/// @param fileName 文件名
/// @param module 模块名
- (void)recordLocalFilePath:(NSString *)path forFile:(NSString *)fileName ofModule:(NSString *)module;


/// 根据远端配置检查是否需要删除本地沙盒中的文件
/// @param record 远端的配置
- (void)checkIfNeedDeleteLocalfile:(TRLocalRecord *)record;
@end

NS_ASSUME_NONNULL_END
