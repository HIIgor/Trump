//
//  TRSourceManager.m
//  Trump
//
//  Created by igor xiang on 2021/4/29.
//

#import "TRSourceManager.h"
#import "TRSourceFileManager.h"
#import "TRSourceSniffer.h"
#import "TRSourceModel.h"
#import "TRSource_Internal.h"
#import "TRSourceProtocol.h"
#import "TRDownloaderDelegateDispatcher.h"
#import "TRDownloadAnalytics.h"
#import "TRExplictDownloadCallback.h"
#import "TRDownloadManager.h"
#import "TRSourceLocalInfo.h"
#import "TRSourceCommon.h"


static const UInt64 kMaxDownloadSize = 100 * 1024 * 1024; // 100MB

UInt64 kTrumpDownloadSizeAlready = 0;

static BOOL isTrumpEnable = NO;
@interface TRSourceManager () <TRDownloaderDelegate>

@property (nonatomic, strong) NSMutableDictionary *interceptors;
@property (nonatomic,   weak) TRSourceFileManager *fileManager;

@property (nonatomic, strong) TRSources *sources;           // 读取配置

@property (nonatomic, strong) TRDownloaderDelegateDispatcher *downloadDispatcher; // 分层 下载回调分发器

@end

@implementation TRSourceManager

+ (void)startWithInterceptors:(NSArray<TRSourceProtocol> *)interceptors {
    [[TRSourceManager defaultManager] registerSourceInterceptors:interceptors];
}

+ (TRSource *)sourceWithModule:(NSString *)module file:(NSString *)file {
    return [TRSourceManager sourceWithModule:module file:file isDir:NO];
}

+ (TRSource *)sourceWithModule:(NSString *)module file:(NSString *)file isDir:(BOOL)isDir {
    if (!isTrumpEnable) return nil;
    
    TRSource *source = [[TRSource alloc] init];
    source.module = module;
    source.name = file;
    source.isDir = isDir;
    source.filePath = [[TRSourceFileManager defaultManager] pathForModule:module file:file isDir:isDir];
    
    NSString *ret = source.filePath.length > 0 ? @"1" : @"0";
    TRResource *resource = [[TRSourceManager defaultManager] resourceOfModule:module fileName:file];
//    [YourAnalytics event:@"assets_downloader_get" parameters:@{
//        @"key" : resource.key ?: @"",
//        @"ret" : ret
//    }];
    
    return source;
}

+ (NSArray *)sourcesWithModule:(NSString *)moduleName {
    TRSourceModule *module = nil;
    for (TRSourceModule * obj in [TRSourceManager defaultManager].sources.contents) {
        if ([obj.module isEqualToString:moduleName]) {
            module = obj;
            break;
        }
    }
    if (!module) {
        TrumpLogInfo(@"can not find a module of moduleName - %@", moduleName);
        return nil;
    }
    
    NSMutableArray *sources = [NSMutableArray array];
    for (TRResource *resource in module.resources) {
        TRSource *source = [self sourceWithModule:moduleName file:resource.name];
        if (source) {
            [sources addObject:source];
        }
    }
    
    return sources.copy;
}


