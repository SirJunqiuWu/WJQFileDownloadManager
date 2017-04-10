//
//  TaskFailedCell.m
//  WJQFileDownloadManager
//
//  Created by 吴 吴 on 2017/3/31.
//  Copyright © 2017年 JackWu. All rights reserved.
//

#import "TaskFailedCell.h"

@implementation TaskFailedCell
{
    UILabel *nameLbl;
    UILabel *desLbl;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
    }
    return self;
}

#pragma mark - 创建UI

- (void)setupUI {
    nameLbl = [[UILabel alloc]init];
    nameLbl.backgroundColor = [UIColor clearColor];
    nameLbl.font = [UIFont systemFontOfSize:13];
    [self.contentView addSubview:nameLbl];
    
    desLbl = [[UILabel alloc]init];
    desLbl.backgroundColor = [UIColor clearColor];
    desLbl.font = [UIFont systemFontOfSize:12];
    desLbl.text = @"下载失败";
    [self.contentView addSubview:desLbl];
    
    UIView *gapline = [[UIView alloc]init];
    gapline.backgroundColor = [UIColor grayColor];
    [self.contentView addSubview:gapline];
    
    [nameLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).with.offset(8);
        make.left.equalTo(self.contentView.mas_left).with.offset(10);
        make.right.equalTo(self.contentView.mas_right).with.offset(-50);
        make.height.equalTo(self.contentView.mas_height).with.multipliedBy(0.3);
    }];
    
    [desLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nameLbl.mas_bottom).offset(5);
        make.left.equalTo(nameLbl.mas_left);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-8);
        make.right.equalTo(nameLbl.mas_right);
    }];
    
    [gapline mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left);
        make.width.equalTo(self.contentView.mas_width);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-1);
        make.height.equalTo(@1);
    }];
}

#pragma mark - Setter

-(void)setTask:(WJQTask *)task{
    _task = task;
    nameLbl.text = _task.taskFileName;
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
