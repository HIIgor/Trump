//
//  TRSourceLocalInfo.h
//  Trump
//
//  Created by igor xiang on 2021/7/9.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TRLocalModule <NSObject>
@end
@interface TRLocalModule : JSONModel

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *dir;

@end

@protocol TRLocalSource <NSObject>
@end
@interface TRLocalSource : JSONModel

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *dir;
@property (nonatomic, copy) NSString *module;

@end

@interface TRLocalRecord : JSONModel

@property (nonatomic, copy) NSArray <TRLocalModule>*modules;
@property (nonatomic, copy) NSArray <TRLocalSource>*sources;
//@property (nonatomic, copy) NSString *version;

@end

NS_ASSUME_NONNULL_END