/// 主动下载某一个资源文件
- (void)requestSourceWithModule:(NSString *)moduleName fileName:(NSString *)filename completion:(TRSourceResultCallback)completion {
    if (!completion) {
        [self requestSourceWithModule:moduleName fileName:filename];
        return;
    }
    
    if (!isTrumpEnable || moduleName.length == 0 || filename.length == 0) {
        completion(nil, nil, TRSourceParamsInvalid);
    }
    
    if ([self hasReachedMaxDownloadSize]) {
        TrumpLogInfo(@"has reached max download size");
        completion(nil, nil, TRSourceReachedMaxSize);
    }
    
    // 获取文件的配置(ns,key)
    TRResource *resource = [self resourceOfModule:moduleName fileName:filename];
    
    TRSourceSniffer *sniffer = [[TRSourceSniffer alloc] init];
    [sniffer snifferGiftSourceWithNamespace:resource.ns key:resource.key success:^(TRSourceInfo * _Nonnull info) {
        // 1.存在 2.md5校验 3.下载
        NSString *moduleFolder = [self.fileManager createFolderForModule:moduleName];
        NSString *path = [[TRSourceFileManager defaultManager] pathForModule:moduleName file:filename isDir:NO] ?: @"";
        BOOL verify = [[TRSourceFileManager defaultManager] verifyAndDeleteFileIfNotPassed:path md5:info.md5];
        if (verify)  { // 文件存在本地直接回调,跳过下载
            TrumpLogInfo(@"Local source exist (module - %@ filename - %@), download ignored", moduleName, filename);
            completion([path stringByDeletingLastPathComponent], filename, TRSourceLocalExists);
            return;
        }
        
        TRDownloaderDelegateDispatcher *dispatcher = [[TRDownloaderDelegateDispatcher alloc] initWithInterceptors:
            [NSArray<TRDownloaderDelegate> arrayWithObjects:[[TRExplictDownloadCallback alloc] initWithCallBack:completion], [[TRDownloadAnalytics alloc] init], nil]
        ];
        // 主动触发任务埋点
        info.isExplicitTrigger = YES;
        [self downloadSourceWithName:resource.name info:info moduleName:moduleName moduleFolder:moduleFolder delegate:dispatcher];
    } failure:^(NSError *error) {
        TrumpLogInfo(@"sniffer failed - module - %@ file - %@", moduleName, filename);
        completion(nil, nil, TRSourceDownloadFail);
    }];
}

// 主动触发下载任务,走拦截器的回调
- (void)requestSourceWithModule:(NSString *)moduleName fileName:(NSString *)filename {
    if (!isTrumpEnable || moduleName.length == 0 || filename.length == 0 || [self hasReachedMaxDownloadSize]) {
        TrumpLogInfo(@"download ignored (apollo enabled - %d, modulename - %@ filename - %@ reachedMaxDownloadSize - %@)", isTrumpEnable, moduleName, filename, [self hasReachedMaxDownloadSize]);
        return;
    }
    // 获取文件的配置(ns,key)
    TRResource *resource = [self resourceOfModule:moduleName fileName:filename];
    
    TRSourceSniffer *sniffer = [[TRSourceSniffer alloc] init];
    [sniffer snifferGiftSourceWithNamespace:resource.ns key:resource.key success:^(TRSourceInfo * _Nonnull info) {
        // 1.存在 2.md5校验 3.下载
        NSString *moduleFolder = [self.fileManager createFolderForModule:moduleName];
        NSString *path = [[TRSourceFileManager defaultManager] pathForModule:moduleName file:filename isDir:NO] ?: @"";
        BOOL verify = [[TRSourceFileManager defaultManager] verifyAndDeleteFileIfNotPassed:path md5:info.md5];
        if (verify)  {
            TrumpLogInfo(@"Local source exist (module - %@ filename - %@), download ignored", moduleName, filename);
            id interceptor = [self.interceptors valueForKey:moduleName];
            if ([interceptor respondsToSelector:@selector(didFinishDownloadFile:atPath:)]) {
                [interceptor didFinishDownloadFile:filename atPath:[path stringByDeletingLastPathComponent]];
            }
            return;// 本地存在,跳过下载 (是否需要回调)
        }
        // 主动触发任务埋点
        info.isExplicitTrigger = YES;
        [self downloadSourceWithName:resource.name info:info moduleName:moduleName moduleFolder:moduleFolder delegate:self.downloadDispatcher];
    } failure:^(NSError *error) {
        TrumpLogInfo(@"sniffer failed - module - %@ file - %@", moduleName, filename);
    }];
}

