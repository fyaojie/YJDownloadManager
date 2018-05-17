//
//  HJDownloadHomeCell.m
//  HJDownloadManager
//
//  Created by WHJ on 2018/2/27.
//  Copyright © 2018年 WHJ. All rights reserved.
//

#import "HJDownloadHomeCell.h"
#import "HJExampleModel.h"
#import "YJDownloadModel.h"
#import "YJDownloadManager.h"

static const CGFloat kHomeCellHeight = 53.f;

@interface HJDownloadHomeCell ()

@property (nonatomic, strong) YJDownloadModel *downloadModel;

@end

@implementation HJDownloadHomeCell

#pragma mark - Life Circle

#pragma mark - About UI

- (void)refreshUIWithDownloadModel:(YJDownloadModel *)downloadModel{
    
    YJDownloadStatus downloadStatus = downloadModel.status;
    CGFloat progress = downloadModel.progress;
    NSInteger progressInt = (NSInteger)(progress * 100);
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.progressView setProgress:progress];
        [self.downloadBtn setTitle:nil forState:UIControlStateNormal];
        
        if(downloadStatus == kYJDownloadStatus_None){
            [self.downloadBtn setImage:[UIImage imageNamed:@"HJ_download_ready"] forState:UIControlStateNormal];
        }else if(downloadStatus == kYJDownloadStatus_Running){
            [self.downloadBtn setImage:nil forState:UIControlStateNormal];
            NSString *title = [NSString stringWithFormat:@"%zd%%",progressInt];
            [self.downloadBtn setTitle:title forState:UIControlStateNormal];
        }else if(downloadStatus == kYJDownloadStatus_Suspended){
            [self.downloadBtn setImage:[UIImage imageNamed:@"HJ_download_pause"] forState:UIControlStateNormal];
        }else if(downloadStatus == kYJDownloadStatus_Completed){
            [self.downloadBtn setImage:[UIImage imageNamed:@"HJ_download_finished"] forState:UIControlStateNormal];
        }else if(downloadStatus == kYJDownloadStatus_Failed){
            [self.downloadBtn setImage:[UIImage imageNamed:@"HJ_download_fail"] forState:UIControlStateNormal];
        }else if(downloadStatus == kYJDownloadStatus_Waiting){
            [self.downloadBtn setImage:[UIImage imageNamed:@"HJ_download_waiting"] forState:UIControlStateNormal];
        }else{
            
        }
    });
}

- (void)layoutSubviews{
    
    self.titleLabel.frame = CGRectMake(10, 10, 200, 20);
    self.downloadBtn.frame = CGRectMake(CGRectGetWidth(self.bounds) - kHomeCellHeight - 10, 0, kHomeCellHeight, kHomeCellHeight);
    self.downloadBtn.center = CGPointMake(self.downloadBtn.center.x, self.contentView.center.y);
    self.progressView.frame = CGRectMake(0, 50, CGRectGetWidth(self.bounds), 3.f);
    
}
#pragma mark - Pravite Method
- (YJDownloadModel *)downloadModel{
    
    if(!_downloadModel){
        _downloadModel = [kYJDownloadManager downloadModelWithUrl:self.model.url];
        
        if(!_downloadModel && _model){
            _downloadModel = [[YJDownloadModel alloc] init];
            _downloadModel.fileURL = self.model.url;
            _downloadModel.downloadDesc = self.model.name;
        }
        __weak typeof(self) weakSelf = self;
        _downloadModel.statusChanged = ^(YJDownloadModel *downloadModel) {
            [weakSelf refreshUIWithDownloadModel:downloadModel];
        };
        
        _downloadModel.progressChanged = ^(YJDownloadModel *downloadModel) {
            [weakSelf refreshUIWithDownloadModel:downloadModel];
        };
    }
    return _downloadModel;
}

#pragma mark - Public Method
+ (CGFloat)backCellHeight{
    
    return kHomeCellHeight;
}
#pragma mark - Event response
- (void)downloadAction:(UIButton *)sender{
    
    YJDownloadStatus downloadStatus = self.downloadModel.status;
        __weak typeof(self) weakSelf = self;
    if(downloadStatus == kYJDownloadStatus_None){
        self.downloadModel = nil;
        self.downloadModel = [kYJDownloadManager download:self.model.url];
        _downloadModel.statusChanged = ^(YJDownloadModel *downloadModel) {
            [weakSelf refreshUIWithDownloadModel:downloadModel];
        };
        
        _downloadModel.progressChanged = ^(YJDownloadModel *downloadModel) {
            [weakSelf refreshUIWithDownloadModel:downloadModel];
        };
//        [kYJDownloadManager startWithDownloadModel:self.downloadModel];
    
    }else if(downloadStatus == kYJDownloadStatus_Running){
        
        [kYJDownloadManager suspendWithDownloadModel:self.downloadModel];
        
    }else if(downloadStatus == kYJDownloadStatus_Suspended){
        
        [kYJDownloadManager resumeWithDownloadModel:self.downloadModel];
        
    }else if(downloadStatus == kYJDownloadStatus_Completed){
    
        [kYJDownloadManager startWithDownloadModel:self.downloadModel];
    }else if(downloadStatus == kYJDownloadStatus_Failed){
    
        [kYJDownloadManager resumeWithDownloadModel:self.downloadModel];
        
    }else if(downloadStatus == kYJDownloadStatus_Waiting){
      [kYJDownloadManager startWithDownloadModel:self.downloadModel];
    }else if(downloadStatus == kYJDownloadStatus_Cancel){
        
        [kYJDownloadManager resumeWithDownloadModel:self.downloadModel];
    }
    
}
#pragma mark - Delegate methods

#pragma mark - Getters/Setters/Lazy
- (void)setModel:(HJExampleModel *)model{
    _model = model;
    
    self.titleLabel.text = model.name;
    
    self.downloadModel = nil;
    
    [self refreshUIWithDownloadModel:[self downloadModel]];
}

@end
