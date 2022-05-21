//
//  TRSourceSniffer.m
//  Trump
//
//  Created by igor xiang on 2021/5/10.
//

#import "TRSourceSniffer.h"

@implementation TRSourceSniffer

- (void)snifferGiftSourceWithNamespace:(NSString *)ns key:(NSString *)key success:(void (^)(TRSourceInfo *info))success failure:(void (^)(NSError *))failure {
    NSString *hxy02host = @"http://100.19.138.37:8000"; // your gift service
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/resource/%@/%@", hxy02host, ns, key]];
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:URL];
    mutableRequest.HTTPMethod = @"GET";
    [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:mutableRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error && failure) {
            failure(error);
            return;
        }
        
        NSDictionary *obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            TRSourceInfo *info = [[TRSourceInfo alloc] initWithDictionary:obj error:nil];
            !success ?: success(info);
        } else {
            NSError *e = [NSError errorWithDomain:@"返回数据校验失败" code:-999 userInfo:nil];
            !failure ?: failure(e);
        }
    }];
        
    [dataTask resume];
}

@end
