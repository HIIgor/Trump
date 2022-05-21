//
//  TRSourceFileManager.m
//  Trump
//
//  Created by igor xiang on 2021/4/29.
//

#import "TRSourceFileManager.h"
#import "TRSourceLocalInfo.h"
#import "TRSourceCommon.h"


@interface TRSourceFileManager ()

@property (nonatomic, copy) NSString *root; // Perse 目录
@property (nonatomic, strong) TRLocalRecord *localRecord;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation TRSourceFileManager


static TRSourceFileManager *manager;
+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TRSourceFileManager alloc] init];
        [manager createDefaultPath];
        // 处理本地文件
        [manager loadLocalRecord];
    });
    
    return manager;
}

- (NSString *)createFolderForModule:(NSString *)module {
    if (self && self != manager) return nil;
    
    NSString *folder = [self.root stringByAppendingPathComponent:module];
    BOOL isDir = NO;
    BOOL folderExist = [[NSFileManager defaultManager] fileExistsAtPath:folder isDirectory:&isDir];
    if (!folderExist || !isDir) {
        BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
        if (!created) return nil;
    }
    
    return folder;
}

- (void)loadLocalRecord {
    NSData *data = [NSData dataWithContentsOfFile:[self localRecordPath]];
    self.localRecord = [[TRLocalRecord alloc] initWithData:data error:nil];
}

- (NSString *)pathForModule:(NSString *)module file:(NSString *)file isDir:(BOOL)isDir {
    NSString *moduleFolder = [self.root stringByAppendingPathComponent:module];
    NSString *filePath = [[moduleFolder stringByAppendingPathComponent:TRAdditionalFileComponentOfFile(file)] stringByAppendingPathComponent:file];
    
    if (isDir) {
        // 如果希望获取目录,尝试获取去除后缀名后的的目录
        // 如果入参 file 为 @"image.zip" 将在目录下去寻找 images目录
        filePath = [filePath stringByDeletingPathExtension];
    }
    
    BOOL isFilePathDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isFilePathDir] && (isFilePathDir == isDir)) {
        return filePath;
    }
    return nil;
}

- (BOOL)verifyAndDeleteFileIfNotPassed:(NSString *)path md5:(NSString *)md5 {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return NO;
    }
    
    BOOL verify = [self verifyFile:path md5:md5];
    if (!verify) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    return verify;
}

- (BOOL)verifyFile:(NSString *)path md5:(NSString *)md5 {
    NSString *fileMd5 = (__bridge_transfer NSString *)TRFileMD5HashCreateWithPath((__bridge CFStringRef)path, TRFileHashDefaultChunkSizeForReadingData);
    return [fileMd5 isEqualToString:md5];
}

- (void)recordLocalFilePath:(NSString *)path forFile:(NSString *)fileName ofModule:(NSString *)module {
    path = [path substringWithRange:NSMakeRange(self.root.length, path.length - self.root.length)];
    dispatch_async(self.queue, ^{
        TRLocalModule *moduleNeedUpdate = nil;
        if (!self.localRecord) {
            self.localRecord = [[TRLocalRecord alloc] init];
        }
        for (TRLocalModule *m in self.localRecord.modules) {
            if ([m.name isEqualToString:module]) {
                moduleNeedUpdate = m;
                break;
            }
        }
        if (!moduleNeedUpdate) {
            moduleNeedUpdate = [TRLocalModule new];
            moduleNeedUpdate.dir = [path stringByDeletingLastPathComponent];
            moduleNeedUpdate.name = module;
            if (!self.localRecord.modules) {
                self.localRecord.modules = [NSArray<TRLocalModule> array];
            }
            self.localRecord.modules = [self.localRecord.modules arrayByAddingObject:moduleNeedUpdate];
        }
        
        TRLocalSource *sourceNeedUpdate = nil;
        for (TRLocalSource *s in self.localRecord.sources) {
            if ([s.name isEqualToString:fileName] && [s.module isEqualToString:module]) {
                sourceNeedUpdate = s;
                break;
            }
        }
        if (!sourceNeedUpdate) {
            sourceNeedUpdate = [TRLocalSource new];
            sourceNeedUpdate.dir = path;
            sourceNeedUpdate.name = fileName;
            sourceNeedUpdate.module = module;
            if (!self.localRecord.sources) {
                self.localRecord.sources = [NSArray<TRLocalSource> array];
            }
            self.localRecord.sources = [self.localRecord.sources arrayByAddingObject:sourceNeedUpdate];
        }
        [self.localRecord.toJSONData writeToFile:[self localRecordPath] atomically:YES];
    });
}


/// 根据远端配置检查是否需要删除本地沙盒中的文件
/// @param record 远端的配置
- (void)checkIfNeedDeleteLocalfile:(TRLocalRecord *)record {
    if (!self.localRecord) return;
    
    NSMutableDictionary *moduleMap = [NSMutableDictionary dictionary];
    for (TRLocalModule *m in record.modules) {
        [moduleMap setValue:m forKey:m.name];
    }
    // 不需要删除的module
    NSMutableArray *remainModules = [NSMutableArray array];
    for (TRLocalModule *m in self.localRecord.modules) {
        if ([moduleMap valueForKey:m.name] == nil) {
            // 沙盒+子路径
            NSString *fullPath = [self.root stringByAppendingPathComponent:m.dir];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
            }
        } else {
            [remainModules addObject:m];
        }
    }
    self.localRecord.modules = [remainModules copy];
    
    // sources
    NSMutableDictionary *sourceMap = [NSMutableDictionary dictionary];
    for (TRLocalSource *s in record.sources) {
        [sourceMap setValue:s forKey:s.name];
    }
    // 本地sources与远端sources比较,本地有但远端不存在的source,将其删除
    NSMutableArray *remainSources = [NSMutableArray array];
    for (TRLocalSource *s in self.localRecord.sources) {
        if ([sourceMap valueForKey:s.name] == nil) {
            // 沙盒+子路径
            NSString *fullPath = [self.root stringByAppendingPathComponent:s.dir];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
                [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
            }
        } else {
            [remainSources addObject:s];
        }
    }
    self.localRecord.sources = [remainSources copy];
    dispatch_async(self.queue, ^{
        [self.localRecord.toJSONData writeToFile:[self localRecordPath] atomically:YES];
    });
}


- (void)createDefaultPath {
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    self.root = [documents stringByAppendingPathComponent:@"Trump"];
    [self handleDownloadFolder:self.root];
}

- (NSString *)localRecordPath {
    return [self.root stringByAppendingPathComponent:@"Trump.json"];
}

- (dispatch_queue_t)queue {
    if (!_queue) {
        _queue = dispatch_queue_create("Trump_Record_Local_Path", DISPATCH_QUEUE_SERIAL);
    }
    return _queue;
}
/**
 处理下载文件夹
 - 确保文件夹存在
 - 为此文件夹设置备份属性，避免占用用户iCloud容量，不然会被拒的
 @param folder 文件路径
 */
- (void)handleDownloadFolder:(NSString *)folder {
    BOOL isDir = NO;
    BOOL folderExist = [[NSFileManager defaultManager] fileExistsAtPath:folder isDirectory:&isDir];
    if (!folderExist || !isDir) {
        [[NSFileManager defaultManager] createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:nil];
        NSURL *fileURL = [NSURL fileURLWithPath:folder];
        [fileURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
    }
}

@end


