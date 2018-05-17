//
//  YJDownloadOperation.h
//  HJDownloadManager
//
//  Created by cool on 2018/5/17.
//  Copyright © 2018 WHJ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^DownloadStatusChangedBlock)(void);

@class YJDownloadModel;

@interface NSURLSessionTask (YJModel)
@property (nonatomic, weak)YJDownloadModel  * downloadModel;
@end

@interface YJDownloadOperation : NSOperation

@property (nonatomic, weak) YJDownloadModel * downloadModel;

@property (nonatomic, strong) NSURLSessionDataTask * downloadTask;

@property (nonatomic ,weak) NSURLSession *session;

/** 下载状态改变回调 */
@property (nonatomic, copy) DownloadStatusChangedBlock downloadStatusChangedBlock ;

- (instancetype)initWithDownloadModel:(YJDownloadModel *)downloadModel andSession:(NSURLSession *)session;

- (void)suspend;
//- (void)resume;
@end
