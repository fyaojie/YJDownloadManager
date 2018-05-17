//
//  YJDownloadModel.m
//  HJDownloadManager
//
//  Created by cool on 2018/5/17.
//  Copyright © 2018 WHJ. All rights reserved.
//

#import "YJDownloadModel.h"
#import <MJExtension.h>
#import <CommonCrypto/CommonDigest.h>

/******** 通知 Begin ********/
/** 下载进度发生改变的通知 */
NSString * const YJDownloadProgressDidChangeNotification = @"MJDownloadProgressDidChangeNotification";
/** 下载状态发生改变的通知 */
NSString * const YJDownloadStateDidChangeNotification = @"MJDownloadStateDidChangeNotification";
/** 利用这个key从通知中取出对应的MJDownloadInfo对象 */
NSString * const YJDownloadInfoKey = @"MJDownloadInfoKey";
/******** 通知 End ********/

@implementation NSString (Download)
- (NSString *)md5Encrypt {
    const char *original_str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, (int)strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
    {
        [hash appendFormat:@"%02X", result[i]];
    }
    return [hash lowercaseString];
}
@end

@implementation YJDownloadModel

MJCodingImplementation

- (NSString *)localFileName {
    if (!self.fileURL || self.fileURL.length <= 0) {
        return nil;
    }
    return self.fileURL.md5Encrypt;
}

- (NSString *)destinationPath{
    if (_destinationPath) {
        return _destinationPath;
    }
    return [YJCachesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",self.localFileName,self.fileType]];
}

- (NSString *)fileName {
    
    if (_fileName) {
        return _fileName;
    }
    
    if (!self.fileURL || self.fileURL.length <= 0) {
        return nil;
    }
    return self.fileURL.lastPathComponent;
}

//- (NSString *)fileName{
//    if (!_fileName) {
//        NSTimeInterval timeInterval = [[NSDate date]timeIntervalSince1970];
//        //解决多个任务同时开始时 文件重名问题
//        NSString *timeStr = [NSString stringWithFormat:@"%.6f",timeInterval];
//        timeStr = [timeStr stringByReplacingOccurrencesOfString:@"." withString:@"_"];
//        _fileName = [NSString stringWithFormat:@"%@",timeStr];
//    }
//    return _fileName;
//}

- (NSString *)fileType {
    return self.fileName.pathExtension;
}

- (void)setFileDownloadSize:(NSInteger)fileDownloadSize {
    
    // 下载进度
    NSInteger totalBytesWritten = self.fileDownloadSize;
    NSInteger totalBytesExpectedToWrite = self.fileTotalSize;
    
    double byts = totalBytesWritten * 1.0 / 1024 /1024;
    double total = totalBytesExpectedToWrite * 1.0 / 1024 /1024;
    NSString *text = [NSString stringWithFormat:@"%.1lfMB/%.1lfMB",byts,total];
    
    CGFloat progress = 1.0 * byts / total;
    
    self.progress = progress;
    if (total <= 0) {
        self.progress = 0;
    }
    
    if (self.progress > 0) {
        self.statusText = text;
    }
}

- (void)setProgress:(CGFloat)progress{
    if (_progress != progress) {
        _progress = progress;
    }
    
    if (self.progressChanged) {
        self.progressChanged(self);
    }
    
    [YJDownloadNoteCenter postNotificationName:YJDownloadProgressDidChangeNotification
                                        object:self
                                      userInfo:@{YJDownloadInfoKey : self}];
}

- (void)setStatus:(YJDownloadStatus)status{
    
    if (_status != status) {
        _status = status;
        [self setStatusTextWith:_status];
        
        if (self.statusChanged) {
            self.statusChanged(self);
        }
        
        [YJDownloadNoteCenter postNotificationName:YJDownloadStateDidChangeNotification
                                            object:self
                                          userInfo:@{YJDownloadInfoKey : self}];
    }
}

- (void)setCompleteTime:(NSString *)completeTime{
    NSDateFormatter *fomatter = [[NSDateFormatter alloc]init];
    _completeTime = [fomatter stringFromDate:[NSDate date]];
}

- (void)setStatusTextWith:(YJDownloadStatus)status{
    _status = status;
    
    switch (status) {
        case kYJDownloadStatus_Running:
            self.statusText = @"正在下载";
            break;
        case kYJDownloadStatus_Suspended:
            self.statusText = @"暂停下载";
            break;
        case kYJDownloadStatus_Failed:
            self.statusText = @"下载失败";
            break;
        case kYJDownloadStatus_Cancel:
            self.statusText = @"取消下载";
            break;
        case kYJDownloadStatus_Waiting:
            self.statusText = @"等待下载";
            break;
        case kYJDownloadStatus_Completed:
            self.statusText = @"下载完成";
            break;
        default:
            break;
    }
    
    NSLog(@"%@==%@",self.fileName,self.statusText);
}

+ (NSArray *)mj_ignoredCodingPropertyNames{
    
    return @[@"statusChanged",@"progressChanged",@"stream",@"operation",@"fileDownloadSize",@"localFileName",@"destinationPath",@"fileType"];
}

- (NSInteger)fileDownloadSize{
    // 获取文件下载长度
    NSInteger fileDownloadSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:self.destinationPath error:nil][NSFileSize] integerValue];
    return fileDownloadSize;
}

- (NSOutputStream *)stream{
    if (!_stream) {
        _stream =  [NSOutputStream outputStreamToFileAtPath:self.destinationPath append:YES];
    }
    return _stream;
}

- (BOOL)isFinished{
    return (self.fileTotalSize == self.fileDownloadSize) && (self.fileTotalSize != 0);
}
@end
