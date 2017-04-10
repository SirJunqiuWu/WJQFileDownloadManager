//
//  TaskLoadingCell.m
//  WJQFileDownloadManager
//
//  Created by 吴 吴 on 2017/3/31.
//  Copyright © 2017年 JackWu. All rights reserved.
//

#import "TaskLoadingCell.h"

@interface TaskLoadingCell()
{
    UILabel *nameLabel;
    UIProgressView *progressView;
    UILabel *progressLabel;
    UILabel *speedLabel;
    UIButton *downloadButton;
}

@end

@implementation TaskLoadingCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - 创建UI

- (void)setupUI {
    nameLabel = [[UILabel alloc]init];
    nameLabel.textAlignment = NSTextAlignmentLeft;
    nameLabel.backgroundColor = [UIColor clearColor];
    nameLabel.font = [UIFont systemFontOfSize:13];
    [self.contentView addSubview:nameLabel];
    
    progressView = [[UIProgressView alloc]init];
    progressView.tintColor = [UIColor colorWithRed:245.0/255.0 green:76.0/255.0 blue:72.0/255.0 alpha:1];
    [self.contentView addSubview:progressView];
    
    progressLabel = [[UILabel alloc]init];
    progressLabel.backgroundColor = [UIColor clearColor];
    progressLabel.font = [UIFont systemFontOfSize:12];
    progressLabel.text = @"0.0";
    [self.contentView addSubview:progressLabel];
    
    speedLabel = [[UILabel alloc]init];
    speedLabel.backgroundColor = [UIColor clearColor];
    speedLabel.font = [UIFont systemFontOfSize:12];
    speedLabel.text = @"";
    speedLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:speedLabel];
    
    downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    downloadButton.backgroundColor = [UIColor clearColor];
    [downloadButton setImage:[UIImage imageNamed:@"stopDownload"] forState:UIControlStateNormal];
    [downloadButton setImage:[UIImage imageNamed:@"startDownload"] forState:UIControlStateSelected];
    [downloadButton addTarget:self action:@selector(downloadBtnPressed) forControlEvents:UIControlEventTouchUpInside];
    downloadButton.selected = NO;
    [self.contentView addSubview:downloadButton];
    
    UIView *gapline = [[UIView alloc]init];
    gapline.backgroundColor = [UIColor grayColor];
    [self.contentView addSubview:gapline];
    
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).with.offset(8);
        make.left.equalTo(self.contentView.mas_left).with.offset(10);
        make.right.equalTo(self.contentView.mas_right).with.offset(-50);
        make.height.equalTo(self.contentView.mas_height).with.multipliedBy(0.3);
    }];
    
    [progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nameLabel.mas_bottom).with.offset(5);
        make.left.equalTo(nameLabel.mas_left);
        make.right.equalTo(nameLabel.mas_right);
        make.height.equalTo(@2);
    }];
    
    [progressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(progressView.mas_bottom).with.offset(5);
        make.left.equalTo(progressView.mas_left);
        make.right.equalTo(progressView.mas_right).offset(-100);
        make.bottom.equalTo(self.contentView.mas_bottom).with.offset(-5);
    }];
    
    [speedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(progressLabel.mas_top);
        make.left.equalTo(progressLabel.mas_right);
        make.width.equalTo(@100);
        make.height.equalTo(progressLabel.mas_height);
    }];
    
    [downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView.mas_right).offset(-10);
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.width.equalTo(@32);
        make.height.equalTo(@32);
    }];
    
    [gapline mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left);
        make.width.equalTo(self.contentView.mas_width);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-1);
        make.height.equalTo(@1);
    }];
}

#pragma mark - Setter

- (void)setTask:(WJQTask *)task {
    _task = task;
    nameLabel.text = _task.taskFileName;
    
    //进度
    float progress = ((float)_task.totalBytesWritten/(float)(_task.totalBytesExpectedToWrite));
    if (progress>0)
    {
        progressView.progress = progress;
    }
    else
    {
        progressView.progress = 0;
    }
    
    //下载速度
    if (_task.totalBytesWritten > 0)
    {
        NSString *progressStr = [NSString stringWithFormat:@"(%.2f%@)",progress*100,@"%"];
        NSString *sizeStr = [NSString stringWithFormat:@"%.2fM/%.2fM",_task.totalBytesWritten/1024.0/1024.0,_task.totalBytesExpectedToWrite/1024.0/1024.0];
        progressLabel.text = [NSString stringWithFormat:@"%@ %@",sizeStr,progressStr];
    }
    else
    {
        progressLabel.text = @"";
    }
    if (task.taskState == WaitingDownload) {
        speedLabel.text = @"等待";
        downloadButton.selected = YES;
    }
    else if (_task.taskState == Suspended)
    {
        speedLabel.text = @"暂停";
        downloadButton.selected = YES;
    }
    else
    {
        speedLabel.text = task.taskDownloadSpeed;
        downloadButton.selected = NO;
    }
}

#pragma mark - 按钮点击事件

- (void)downloadBtnPressed {
    downloadButton.selected = !downloadButton.selected;
    if (downloadButton.selected)
    {
        //暂停下载
        [[WJQTaskManager sharedManager]suspendTaskWithTargetTask:_task];
    }
    else
    {
        //继续下载
        [[WJQTaskManager sharedManager]resumeTaskWithTargetTask:_task];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
