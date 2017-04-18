//
//  AKNewWorking.m
//
//  Created by 赵博 on 17/4/17.
//  Copyright © 2017年 赵博. All rights reserved.
//

#import "AKNewWorking.h"
#import <AFNetworking.h>
#import <commoncrypto/CommonCrypto.h>
#import "Reachability.h"
#import "AllApi.h"
@implementation AKNewWorking

+ (void)getDataWithURL:(NSString *)urlStr dic:(NSDictionary *)dic success:(void (^)(id))response filed:(void (^)(NSError *))err
{
    
#warning 2.判断网络状态
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    if (0 != reach.currentReachabilityStatus) {
       
    AFHTTPSessionManager *man = [AFHTTPSessionManager manager];
   //有的返回值的数据类型，AFN不支持解析，我们需要设置一下，让AFN支持解析
    [man.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"text/html", @"application/json", @"text/json", @"text/javascript",@"text/html",@"text/css", @"text/plain", @"application/x-javascript", @"application/javascript",nil]];
    [man GET:urlStr parameters:dic success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //返回数据给调用方response(是个block)responseObject(返回的数据类型是id类型)
        response(responseObject);
//调用获取缓存路径方法，把网址和网络请求成功的值传入
        [self cachePath:urlStr respose:responseObject type:0];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
       
        err(error);
        
    }];
    }else{
        //无网走缓存
        //拿到缓存路径
        //response 后面参数，因为我们没走网络请求，我不是要缓存数据，而是要获取数据
        id data = [self cachePath:urlStr respose:nil type:1];
        if (data != nil) {
            //写个保护
            response(data);
  
        }
    }

};

+ (void)postDataWithURL:(NSString *)urlStr dic:(NSDictionary *)dic success:(void (^)(id))response filed:(void (^)(NSError *))err
{
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    if (0 != reach.currentReachabilityStatus) {
        
        AFHTTPSessionManager *man = [AFHTTPSessionManager manager];
        //有的返回值的数据类型，AFN不支持解析，我们需要设置一下，让AFN支持解析
        [man.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"text/html", @"application/json", @"text/json", @"text/javascript",@"text/html",@"text/css", @"text/plain", @"application/x-javascript", @"application/javascript",nil]];
        
        [man GET:urlStr parameters:dic success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            //返回数据给调用方response(是个block)responseObject(返回的数据类型是id类型)
            response(responseObject);
            //调用获取缓存路径方法，把网址和网络请求成功的值传入
            [self cachePath:urlStr respose:responseObject type:0];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            err(error);
            
        }];
    }else{
        //无网走缓存
        //拿到缓存路径
        //response 后面参数，因为我们没走网络请求，我不是要缓存数据，而是要获取数据
        id data = [self cachePath:urlStr respose:nil type:1];
        if (data != nil) {
            //写个保护
            response(data);
            
        }
    }
    
}

/**
 *  SOAP请求 接口
 *
 */