- (void)requestSourceWithModule:(NSString *)moduleName {
    if (!isTrumpEnable || moduleName.length == 0 || [self hasReachedMaxDownloadSize]) {
        TrumpLogInfo(@"download ignored (apollo enabled - %d, modulename - %@)", isTrumpEnable, moduleName, [self hasReachedMaxDownloadSize]);
        return;
    }
    
    TRSourceModule *module = nil;
    for (TRSourceModule * obj in self.sources.contents) {
        if ([obj.module isEqualToString:moduleName]) {
            module = obj;
            break;
        }
    }
    
    if (!module) {
        TrumpLogInfo(@"download ignored ,module not found (moudleName - %@)", moduleName);
        return;
    }
    
    for (TRResource *resource in module.resources) {
        TRSourceSniffer *sniffer = [[TRSourceSniffer alloc] init];
        [sniffer snifferGiftSourceWithNamespace:resource.ns key:resource.key success:^(TRSourceInfo * _Nonnull info) {
            // 1.存在 2.md5校验 3.下载
            NSString *moduleFolder = [self.fileManager createFolderForModule:moduleName];
            NSString *path = [[TRSourceFileManager defaultManager] pathForModule:moduleName file:resource.name isDir:NO] ?: @"";
            BOOL verify = [[TRSourceFileManager defaultManager] verifyAndDeleteFileIfNotPassed:path md5:info.md5];
            if (verify)  {
                TrumpLogInfo(@"Local source exist (module - %@ filename - %@), download ignored", moduleName, resource.name);
                id interceptor = [self.interceptors valueForKey:moduleName];
                if ([interceptor respondsToSelector:@selector(didFinishDownloadFile:atPath:)]) {
                    [interceptor didFinishDownloadFile:resource.name atPath:[path stringByDeletingLastPathComponent]];
                }
                return;// 本地存在,跳过下载 (是否需要回调)
            }
            [self downloadSourceWithName:resource.name info:info moduleName:moduleName moduleFolder:moduleFolder delegate:self.downloadDispatcher];
        } failure:^(NSError *error) {
            TrumpLogInfo(@"sniffer failed - module - %@ file - %@", moduleName, resource.name);
        }];
    }
}

+ (instancetype)defaultManager {
    static TRSourceManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.interceptors = [NSMutableDictionary dictionary];
        [instance addObserverForApplicateStateSwitch];
    });
    
    if ([instance isTrumpEnabled]) {
        [instance tr_initialize];
    }
    
    return instance;
}

- (void)addObserverForApplicateStateSwitch {
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didApplicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didApplicationBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)tr_initialize {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        self.fileManager = [TRSourceFileManager defaultManager];
        [self loadConfig];
        [self checkIfNeedDeleteLocalfile];
    });
}

/// 进入后台时check阿波罗开关情况,如果打开则初始化
//- (void)didApplicationEnterBackground {
//    if ([self isTrumpEnabled]) {
//        [self tr_initialize];
//    }
//}

/// 进入前台时check阿波罗开关情况,如果打开则初始化 并开启下载任务
- (void)didApplicationBecomeActive {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self tryToDownload];
    });
}


/// 开关是否开启
- (BOOL)isTrumpEnabled {
    isTrumpEnable = YES;
    // 该功能是否开启,如有该基础能力,可进行配置下发
    return isTrumpEnable;
}


/// 避免过度下载
- (BOOL)hasReachedMaxDownloadSize {
    return kTrumpDownloadSizeAlready >= kMaxDownloadSize;
}


/// 读取远端的配置
- (void)loadConfig {
#warning    // 从线上平台读取远端配置 依赖基础能力, 如没有线上更新功能可将该配置写死在本地
    NSString *config = nil;
    self.sources = [[TRSources alloc] initWithString:config error:nil];
}

