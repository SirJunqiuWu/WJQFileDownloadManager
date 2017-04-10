//
//  TaskListCell.h
//  WJQFileDownloadManager
//
//  Created by 吴 吴 on 2017/3/29.
//  Copyright © 2017年 JackWu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TaskListCell : UITableViewCell


/**
 任务对象
 */
@property(nonatomic,strong)WJQTask *task;

/**
 下载按钮点击回调
 */
@property(nonatomic,copy)void(^downloadBlock)();

@end