+ (void)getSOAPUrl:(NSMutableDictionary *)paraDic success:(void (^)(id responseObject))success failure:(void(^)(NSError *error))failure{


    //请求接口
    NSString *url = [NSString stringWithFormat:@"%@%@",NEWS_List,Path_WebService_CmsWs];
    // 得到发送数据长度
    NSString * postData = [self getSOAPXML:Soap_MethodName soapAction:Soap_NameSpace paraDic:paraDic];
    
    NSString *msgLength = [NSString stringWithFormat:@"%ld", (unsigned long)[postData length]];

    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
    NSLog(@"manager.responseSerializer = %@", manager.responseSerializer);
    
    [manager.requestSerializer setValue:@"application/soap+xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

     [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"text/html", @"application/json", @"text/json", @"text/javascript",@"text/css", @"text/plain", @"application/x-javascript", @"application/javascript",@"application/soap+xml",@"text/xml",nil]];
    [manager.requestSerializer setValue:msgLength forHTTPHeaderField:@"Content-Length"];
  

    // 设置HTTPBody AFN3.0后唯一方法
    [manager.requestSerializer setQueryStringSerializationWithBlock:^NSString *(NSURLRequest *request, NSDictionary *parameters, NSError *__autoreleasing *error) {
        return postData;
    }];
    
    [manager POST:url parameters:paraDic progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //把返回的二进制数据转为字符串
        NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        // 利用正则表达式取出<return></return>之间的字符串
        NSRegularExpression *regular = [[NSRegularExpression alloc] initWithPattern:@"(?<=return\\>).*(?=</return)" options:NSRegularExpressionCaseInsensitive error:nil];
        NSDictionary *dict = [NSDictionary dictionary];
        for (NSTextCheckingResult *checkingResult in [regular matchesInString:result options:0 range:NSMakeRange(0, result.length)]) {
            // 得到字典
            dict = [NSJSONSerialization JSONObjectWithData:[[result substringWithRange:checkingResult.range] dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:nil];
        }
        // 请求成功并且结果有值把结果传出去
        if (success && dict) {
            success(dict);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
    
    

}





+ (NSString *)getSOAPXML:(NSString *)soapNameSpace soapAction:(NSString *)soapAction paraDic:(NSDictionary *)paraDic {
    
    NSMutableString *soapXml = [NSMutableString string];
    
    
    [soapXml appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"];
    
    // Sopa Header
    [soapXml appendString:@"<soap:Envelope xmlns:xsi=\"http://www.w3.org/1999/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/1999/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"];
       // Soap Body
    [soapXml appendString:@"<soap:Body>\n"];
    
    // Soap Function
    [soapXml appendString:[NSString stringWithFormat:@"<n0:%@ xmlns:n0=\"%@\">\n", soapAction,soapNameSpace]];
    
    // Data
    if (paraDic != nil && [paraDic count] > 0) {
        // Add Data
        NSArray *keys = [paraDic allKeys];
        
        NSString * key;
        NSString * value;
        
        for (int i = 0; i < [keys count]; i++)
        {
            key = [keys objectAtIndex:i];
            value = [paraDic objectForKey:key];
            
            // Name
            [soapXml appendString:[NSString stringWithFormat:@"<%@>",key]];
            
            // Data
            //    &lt;
            //
            //    <
            //
            //    小于号
            value = [value stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
            
            //
            //    &gt;
            //
            //    >
            //
            //    大于号
            value = [value stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
            
            [soapXml appendString:value];
            
            // Name End
            [soapXml appendString:[NSString stringWithFormat:@"</%@>\n",key]];
        }
    }
    
    // Soap Function End
    [soapXml appendString:[NSString stringWithFormat:@"</n0:%@>\n", soapAction]];
    
    // Soap Body End
    [soapXml appendString:@"</soap:Body>\n"];
    
    // Sopa Header End
    [soapXml appendString:@"</soap:Envelope>\n"];
    
//    NSData *resultData;
//    
//    resultData = [soapXml dataUsingEncoding:NSUTF8StringEncoding];
    
    return soapXml;
}






+ (id)cachePath:(NSString *)urlStr respose:(id)responseObject type:(NSInteger)type
{
    
#warning 注意：1.开始做缓存
    //1.把网址利用MD5加密算法转化成数字和字符串的组合（因为网址不能直接作为文件名）
    //如果self后面调用的是-号方法，那么这个self就是奔雷的对象。例如Person* per= nil, self就是这个per.
    //如果self 后面调用的是+号方法，那么这个self就是奔雷的名字Person就是self
    NSString *fileName = [self cachedFileNameForKey:urlStr];
    
    //2.找到cache文件夹在沙盒中得路径
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    
    //3.路径文件名拼接
    NSString *cacheP = [cachePath stringByAppendingPathComponent:fileName];
    
    //4.把网络请求成功的数据（归档）
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:responseObject];
    //5.最后一步 写入本地
    if (0 == type) {
        //如果type是0则代表我要写入1读取
    [data writeToFile:cacheP atomically:YES];
        return nil;
    }else if (1 == type){
        //读取
        id data = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheP]
        ;
        return data;
    }else{
        NSLog(@"%@", cacheP);
        return nil;
    }
    
    return cacheP;
}

// 利用MD5算法把网址转换成一串数字加字母
+ (NSString *)cachedFileNameForKey:(NSString *)key {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    return filename;
}
@end
