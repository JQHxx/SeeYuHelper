//
//  SYRCIMDataSource.h
//  SeeYu
//
//  Created by 唐荣才 on 2019/1/16.
//  Copyright © 2019年 fljj. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SYRCIMDataSource : NSObject <RCIMUserInfoDataSource>

+ (SYRCIMDataSource *)shareInstance;

@end

NS_ASSUME_NONNULL_END
