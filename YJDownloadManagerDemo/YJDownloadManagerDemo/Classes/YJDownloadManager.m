//
//  YJDownloadManager.m
//  HJDownloadManager
//
//  Created by cool on 2018/5/17.
//  Copyright © 2018 WHJ. All rights reserved.
//

#import "YJDownloadManager.h"
#import "RealReachability.h"
#import "YJUncaughtExceptionHandler.h"
#import "YJDownloadOperation.h"

#define kFileManager [NSFileManager defaultManager]

#define  YJSavedDownloadModelsFilePath [YJCachesDirectory stringByAppendingFormat:@"YJSavedDownloadModels"]

#define  YJSavedDownloadModelsBackup [YJCachesDirectory stringByAppendingFormat:@"YJSavedDownloadModelsBackup"]

// 下载operation最大并发数
#define YJDownloadMaxConcurrentOperationCount  3

@interface YJDownloadManager ()<NSURLSessionDataDelegate>{
    NSMutableArray *_downloadModels;
    NSMutableArray *_completeModels;
    NSMutableArray *_downloadingModels;
    NSMutableArray *_pauseModels;
    BOOL            _enableProgressLog;
}


@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, strong) NSURLSession *backgroundSession;

@end

static UIBackgroundTaskIdentifier bgTask;


@implementation YJDownloadManager


#pragma mark - 单例相关
static id instace = nil;
+ (id)allocWithZone:(struct _NSZone *)zone
{
    if (instace == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instace = [super allocWithZone:zone];
            // 添加未捕获异常的监听
            [instace handleUncaughtExreption];
            // 添加监听
            [instace addObservers];
            // 创建缓存目录
            [instace createCacheDirectory];
        });
    }
    return instace;
}

- (instancetype)init
{
    return instace;
}

+ (instancetype)sharedManager
{
    return [[self alloc] init];
}

- (id)copyWithZone:(struct _NSZone *)zone
{
    return instace;
}

- (id)mutableCopyWithZone:(struct _NSZone *)zone{
    return instace;
}


#pragma mark - 单例初始化调用
/**
 *  添加监听
 */
- (void)addObservers{
    
    [[NSNotificationCenter defaultCenter] addObserver:instace selector:@selector(recoverDownloadModels) name:UIApplicationDidFinishLaunchingNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:instace selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:instace selector:@selector(endBackgroundTask) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:instace selector:@selector(getBackgroundTask) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:instace selector:@selector(applicationWillTerminate) name:kNotificationUncaughtException object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChanged:)
                                                 name:kRealReachabilityChangedNotification
                                               object:nil];
}

//观察者实时检测方法
- (void)networkChanged:(NSNotification *)notification
{
    RealReachability *reachability = (RealReachability *)notification.object;
    ReachabilityStatus status = [reachability currentReachabilityStatus];
    ReachabilityStatus previousStatus = [reachability previousReachabilityStatus];
    NSLog(@"networkChanged, currentStatus:%@, previousStatus:%@", @(status), @(previousStatus));
    
    if (status == RealStatusNotReachable)
    {
        NSLog(@"Network unreachable!");
    }
    
    if (status == RealStatusViaWiFi)
    {
        NSLog(@"Network wifi! Free!");
    }
    
    if (status == RealStatusViaWWAN)
    {
        NSLog(@"Network WWAN! In charge!");
    }
    
    WWANAccessType accessType = [GLobalRealReachability currentWWANtype];
    
    if (status == RealStatusViaWWAN)
    {
        if (accessType == WWANType2G)
        {
            NSLog(@"RealReachabilityStatus2G");
        }
        else if (accessType == WWANType3G)
        {
            NSLog(@"RealReachabilityStatus3G");
        }
        else if (accessType == WWANType4G)
        {
            NSLog(@"RealReachabilityStatus4G");
        }
        else
        {
            NSLog(@"Unknown RealReachability WWAN Status, might be iOS6");
        }
    }
    
    
}

/**
 *  创建缓存目录
 */
- (void)createCacheDirectory{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:YJCachesDirectory]) {
        [fileManager createDirectoryAtPath:YJCachesDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    NSLog(@"创建缓存目录:%@",YJCachesDirectory);
}

/**
 *  添加未捕获异常的监听
 */
- (void)handleUncaughtExreption{
    
    [YJUncaughtExceptionHandler setDefaultHandler];
}

/**
 *  禁止打印进度日志
 */
- (void)enableProgressLog:(BOOL)enable{
    
    _enableProgressLog = enable;
}

#pragma mark - 模型相关
- (void)addDownloadModel:(YJDownloadModel *)model{
    if (![self checkExistWithDownloadModel:model]) {
        [self.downloadModels addObject:model];
        NSLog(@"下载模型添加成功");
    }
}

- (void)addDownloadModels:(NSArray<YJDownloadModel *> *)models{
    if ([models isKindOfClass:[NSArray class]]) {
        [models enumerateObjectsUsingBlock:^(YJDownloadModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addDownloadModel:obj];
        }];
    }
}

