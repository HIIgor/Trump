#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "TRDownloadAnalytics.h"
#import "TRDownloaderDelegateDispatcher.h"
#import "TRExplictDownloadCallback.h"
#import "TRDownload.h"
#import "TRDownloader.h"
#import "TRDownloader_Internal.h"
#import "TRDownloadManager.h"
#import "TRSourceFileManager.h"
#import "TRSourceLocalInfo.h"
#import "TRSource.h"
#import "TRSourceCommon.h"
#import "TRSourceManager.h"
#import "TRSourceModel.h"
#import "TRSourceProtocol.h"
#import "TRSourceSniffer.h"
#import "TRSource_Internal.h"
#import "Trump.h"

FOUNDATION_EXPORT double TrumpVersionNumber;
FOUNDATION_EXPORT const unsigned char TrumpVersionString[];

