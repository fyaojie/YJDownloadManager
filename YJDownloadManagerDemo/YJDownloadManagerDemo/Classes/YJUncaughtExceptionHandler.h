//
//  YJUncaughtExceptionHandler.h
//  HJDownloadManager
//
//  Created by cool on 2018/5/17.
//  Copyright © 2018 WHJ. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const kNotificationUncaughtException = @"kNotificationUncaughtException";

@interface YJUncaughtExceptionHandler : NSObject

+ (void)setDefaultHandler;
+ (NSUncaughtExceptionHandler *)getHandler;
+ (void)TakeException:(NSException *) exception;

@end
