//
//  TRSource.m
//  Trump
//
//  Created by igor xiang on 2021/5/11.
//

#import "TRSource.h"
#import "TRSource_Internal.h"

@implementation TRSource

- (NSString *)subfilePathForName:(NSString *)name {
    if (name.length == 0 || !self.isDir) return nil;
    
    return [self.filePath stringByAppendingPathComponent:name];
}

@end
