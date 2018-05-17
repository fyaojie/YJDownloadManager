//
//  YJDownloadManager.h
//  HJDownloadManager
//
//  Created by cool on 2018/5/17.
//  Copyright © 2018 WHJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YJDownloadModel.h"

typedef NS_ENUM(NSUInteger, YJOperationType) {
    kYJOperationType_startAll,
    kYJOperationType_suspendAll ,
    kYJOperationType_resumeAll,
    kYJOperationType_stopAll
};

@interface YJDownloadManager : NSObject

@property (nonatomic, strong, readonly) NSMutableArray * downloadModels;

@property (nonatomic, strong, readonly) NSMutableArray * completeModels;

@property (nonatomic, strong, readonly) NSMutableArray * downloadingModels;

@property (nonatomic, strong, readonly) NSMutableArray * pauseModels;

@property (nonatomic, strong, readonly) NSMutableArray * waitModels;

@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;

/** 是否禁用进度打印日志 */
@property (readonly, nonatomic, assign) BOOL enableProgressLog;

#pragma mark - 单例方法
+ (instancetype)sharedManager;

/**
 *  启动网络监听，在appdelete中调用
 */
- (void)startNotifier;

/**
 *  禁止打印进度日志
 */
- (void)enableProgressLog:(BOOL)enable;
/**
 *  获取下载模型
 */
- (YJDownloadModel *)downloadModelWithUrl:(NSString *)url;

#pragma mark - 下载

/**
 *  下载一个文件
 *
 *  @param url  文件的URL路径
 *
 *  @return YES代表文件已经下载完毕
 */
- (YJDownloadModel *)download:(NSString *)url;

/**
 *  下载一个文件
 *
 *  @param url      文件的URL路径
 *  @param state    状态改变的回调
 *
 *  @return YES代表文件已经下载完毕
 */
- (YJDownloadModel *)download:(NSString *)url state:(DownloadStatusChanged)state;

/**
 *  下载一个文件
 *
 *  @param url          文件的URL路径
 *  @param progress     下载进度的回调
 *  @param state        状态改变的回调
 *
 *  @return YES代表文件已经下载完毕
 */
- (YJDownloadModel *)download:(NSString *)url progress:(DownloadProgressChanged)progress state:(DownloadStatusChanged)state;

/**
 *  下载一个文件
 *
 *  @param url              文件的URL路径
 *  @param destinationPath  文件的存放路径
 *  @param progress         下载进度的回调
 *  @param state            状态改变的回调
 *
 *  @return YES代表文件已经下载完毕
 */
- (YJDownloadModel *)download:(NSString *)url toDestinationPath:(NSString *)destinationPath progress:(DownloadProgressChanged)progress state:(DownloadStatusChanged)state;

/**
 *  开始下载
 */
- (void)startWithDownloadModel:(YJDownloadModel *)model;
/**
 *  批量下载操作
 */
- (void)startWithDownloadModels:(NSArray<YJDownloadModel *> *)downloadModels;
#pragma mark - 暂停下载
/**
 *  暂停下载某个文件
 */
- (YJDownloadModel *)suspend:(NSString *)url;
/**
 *  暂停所有下载任务
 */
- (void)suspendAll;
/**
 *  暂停下载
 */
- (void)suspendWithDownloadModel:(YJDownloadModel *)model;

#pragma mark - 恢复下载
/**
 *  开始\继续下载某个文件
 */
- (YJDownloadModel *)resume:(NSString *)url;
/**
 *  恢复下载
 */
- (void)resumeWithDownloadModel:(YJDownloadModel *)model;
/**
 *  恢复下载任务（进行中、已完成、等待中除外）
 */
- (void)resumeAll;

#pragma mark - 取消下载
/**
 *  取消下载 (取消下载后 operation将从队列中移除 并 移除下载模型和对应文件)
 */
- (void)stopWithDownloadModel:(YJDownloadModel *)model;

/**
 *  取消下载某个文件(一旦被取消了，需要重新调用download方法)
 */
- (YJDownloadModel *)cancel:(NSString *)url;

/**
 *  停止并删除下载任务
 */
- (void)stopAll;

@end