/// diff远端与本地沙盒配置,做删除更新(删除沙盒中的本地文件)
- (void)checkIfNeedDeleteLocalfile {
    TRLocalRecord *record = [TRLocalRecord new];
    
    NSMutableArray *modules = [NSMutableArray array];
    NSMutableArray *sources = [NSMutableArray array];
    for (TRSourceModule *m in self.sources.contents) {
        TRLocalModule *model = [[TRLocalModule alloc] init];
        model.name = m.module;
        [modules addObject:model];
        
        for (TRResource *rs in m.resources) {
            TRLocalSource *s = [TRLocalSource new];
            s.module = m.module;
            s.name = rs.name;
            [sources addObject:s];
        }
    }
    record.modules = modules.copy;
    record.sources = sources.copy;
    [[TRSourceFileManager defaultManager] checkIfNeedDeleteLocalfile:record];
}

- (void)tryToDownload {
    if ([self isTrumpEnabled]) {
        [self tr_initialize];
    }
    
    [self prepareResourceForModules];
}


/// 尝试下载文件等一连串逻辑
- (void)prepareResourceForModules {
    if (!isTrumpEnable || [self hasReachedMaxDownloadSize]) return;
    
    for (TRSourceModule *module in self.sources.contents) {
        if ([self.interceptors valueForKey:module.module] != nil) {
            [self downloadFileForModuleIfNeed:module];
        }
    }
}

/// 下载对应模块的资源
/// @param module 业务模块
- (void)downloadFileForModuleIfNeed:(TRSourceModule *)module {
    TRSourceSniffer *sniffer = [[TRSourceSniffer alloc] init];
    for (TRResource *source in module.resources) {
        // 通过namespace & key 去 gift 服务器嗅探其详细信息
        [sniffer snifferGiftSourceWithNamespace:source.ns key:source.key success:^(TRSourceInfo * _Nonnull info) {
            // 1.存在 2.md5校验 3.下载
            NSString *moduleFolder = [self.fileManager createFolderForModule:module.module];
            NSString *path = [[TRSourceFileManager defaultManager] pathForModule:module.module file:source.name isDir:NO] ?: @"";
            BOOL verify = [[TRSourceFileManager defaultManager] verifyAndDeleteFileIfNotPassed:path md5:info.md5];
            if (verify) {
                TrumpLogInfo(@"Local source exist (module - %@ filename - %@), download ignored", module.module, source.name);
                return; // 本地存在文件,跳过下载
            }
            // 询问业务方是否需要预加载
            id interceptor = [self.interceptors valueForKey:module.module];
            BOOL preload = YES;
            if ([interceptor respondsToSelector:@selector(shouldPreloadFile:)]) {
                preload = [interceptor shouldPreloadFile:source.name];
            }
            if (!preload) {
                TrumpLogInfo(@"refuse to preload file (module - %@, filename - %@)", module.module, source.name);
                return;
            }
            
            [self downloadSourceWithName:source.name info:info moduleName:module.module moduleFolder:moduleFolder delegate:self.downloadDispatcher];
        } failure:^(NSError *erro) {
            TrumpLogInfo(@"sniffer failed - module - %@ file - %@", module.module, source.name);
        }];
    }
}


/// 启动下载任务
/// @param filename 文件名
/// @param info 文件的相关信息(下载链接 md5等等)
/// @param module 文件所属业务方
/// @param folder 下载文件的存储文件夹
/// @param delegate 回调
- (void)downloadSourceWithName:(NSString *)filename info:(TRSourceInfo *)info moduleName:(NSString *)module moduleFolder:(NSString *)folder delegate:(id <TRDownloaderDelegate>)delegate {
    NSString *downloadKey = [NSString stringWithFormat:@"%@_%@", module, filename];
    TRDownloader *task = [[TRDownloadManager defaultManager] downloadTaskWithKey:downloadKey];
    // 避免多次触发同一个文件的资源下载任务
    if (task) return;
    
    NSURL *URL = [NSURL URLWithString:info.download_url_https];
    if (!URL) return;
    
    TRDownloadManager *dlm = [TRDownloadManager defaultManager];
    TRDownloader *dl = [dlm downloaderWithURL:URL customPath:folder fileName:filename retry:3 retryInterval:3 delegate:delegate];
    [dlm startDownload:dl];
    [dlm setDownloadTask:dl forKey:downloadKey];
    info.module = module;
    dl.model = info;
    TrumpLogInfo(@"download task created, module - %@ filename - %@", module, filename);
}


