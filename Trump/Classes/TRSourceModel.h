//
//  TRSourceModel.h
//  Trump
//
//  Created by igor xiang on 2021/7/8.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

// http://wiki.intra.xiaojukeji.com/pages/viewpage.action?pageId=572181374

@protocol TRResource <NSObject>
@end
@interface TRResource : JSONModel

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *ns; //namespace
@property (nonatomic, copy) NSString *key;

@end

@protocol TRSourceModule <NSObject>
@end
@interface TRSourceModule : JSONModel

@property (nonatomic, copy) NSString *module;

@property (nonatomic, copy) NSArray <TRResource> *resources;

@end


@interface TRSources : JSONModel

@property (nonatomic, copy) NSArray <TRSourceModule> *contents;
@property (nonatomic, copy) NSString *version;

@end


#pragma TRSourceInfo

@interface TRSourceInfo : JSONModel


/*
 {
     "creation_time":1619437394,
     "download_url":"https://xxxxxx.com/xxxx",
     "download_url_https":"https://xxxxxx.com/xxxx",
     "file_size":1398002,
     "md5":"c53a2a070e193666f6a0dd5a6eb50e0d",
     "status":"success",
     "status_code":200
 }
 */

@property (nonatomic, strong) NSNumber *creation_time;
@property (nonatomic,   copy) NSString *download_url;
@property (nonatomic,   copy) NSString *download_url_https;
@property (nonatomic, strong) NSNumber *file_size;
@property (nonatomic,   copy) NSString *md5;
@property (nonatomic,   copy) NSString *status;
@property (nonatomic, strong) NSNumber *status_code;

/**
 额外参数
 */
@property (nonatomic,   copy) NSString *module;
@property (nonatomic, assign) uint64_t beginContentLength;
@property (nonatomic, assign) uint64_t totalLength;     // 总数
@property (nonatomic, assign) uint64_t receivedLength; // 已接收
@property (nonatomic, assign) NSTimeInterval beginTime; // 任务开始时间
@property (nonatomic, assign) BOOL isExplicitTrigger; // 主动下载为1 默认下载为0

@end


NS_ASSUME_NONNULL_END