-(BOOL)checkExistWithDownloadModel:(YJDownloadModel *)model{
    
    for (YJDownloadModel *tmpModel in self.downloadModels) {
        if ([tmpModel.fileURL isEqualToString:model.fileURL]) {
            NSLog(@"Tip:下载数据模型已存在");
            return YES;
        }
    }
    return NO;
}


- (YJDownloadModel *)downloadModelWithUrl:(NSString *)url{
    if (url == nil || url.length <= 0) return nil;
    for (YJDownloadModel *tmpModel in self.downloadModels) {
        if ([url isEqualToString:tmpModel.fileURL]) {
            return tmpModel;
        }
    }
    
    YJDownloadModel *info = [[YJDownloadModel alloc] init];
    info.fileURL = url; // 设置url
    //    [self.downloadModels addObject:info];
    return info;
}
#pragma mark - 单任务下载控制
- (YJDownloadModel *)download:(NSString *)url {
    return [self download:url state:nil];
}

- (YJDownloadModel *)download:(NSString *)url state:(DownloadStatusChanged)state {
    return [self download:url progress:nil state:state];
}

- (YJDownloadModel *)download:(NSString *)url progress:(DownloadProgressChanged)progress state:(DownloadStatusChanged)state {
    return [self download:url toDestinationPath:nil progress:progress state:state];
}

- (YJDownloadModel *)download:(NSString *)url toDestinationPath:(NSString *)destinationPath progress:(DownloadProgressChanged)progress state:(DownloadStatusChanged)state {
    if (url == nil || url.length <= 0) return nil;
    
    // 下载信息
    YJDownloadModel *info = [self downloadModelWithUrl:url];
    info.progressChanged = progress;
    info.statusChanged = state;
    
    if (destinationPath) {
        info.destinationPath = destinationPath;
    }
    
    [self downloadModel:info];
    
    return info;
}

- (YJDownloadModel *)cancel:(NSString *)url {
    // 下载信息
    YJDownloadModel *info = [self downloadModelWithUrl:url];
    if (info == nil) {
        return nil;
    }
    [self stopWithDownloadModel:info];
    return info;
}

- (YJDownloadModel *)resume:(NSString *)url {
    // 下载信息
    YJDownloadModel *info = [self downloadModelWithUrl:url];
    if (info == nil) {
        return nil;
    }
    [self resumeWithDownloadModel:info];
    return info;
}

- (YJDownloadModel *)suspend:(NSString *)url {
    // 下载信息
    YJDownloadModel *info = [self downloadModelWithUrl:url];
    if (info == nil) {
        return nil;
    }
    [self suspendWithDownloadModel:info];
    return info;
}

- (void)startWithDownloadModel:(YJDownloadModel *)model{
    
    if (model.status == kYJDownloadStatus_Completed) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"该文件已下载，是否重新下载？" preferredStyle:(UIAlertControllerStyleAlert)];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [self downloadModel:model];
        }]];
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if (model.status == kYJDownloadStatus_Failed) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"该文件已下载失败，是否重新下载？" preferredStyle:(UIAlertControllerStyleAlert)];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [self downloadModel:model];
        }]];
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    if (model.status == kYJDownloadStatus_Running ||
        model.status == kYJDownloadStatus_Suspended ||
        model.status == kYJDownloadStatus_Waiting) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"该文件已在下载列表中，是否重新下载？" preferredStyle:(UIAlertControllerStyleAlert)];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [self downloadModel:model];
        }]];
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    [self downloadModel:model];
}

- (void)downloadModel:(YJDownloadModel *)model {
    
    [[NSFileManager defaultManager] removeItemAtPath:model.destinationPath error:nil];
    model.status = kYJDownloadStatus_None;
    
    [self addDownloadModel:model];
    model.operation = [[YJDownloadOperation alloc] initWithDownloadModel:model andSession:self.backgroundSession];
    [self.queue addOperation:model.operation];
    
    [self saveData];
    
    ReachabilityStatus status = [GLobalRealReachability currentReachabilityStatus];
    
    NSLog(@"Initial reachability status:%@",@(status));
    if (status == RealStatusNotReachable)
    {
        NSLog(@"Network unreachable!");
    }
    
    if (status == RealStatusViaWiFi)
    {
        NSLog(@"Network wifi! Free!");
    }
    
    if (status == RealStatusViaWWAN)
    {
        NSLog(@"Network WWAN! In charge!");
    }
    
}

