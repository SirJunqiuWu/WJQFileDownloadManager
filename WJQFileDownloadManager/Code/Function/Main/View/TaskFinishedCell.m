//
//  TaskFinishedCell.m
//  WJQFileDownloadManager
//
//  Created by 吴 吴 on 2017/3/31.
//  Copyright © 2017年 JackWu. All rights reserved.
//

#import "TaskFinishedCell.h"

@implementation TaskFinishedCell
{
    UIImageView *icon;
    UILabel     *nameLbl;
    UILabel     *sizeLbl;
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
    icon = [[UIImageView alloc]init];
    icon.image = [UIImage imageNamed:@"file"];
    [self.contentView addSubview:icon];
    
    nameLbl = [[UILabel alloc]init];
    nameLbl.backgroundColor = [UIColor clearColor];
    nameLbl.font = [UIFont systemFontOfSize:13];
    [self.contentView addSubview:nameLbl];
    
    sizeLbl = [[UILabel alloc]init];
    sizeLbl.backgroundColor = [UIColor clearColor];
    sizeLbl.font = [UIFont systemFontOfSize:14];
    sizeLbl.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:sizeLbl];
    
    UIView *gapline = [[UIView alloc]init];
    gapline.backgroundColor = [UIColor grayColor];
    [self.contentView addSubview:gapline];
    
    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).offset(17.5);
        make.left.equalTo(self.contentView.mas_left).offset(10.0);
        make.width.equalTo(@31);
        make.height.equalTo(@35);
    }];
    
    [nameLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(icon.mas_left).offset(10);
        make.right.equalTo(self.contentView.mas_right).offset(-17);
        make.centerY.equalTo(icon.mas_centerY);
        make.height.equalTo(@25);
    }];
    
    [sizeLbl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(nameLbl.mas_bottom);
        make.left.equalTo(nameLbl.mas_left);
        make.right.equalTo(nameLbl.mas_right);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-8);
    }];
    
    [gapline mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView.mas_left);
        make.width.equalTo(self.contentView.mas_width);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-1);
        make.height.equalTo(@1);
    }];
}

#pragma mark - Setter

- (void)setTask:(WJQTask *)task{
    _task = task;
    nameLbl.text = task.taskFileName;
    sizeLbl.text = [NSString stringWithFormat:@"%.2f M",task.totalBytesExpectedToWrite/1024.0/1024.0];
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
