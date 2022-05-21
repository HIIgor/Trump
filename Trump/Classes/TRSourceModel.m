//
//  TRSourceModel.m
//  Trump
//
//  Created by igor xiang on 2021/7/8.
//

#import "TRSourceModel.h"

@implementation TRResource
+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}
@end


@implementation TRSourceModule
@end


@implementation TRSources
@end


@implementation TRSourceInfo

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    self = [super initWithDictionary:dict error:err];
    if (self) {
        _module = @"";
        _beginContentLength = 0;
        _totalLength = 0;
        _receivedLength = 0;
        _beginTime = 0;
    }
    
    return self;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return  [propertyName isEqualToString:@"module"] ||
            [propertyName isEqualToString:@"beginContentLength"] ||
            [propertyName isEqualToString:@"totalLength"] ||
            [propertyName isEqualToString:@"receivedLength"] ||
            [propertyName isEqualToString:@"beginTime"] ||
            [propertyName isEqualToString:@"isExplicitTrigger"];
}

@end