//暂停后操作将销毁 若想继续执行 则需重新创建operation并添加
- (void)suspendWithDownloadModel:(YJDownloadModel *)model{
    
    [self suspendWithDownloadModel:model forAll:NO];
}


- (void)suspendWithDownloadModel:(YJDownloadModel *)model forAll:(BOOL)forAll{
    if (forAll) {//暂停全部
        if (model.status == kYJDownloadStatus_Running) {//下载中 则暂停
            [model.operation suspend];
        }else if (model.status == kYJDownloadStatus_Waiting){//等待中 则取消
            [model.operation cancel];
        }
    }else{
        if (model.status == kYJDownloadStatus_Running) {
            [model.operation suspend];
        }
    }
    model.status = kYJDownloadStatus_Suspended;
    
    model.operation = nil;
}


- (void)resumeWithDownloadModel:(YJDownloadModel *)model{
    
    if (model.status == kYJDownloadStatus_Completed ||
        model.status == kYJDownloadStatus_Running) {
        return;
    }
    //等待中 且操作已在队列中 则无需恢复
    if (model.status == kYJDownloadStatus_Waiting && model.operation) {
        return;
    }
    model.operation = nil;
    model.operation = [[YJDownloadOperation alloc] initWithDownloadModel:model andSession:self.backgroundSession];
    [self.queue addOperation:model.operation];
    
}

- (void)stopWithDownloadModel:(YJDownloadModel *)model{
    
    [self stopWithDownloadModel:model forAll:NO];
}

- (void)stopWithDownloadModel:(YJDownloadModel *)model forAll:(BOOL)forAll{
    
    if (model.status != kYJDownloadStatus_Completed) {
        model.status = kYJDownloadStatus_Cancel;
        [model.operation cancel];
    }
    
    //移除对应的下载文件
    if([kFileManager fileExistsAtPath:model.destinationPath]){
        NSError *error = nil;
        [kFileManager removeItemAtPath:model.destinationPath error:&error];
        if (error) {
            NSLog(@"Tip:下载文件移除失败，%@",error);
        }else{
            NSLog(@"Tip:下载文件移除成功");
        }
    }
    
    //释放operation
    model.operation = nil;
    
    //单个删除 则直接从数组中移除下载模型 否则等清空文件后统一移除
    if(!forAll){
        [self.downloadModels removeObject:model];
        [self saveData];
    }
}


#pragma mark - 批量下载相关
/**
 *  批量下载操作
 */
- (void)startWithDownloadModels:(NSArray<YJDownloadModel *> *)downloadModels{
    NSLog(@">>>%@前 operationCount = %zd", NSStringFromSelector(_cmd),self.queue.operationCount);
    [self.queue setSuspended:NO];
    [self addDownloadModels:downloadModels];
    [self operateTasksWithOperationType:kYJOperationType_startAll];
    NSLog(@"<<<%@后 operationCount = %zd",NSStringFromSelector(_cmd),self.queue.operationCount);
    
    [self saveData];
}

/**
 *  暂停所有下载任务
 */
- (void)suspendAll{
    
    [self.queue setSuspended:YES];
    [self operateTasksWithOperationType:kYJOperationType_suspendAll];
}

/**
 *  恢复下载任务（进行中、已完成、等待中除外）
 */
- (void)resumeAll{
    
    [self.queue setSuspended:NO];
    [self operateTasksWithOperationType:kYJOperationType_resumeAll];
}

/**
 *  停止并删除下载任务
 */
- (void)stopAll{
    //销毁前暂停队列 防止等待中的任务执行
    [self.queue setSuspended:YES];
    [self.queue cancelAllOperations];
    [self operateTasksWithOperationType:kYJOperationType_stopAll];
    [self.queue setSuspended:NO];
    [self.downloadModels removeAllObjects];
    [self removeAllFiles];
}


- (void)operateTasksWithOperationType:(YJOperationType)operationType{
    
    [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        YJDownloadModel *downloadModel = obj;
        switch (operationType) {
            case kYJOperationType_startAll:
                [self startWithDownloadModel:downloadModel];
                break;
            case kYJOperationType_suspendAll:
                [self suspendWithDownloadModel:downloadModel forAll:YES];
                break;
            case kYJOperationType_resumeAll:
                [self resumeWithDownloadModel:downloadModel];
                break;
            case kYJOperationType_stopAll:
                [self stopWithDownloadModel:downloadModel forAll:YES];
                break;
            default:
                break;
        }
    }];
}


