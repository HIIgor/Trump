//
//  TRSourceCommon.h
//  Trump
//
//  Created by igor xiang on 2021/7/21.
//

#import <Foundation/Foundation.h>


#define TrumpLogInfo(fmt, ...)     NSLog(@"[Trump] %@",    [NSString stringWithFormat:fmt, ##__VA_ARGS__]); \

#define TRFileHashDefaultChunkSizeForReadingData 1024 * 8

NS_ASSUME_NONNULL_BEGIN

NSString *TRAdditionalFileComponentOfFile(NSString *file);


CFStringRef TRFileMD5HashCreateWithPath(CFStringRef filePath, size_t chunkSizeForReadingData);

NS_ASSUME_NONNULL_END
