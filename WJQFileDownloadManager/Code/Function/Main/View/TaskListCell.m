//
//  TaskListCell.m
//  WJQFileDownloadManager
//
//  Created by 吴 吴 on 2017/3/29.
//  Copyright © 2017年 JackWu. All rights reserved.
//

#import "TaskListCell.h"

@interface TaskListCell()
{
    UILabel *titleLbl;
    UIButton*addBtn;
}

@end

@implementation TaskListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - 创建UI

- (void)setupUI {
    titleLbl = [[UILabel alloc]init];
    titleLbl.textAlignment = NSTextAlignmentLeft;
    titleLbl.font = [UIFont systemFontOfSize:18];
    titleLbl.textColor = [UIColor darkTextColor];
    [self.contentView addSubview:titleLbl];
    
    addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    addBtn.backgroundColor = [UIColor clearColor];
    [addBtn setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
    [addBtn setImage:[UIImage imageNamed:@"download"] forState:UIControlStateHighlighted];
    [addBtn addTarget:self action:@selector(addBtnPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:addBtn];
    
    UIView *gapline = [[UIView alloc]init];
    gapline.backgroundColor = [UIColor grayColor];
    [self.contentView addSubview:gapline];
    
    [titleLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).offset(15);
        make.left.equalTo(self.contentView.mas_left).offset(10);
        make.right.equalTo(self.contentView.mas_right).offset(-80);
        make.height.equalTo(@20);
    }];
    
    [addBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.right.equalTo(self.contentView.mas_right).offset(-20);
        make.width.equalTo(@25.5);
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
    titleLbl.text = _task.taskFileName;
}

#pragma mark - 按钮点击事件

- (void)addBtnPressed {
    NSLog(@"添加任务到下载，%@",_task);
    [[WJQTaskManager sharedManager]addTaskWithTargetTask:_task];
    if (_downloadBlock)
    {
        _downloadBlock();
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