/**
 *  从备份恢复下载数据
 */
- (void)recoverDownloadModels{
    /// 回到程序前台自动开始下载
    //    [kYJDownloadManager startWithDownloadModels:self.downloadModels];
    [self resumeAll];
    //    if ([kFileManager fileExistsAtPath:YJSavedDownloadModelsBackup]) {
    //        NSError * error = nil;
    //        [kFileManager removeItemAtPath:YJSavedDownloadModelsFilePath error:nil];
    //        BOOL recoverSuccess = [kFileManager copyItemAtPath:YJSavedDownloadModelsBackup toPath:YJSavedDownloadModelsFilePath error:&error];
    //        if (recoverSuccess) {
    //            NSLog(@"Tip:数据恢复成功");
    //
    //            [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
    //                YJDownloadModel *model = (YJDownloadModel *)obj;
    //                if (model.status == kYJDownloadStatus_Running ||
    //                    model.status == kYJDownloadStatus_Waiting){
    //                    [self startWithDownloadModel:model];
    //                }
    //            }];
    //        }else{
    //            NSLog(@"Tip:数据恢复失败，%@",error);
    //        }
    //    }
}

#pragma mark - 文件相关
/**
 *  保存下载模型
 */
- (void)saveData{
    
    [kFileManager removeItemAtPath:YJSavedDownloadModelsFilePath error:nil];
    BOOL flag = [NSKeyedArchiver archiveRootObject:self.downloadModels toFile:YJSavedDownloadModelsFilePath];
    NSLog(@"Tip:下载数据保存路径%@",YJSavedDownloadModelsFilePath);
    NSLog(@"Tip:下载数据保存-%@",flag?@"成功!":@"失败");
    
    if (flag) {
        [self backupFile];
    }
}
/**
 *  备份下载模型
 */
- (void)backupFile{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSError *error = nil;
        [self removeBackupFile];
        BOOL exist = [kFileManager fileExistsAtPath:YJSavedDownloadModelsFilePath];
        if (exist) {
            BOOL backupSuccess = [kFileManager copyItemAtPath:YJSavedDownloadModelsFilePath toPath:YJSavedDownloadModelsBackup error:&error];
            if (backupSuccess) {
                NSLog(@"Tip:数据备份成功");
            }else{
                NSLog(@"Tip:数据备份失败，%@",error);
                [self backupFile];
            }
        }
    });
}
/**
 *  移除备份
 */
- (void)removeBackupFile{
    if ([kFileManager fileExistsAtPath:YJSavedDownloadModelsBackup]) {
        NSError * error = nil;
        BOOL success = [kFileManager removeItemAtPath:YJSavedDownloadModelsBackup error:&error];
        if (success) {
            NSLog(@"Tip:备份移除成功");
        }else{
            NSLog(@"Tip:备份移除失败，%@",error);
        }
    }
}

/**
 *  移除目录中所有文件
 */
- (void)removeAllFiles{
    
    //返回路径中的文件数组
    NSArray * files = [[NSFileManager defaultManager] subpathsAtPath:YJCachesDirectory];
    
    for(NSString *p in files){
        NSError*error;
        
        NSString*path = [YJCachesDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@",p]];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:path]){
            BOOL isRemove = [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
            if(isRemove) {
                NSLog(@"文件：%@-->清除成功",p);
            }else{
                NSLog(@"文件：%@-->清除失败",p);
            }
        }
    }
}

#pragma mark - Private Method

#pragma mark - Getters/Setters
- (NSMutableArray *)downloadModels{
    
    if (!_downloadModels) {
        //查看本地是否有数据
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL exist = [fileManager fileExistsAtPath:YJSavedDownloadModelsFilePath isDirectory:nil];
        
        if (exist) {//有 则读取本地数据
            _downloadModels = [NSKeyedUnarchiver  unarchiveObjectWithFile:YJSavedDownloadModelsFilePath];
            
            for (YJDownloadModel *model in _downloadModels) {
                if (model.fileDownloadSize <= 0 || model.fileTotalSize <= 0) {
                    model.status = kYJDownloadStatus_Waiting;
                }
                
                if (model.fileTotalSize > 0) {
                    if (model.fileTotalSize == model.fileDownloadSize) {
                        model.status = kYJDownloadStatus_Completed;
                    } else {
                        model.status = kYJDownloadStatus_Suspended;
                    }
                }
            }
        }else{
            _downloadModels = [NSMutableArray array];
        }
    }
    return _downloadModels;
}

- (NSMutableArray *)completeModels{
    __block  NSMutableArray *tmpArr = [NSMutableArray array];
    if (self.downloadModels) {
        [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YJDownloadModel *model = obj;
            if (model.status == kYJDownloadStatus_Completed) {
                [tmpArr addObject:model];
            }
        }];
    }
    
    _completeModels = tmpArr;
    return _completeModels;
}


