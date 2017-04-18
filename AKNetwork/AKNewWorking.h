//
//  AKNewWorking.h
//  CollectionViewTableView
//
//  Created by dllo on 15/12/21.
//  Copyright © 2015年 LML-PC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AKNewWorking : NSObject


/**
 *  get缓存
 */
+ (void)getDataWithURL:(NSString *)urlStr dic:(NSDictionary *)dic success:(void(^)(id responseObject))response filed:(void(^)(NSError *error))err;

/**
 *  Post缓存
 */
+ (void)postDataWithURL:(NSString *)urlStr dic:(NSDictionary *)dic success:(void(^)(id responseObject))response filed:(void(^)(NSError *error))err;
/**
 *  SOAP缓存
 */
+ (void)getSOAPUrl:(NSMutableDictionary *)paraDic success:(void (^)(id responseObject))success failure:(void(^)(NSError *error))failure;

@end
