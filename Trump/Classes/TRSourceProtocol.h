//
//  TRSourceProtocol.h
//  Trump
//
//  Created by igor xiang on 2021/4/29.
//

#import <Foundation/Foundation.h>
#import "TRSourceModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol TRSourceProtocol <NSObject>

/// 下载完成后的回调
/// @param filename 文件名
/// @param path 文件所在的目录
/// @Discussion 如果下载文件之后需要解压缩,解压缩的文件夹名务必与文件名一致. 例如下载的文件为 images.zip 解压缩的文件夹为 images
- (void)didFinishDownloadFile:(NSString *)filename atPath:(NSString *)path;


/// 回调业务方是否需要预加载
/// @param filename 文件名
- (BOOL)shouldPreloadFile:(NSString *)filename;


/// 业务方提供模块名称作为唯一标识,务必不要随意更改
- (NSString *)moduleName;

@end

NS_ASSUME_NONNULL_END
