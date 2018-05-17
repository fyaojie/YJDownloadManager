//
//  HJDownloadListCell.m
//  HJDownloadManager
//
//  Created by WHJ on 2018/2/28.
//  Copyright © 2018年 WHJ. All rights reserved.
//

#import "HJDownloadListCell.h"
#import "YJDownloadModel.h"
#import "YJDownloadManager.h"

static const CGFloat kListCellHeight = 58.f;

@interface HJDownloadListCell ()

@end

@implementation HJDownloadListCell

#pragma mark - Life Circle

#pragma mark - About UI

- (void)refreshUIWithDownloadModel:(YJDownloadModel *)downloadModel{
    
    YJDownloadStatus downloadStatus = downloadModel.status;
    CGFloat progress = downloadModel.progress;
    NSInteger progressInt = (NSInteger)(progress * 100);
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.progressView setProgress:progress];
        [self.downloadBtn setTitle:nil forState:UIControlStateNormal];
        //设置文件下载大小
        CGFloat downloadSize = downloadModel.fileDownloadSize/1024/1024.f;
        CGFloat totalSize = downloadModel.fileTotalSize/1024/1024.f;
        NSString *fileSizeText = [NSString stringWithFormat:@"已下载:%.2fM/总大小:%.2fM",downloadSize,totalSize];
        self.fileSizeLabel.text = fileSizeText;
        
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
    
    [super layoutSubviews];
    
    self.titleLabel.frame = CGRectMake(10, 10, 200, 20);
    
    self.fileFormatLabel.frame = CGRectMake(CGRectGetMaxX(self.titleLabel.frame)+20, 10, 100, 20);
    
    self.fileSizeLabel.frame = CGRectMake(10, CGRectGetMaxY(self.titleLabel.frame)+5, 200, 20);
    
    self.downloadBtn.frame = CGRectMake(CGRectGetWidth(self.bounds) - kListCellHeight - 10, 0, kListCellHeight, kListCellHeight);
    self.downloadBtn.center = CGPointMake(self.downloadBtn.center.x, self.contentView.center.y);
    
    self.progressView.frame = CGRectMake(0, 55, CGRectGetWidth(self.bounds), 3.f);
}
#pragma mark - Pravite Method
- (void)setDownloadModel:(YJDownloadModel *)downloadModel{
    
    _downloadModel = downloadModel;
    
    self.titleLabel.text = downloadModel.downloadDesc;
    
    __weak typeof(self) weakSelf = self;
    _downloadModel.statusChanged = ^(YJDownloadModel *downloadModel) {
        [weakSelf refreshUIWithDownloadModel:downloadModel];
    };

    _downloadModel.progressChanged = ^(YJDownloadModel *downloadModel) {
        [weakSelf refreshUIWithDownloadModel:downloadModel];
    };
    
    [self refreshUIWithDownloadModel:self.downloadModel];
    //文件格式
    self.fileFormatLabel.text = [NSString stringWithFormat:@"文件格式:%@", self.downloadModel.fileType];
    
    [self setNeedsLayout];
}

#pragma mark - Public Method
+ (CGFloat)backCellHeight{
    
    return kListCellHeight;
}
#pragma mark - Event response
- (void)downloadAction:(UIButton *)sender{
    
    YJDownloadStatus downloadStatus = self.downloadModel.status;
    
    if(downloadStatus == kYJDownloadStatus_None){
        
        [kYJDownloadManager startWithDownloadModel:self.downloadModel];
        
    }else if(downloadStatus == kYJDownloadStatus_Running){
        
        [kYJDownloadManager suspendWithDownloadModel:self.downloadModel];
        
    }else if(downloadStatus == kYJDownloadStatus_Suspended){
        
        [kYJDownloadManager resumeWithDownloadModel:self.downloadModel];
        
    }else if(downloadStatus == kYJDownloadStatus_Completed){
        
        
    }else if(downloadStatus == kYJDownloadStatus_Failed){
        
        [kYJDownloadManager startWithDownloadModel:self.downloadModel];
        
    }else if(downloadStatus == kYJDownloadStatus_Waiting){
        
    }else if(downloadStatus == kYJDownloadStatus_Cancel){
        
        [kYJDownloadManager startWithDownloadModel:self.downloadModel];
    }
    
}
#pragma mark - Delegate methods

#pragma mark - Getters/Setters/Lazy


@end