/// 注册业务方拦截器
/// @param interceptor 拦截器,由个业务方实现
- (void)registerSourceInterceptor:(id <TRSourceProtocol>)interceptor {
    [self.interceptors setValue:interceptor forKey:interceptor.moduleName];
}


/// 注册业务方拦截器
/// @param interceptors 拦截器数组,拦截器由个业务方实现
- (void)registerSourceInterceptors:(NSArray <TRSourceProtocol> *)interceptors {
    [interceptors enumerateObjectsUsingBlock:^(id <TRSourceProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.interceptors setValue:obj forKey:obj.moduleName];
    }];
}


/// 获取文件的配置(ns, key)
/// @param moduleName 业务方
/// @param filename 文件名
- (TRResource *)resourceOfModule:(NSString *)moduleName fileName:(NSString *)filename {
    TRSourceModule *module = nil;
    for (TRSourceModule * obj in self.sources.contents) {
        if ([obj.module isEqualToString:moduleName]) {
            module = obj;
            break;
        }
    }

    TRResource *resource = nil;
    for (TRResource *obj in module.resources) {
        if ([obj.name isEqualToString:filename]) {
            resource = obj;
            break;
        }
    }

    return resource;
}

#pragma mark - 下载回调

- (void)download:(TRDownloader *)blobDownload didReceiveFirstResponse:(NSURLResponse *)response {
    TRSourceInfo *info = blobDownload.model;
    if (info.beginContentLength > 0) { // 断点续传日志
        TrumpLogInfo(@"breakpoint transfer - beginContentLenght - %f", info.beginContentLength);
    }
}
- (void)download:(TRDownloader *)blobDownload didStopWithError:(NSError *)error {
    TRSourceInfo *info = blobDownload.model;
    kTrumpDownloadSizeAlready += info.receivedLength - info.beginContentLength;
}

- (void)download:(TRDownloader *)blobDownload didFinishWithSuccess:(BOOL)downloadFinished atPath:(NSString *)pathToFile {
    if (downloadFinished) {
        TRSourceInfo *info = blobDownload.model;
        
        kTrumpDownloadSizeAlready += info.receivedLength - info.beginContentLength;
        // 下载完成Md5校验,校验失败删除文件
        BOOL verify = [self.fileManager verifyAndDeleteFileIfNotPassed:pathToFile md5:info.md5];
        if (!verify) {
            TrumpLogInfo(@"download finished, file is delete because of md5 verify failure. path - %@", pathToFile);
            return;
        }
        
        //获取文件路径的文件夹
        NSString *fileDir = [pathToFile stringByDeletingLastPathComponent];
        [self.fileManager recordLocalFilePath:fileDir forFile:pathToFile.lastPathComponent ofModule:info.module];
        // 通知拦截下载完成
        TrumpLogInfo(@"download success at path - %@ module - %@ file - %@", fileDir, info.module, blobDownload.fileName);
        id interceptor = [self.interceptors valueForKey:info.module];
        if ([interceptor respondsToSelector:@selector(didFinishDownloadFile:atPath:)]) {
            [interceptor didFinishDownloadFile:blobDownload.fileName atPath:fileDir];
        }
    }
}

#pragma mark - lazy load
- (TRDownloaderDelegateDispatcher *)downloadDispatcher {
    if (!_downloadDispatcher) {
        _downloadDispatcher = [[TRDownloaderDelegateDispatcher alloc] initWithInterceptors:[NSArray<TRDownloaderDelegate> arrayWithObjects: [TRDownloadAnalytics new], self, nil]];
    }
    
    return _downloadDispatcher;
}
@end
