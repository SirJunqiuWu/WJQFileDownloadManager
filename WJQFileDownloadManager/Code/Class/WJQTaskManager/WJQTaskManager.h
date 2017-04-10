//
//  WJQTaskManager.h
//  WJQFileDownloadManager
//
//  Created by 吴 吴 on 2017/3/30.
//  Copyright © 2017年 JackWu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WJQTask.h"

@protocol WJQTaskManagerDelegate;

//NSCopying是一个与对象拷贝有关的协议
@interface WJQTaskManager : NSObject<NSCopying>

@property(nonatomic,assign)id<WJQTaskManagerDelegate>delegate;
/**
 任务下载的最大并发数（外部控制）
 */
@property(nonatomic,assign)NSInteger downloadMaxCount;

/**
 下载目录
 */
@property(nonatomic,strong) NSString *downloadPath;

#pragma mark - 数组部分

/**
 正在执行的任务所在数组:将要下载，等待下载，正在下载
 */
@property(nonatomic,strong,readonly)NSMutableArray<WJQTask *>*downloadingTaskArr;

/**
 下载完成的任务所在数组
 */
@property(nonatomic,strong,readonly)NSMutableArray<WJQTask *>*finishedTaskArr;

/**
 下载失败的任务所在数组
 */
@property(nonatomic,strong,readonly)NSMutableArray<WJQTask *>*failedTaskArr;



/**
 单例方法

 @return WJQTaskManager
 */
+ (instancetype)sharedManager;


/**
 判断任务是否已经下载成功

 @param task 当前目标任务
 @return YES，任务已经下载成功;反之没有
 */
- (BOOL)taskIsLoaded:(WJQTask *)task;


/**
 添加下载任务

 @param task 当前操作的任务
 */
- (void)addTaskWithTargetTask:(WJQTask *)task;


/**
 删除当前编辑的任务

 @param task 当前操作的任务
 */
- (void)deleteTaskWithTargetTask:(WJQTask *)task;


/**
 开始所有
 */
- (void)startAll;


/**
 取消所有
 */
- (void)cancelAll;


/**
 暂停某个指定任务

 @param task 目标任务对象
 */
- (void)suspendTaskWithTargetTask:(WJQTask *)task;


/**
 开始某个指定任务

 @param task 目标任务对象
 */
- (void)resumeTaskWithTargetTask:(WJQTask *)task;

@end

@protocol WJQTaskManagerDelegate <NSObject>

@optional

//任务将要被添加
- (void)taskWillAdd:(WJQTask *)task Error:(NSError *)error;

//任务正在被添加
- (void)taskDidAdd:(WJQTask *)task;

//任务开始下载
- (void)taskDidStart:(WJQTask *)task;

//开始全部
- (void)allTaskDidStart;

//任务被暂停
- (void)taskDidSuspend:(WJQTask *)task;

//任务执行结束
- (void)taskDidEnd:(WJQTask *)task;

//删除指定任务
- (void)taskDidDelete:(WJQTask *)task Error:(NSError *)error;

//更新下载进度
- (void)updateProgress:(WJQTask *)task;

@end
