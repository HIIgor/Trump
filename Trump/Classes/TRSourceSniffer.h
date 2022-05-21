//
//  TRSourceSniffer.h
//  Trump
//
//  Created by igor xiang on 2021/5/10.
//

#import <Foundation/Foundation.h>
#import "TRSourceModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 资源嗅探,通过namespace和key去gift服务器获取该文件的详细信息
@interface TRSourceSniffer : NSObject

/// 通过namespace和key获取资源的详细信息
/// @param ns 命名空间
/// @param key key
/// @param success 成功回调
/// @param failure 失败回调
- (void)snifferGiftSourceWithNamespace:(NSString *)ns key:(NSString *)key success:(void (^)(TRSourceInfo *info))success failure:(void (^)(NSError *))failure;

@end

NS_ASSUME_NONNULL_END
