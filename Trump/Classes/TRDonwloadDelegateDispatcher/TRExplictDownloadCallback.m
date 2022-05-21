//
//  TRExplictDownloadCallback.m
//  Trump
//
//  Created by igor xiang on 2021/7/7.
//

#import "TRExplictDownloadCallback.h"
#import "TRSourceFileManager.h"
#import "TRSourceModel.h"


@interface TRExplictDownloadCallback()

@property (nonatomic, copy) TRSourceResultCallback downloadCallback;

@end

@implementation TRExplictDownloadCallback

- (instancetype)initWithCallBack:(TRSourceResultCallback)callback {
    self = [super init];
    if (self) {
        self.downloadCallback = callback;
    }
    
    return self;
}

- (void)download:(TRDownloader *)blobDownload didFinishWithSuccess:(BOOL)downloadFinished atPath:(NSString *)pathToFile {
    if (downloadFinished) {
        TRSourceInfo *info = (TRSourceInfo *)blobDownload.model;
        kTrumpDownloadSizeAlready += info.receivedLength - info.beginContentLength;
        BOOL verify = [[TRSourceFileManager defaultManager] verifyAndDeleteFileIfNotPassed:pathToFile md5:info.md5];
        if (!verify) {
            !self.downloadCallback ?: self.downloadCallback(nil, nil, TRSourceDownloadFail);
            return;
        }
        // 下载完成做记载同步到本地配置
        NSString *fileDir = [pathToFile stringByDeletingLastPathComponent];
        [[TRSourceFileManager defaultManager] recordLocalFilePath:fileDir forFile:pathToFile.lastPathComponent ofModule:info.module];
        !self.downloadCallback ?: self.downloadCallback(fileDir, blobDownload.fileName, TRSourceDownloadSuccess);
    }
}

@end