- (NSMutableArray *)downloadingModels{
    __block  NSMutableArray *tmpArr = [NSMutableArray array];
    if (self.downloadModels) {
        [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YJDownloadModel *model = obj;
            if (model.status == kYJDownloadStatus_Running) {
                [tmpArr addObject:model];
            }
        }];
    }
    
    _downloadingModels = tmpArr;
    return _downloadingModels;
}


- (NSMutableArray *)waitModels{
    __block  NSMutableArray *tmpArr = [NSMutableArray array];
    if (self.downloadModels) {
        [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YJDownloadModel *model = obj;
            if (model.status == kYJDownloadStatus_Waiting) {
                [tmpArr addObject:model];
            }
        }];
    }
    return tmpArr;
}

- (NSMutableArray *)pauseModels{
    __block  NSMutableArray *tmpArr = [NSMutableArray array];
    if (self.downloadModels) {
        [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YJDownloadModel *model = obj;
            if (model.status == kYJDownloadStatus_Suspended) {
                [tmpArr addObject:model];
            }
        }];
    }
    _pauseModels = tmpArr;
    return _pauseModels;
}



- (NSOperationQueue *)queue{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
        [_queue setMaxConcurrentOperationCount:YJDownloadMaxConcurrentOperationCount];
    }
    return _queue;
}


- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount{
    _maxConcurrentOperationCount = maxConcurrentOperationCount;
    self.queue.maxConcurrentOperationCount = _maxConcurrentOperationCount;
}


- (NSURLSession *)backgroundSession{
    if (!_backgroundSession) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
        //不能传self.queue
        _backgroundSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    
    return _backgroundSession;
}


- (BOOL)enableProgressLog{
    
    return _enableProgressLog;
}

- (void)startNotifier {
    [GLobalRealReachability startNotifier];
    GLobalRealReachability.hostForPing = @"www.apple.com";
    GLobalRealReachability.hostForCheck = @"www.baidu.com";
}

#pragma mark - 后台任务相关
/**
 *  获取后台任务
 */
- (void)getBackgroundTask{
    
    NSLog(@"getBackgroundTask");
    UIBackgroundTaskIdentifier tempTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        
    }];
    
    if (bgTask != UIBackgroundTaskInvalid) {
        
        [self endBackgroundTask];
    }
    
    bgTask = tempTask;
    
    [self performSelector:@selector(getBackgroundTask) withObject:nil afterDelay:120];
}


/**
 *  结束后台任务
 */
- (void)endBackgroundTask{
    
    [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
}



#pragma mark - Event Response
/**
 *  应用强关或闪退时 保存下载数据
 */
- (void)applicationWillTerminate{
    
    //    [self saveData];
}


#pragma mark - NSURLSessionDataDelegate
/**
 * 接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    YJDownloadModel *downloadModel = dataTask.downloadModel;
    
    // 打开流
    [downloadModel.stream open];
    
    // 获得服务器这次请求 返回数据的总长度
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + downloadModel.fileDownloadSize;
    downloadModel.fileTotalSize = totalLength;
    
    [self saveData];
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/**
 * 接收到服务器返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    
    NSLog(@"还在执行！");
    if (!dataTask.downloadModel) {
        return;
    }
    
    YJDownloadModel *downloadModel = dataTask.downloadModel;
    
    // 写入数据
    [downloadModel.stream write:data.bytes maxLength:data.length];
    //     只为触发set方法引起进度改变
    downloadModel.fileDownloadSize = 0;
}

/**
 * 请求完毕 下载成功 | 失败
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    YJDownloadModel *downloadModel = task.downloadModel;
    [downloadModel.stream close];
    downloadModel.stream = nil;
    task = nil;
    
    if (downloadModel.status == kYJDownloadStatus_Suspended) {
    } else if (downloadModel.status == kYJDownloadStatus_Cancel){
    } else {
        if (error) {
            downloadModel.status = kYJDownloadStatus_Failed;
            downloadModel.error = error;
        } else {
            downloadModel.status = kYJDownloadStatus_Completed;
            downloadModel.error = nil;
        }
    }
    
    [self saveData];
}
@end
