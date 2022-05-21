//
//  TRSource.h
//  Trump
//
//  Created by igor xiang on 2021/5/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TRSource : NSObject

@property (nonatomic, copy, readonly) NSString *module;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign, readonly) BOOL isDir;


/// 文件路径
- (NSString *)filePath;

/// 获取目录下的文件
- (NSString *)subfilePathForName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
