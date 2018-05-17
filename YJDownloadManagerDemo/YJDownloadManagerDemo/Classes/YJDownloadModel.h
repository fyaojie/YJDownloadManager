//
//  YJDownloadModel.h
//  HJDownloadManager
//
//  Created by cool on 2018/5/17.
//  Copyright © 2018 WHJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 缓存主目录
#define  YJCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"/YJDownload/"]
#define YJDownloadNoteCenter [NSNotificationCenter defaultCenter]
#define kYJDownloadManager [YJDownloadManager sharedManager]

/******** 通知 Begin ********/
/** 下载进度发生改变的通知 */
extern NSString * const YJDownloadProgressDidChangeNotification;
/** 下载状态发生改变的通知 */
extern NSString * const YJDownloadStateDidChangeNotification;
/** 利用这个key从通知中取出对应的MJDownloadInfo对象 */
extern NSString * const YJDownloadInfoKey;

@class YJDownloadOperation;
@class YJDownloadModel;

typedef NS_ENUM(NSUInteger, YJDownloadStatus) {
    kYJDownloadStatus_None = 0,
    kYJDownloadStatus_Running = 1,
    kYJDownloadStatus_Suspended = 2,
    kYJDownloadStatus_Completed = 3,  // 下载完成
    kYJDownloadStatus_Failed  = 4,    // 下载失败
    kYJDownloadStatus_Waiting = 5,   // 等待下载
    kYJDownloadStatus_Cancel = 6,      // 取消下载
};

typedef void(^DownloadStatusChanged)(YJDownloadModel *downloadModel);
typedef void(^DownloadProgressChanged)(YJDownloadModel *downloadModel);

@interface YJDownloadModel : NSObject

/** 下载文件的URL */
@property (nonatomic ,copy) NSString * fileURL;
/** 下载描述信息 */
@property (nonatomic, copy) NSString * downloadDesc;
// 真实文件名
@property (nonatomic, copy) NSString * fileName;
// 本地文件名用于查找文件位置（url->md5）
@property (nonatomic, copy, readonly) NSString * localFileName;
/** 文件的类型(文件后缀,比如:mp4)*/
@property (nonatomic, copy, readonly) NSString * fileType;
/** 文件本地存放地址 */
@property (nonatomic, copy) NSString * destinationPath;
/** 下载操作 */
@property (nonatomic, strong) YJDownloadOperation * operation;
/** 下载进度 */
@property (nonatomic, assign) CGFloat progress;
/** 下载状态 */
@property (nonatomic, assign) YJDownloadStatus status;
/** 下载状态文字 */
@property (nonatomic, copy) NSString * statusText;
/** 下载完成时间 */
@property (nonatomic, copy) NSString * completeTime;
/** 状态改变回调 */
@property (nonatomic, copy) DownloadStatusChanged statusChanged;
/** 进度改变回调 */
@property (nonatomic, copy) DownloadProgressChanged progressChanged;
/** 文件总大小 */
@property (nonatomic, assign) NSInteger fileTotalSize;
/** 已下载文件大小 */
@property (nonatomic, assign) NSInteger fileDownloadSize;
/** 输出流 */
@property (nonatomic, strong) NSOutputStream *stream;
/** 是否下载完成 */
@property (nonatomic, assign) BOOL isFinished;
/** 错误 */
@property (nonatomic, strong) NSError *error;
@end
