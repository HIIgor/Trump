//
//  TRSource_Internal.h
//  Pods
//
//  Created by igor xiang on 2021/5/11.
//

#import "TRSource.h"

#ifndef TRSource_Internal_h
#define TRSource_Internal_h

@interface TRSource ()

@property (nonatomic, copy) NSString *module;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, assign) BOOL isDir;

@end

#endif /* TRSource_Internal_h */
