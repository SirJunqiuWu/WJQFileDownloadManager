//
//  WJQTask.h
//  WJQFileDownloadManager
//
//  Created by 吴 吴 on 2017/3/30.
//  Copyright © 2017年 JackWu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,TaskState ) {
    //将要下载
    WillDownload = 0,
    //等待下载
    WaitingDownload,
    //正在下载
    Downloading,
    //暂停下载
    Suspended,
    //下载完成
    Complete,
    //下载失败
    Failed,
};

@interface WJQTask : NSObject

/**
 任务链接
 */
@property(nonatomic,strong,readonly)NSURL *taskURL;

/**
 任务下载状态
 */
@property(nonatomic,assign,readonly)TaskState taskState;

/**
 任务文件名
 */
@property(nonatomic,strong,readonly)NSString *taskFileName;

/**
 任务文件类型 eg:dmg,img
 */
@property(nonatomic,strong,readonly)NSString *taskFileType;

/**
 任务文件路径
 */
@property(nonatomic,strong,readonly)NSString *taskFilePath;


/**
 当前文件写入了多少字节
 */
@property(nonatomic,assign,readonly)NSUInteger bytesWritten;

/**
 当前文件总共下载了多少字节
 */
@property(nonatomic,assign,readonly)NSUInteger totalBytesWritten;

/**
 当前文件总计多少字节需要下载
 */
@property(nonatomic,assign,readonly)NSUInteger totalBytesExpectedToWrite;

/**
 任务下载速度
 */
@property(nonatomic,strong,readonly)NSString *taskDownloadSpeed;

/**
 添加为任务时的时间，便于后序在下载队列中进行优先排序
 */
@property(nonatomic,strong,readonly)NSString *taskAddTime;

/**
 任务下载结果描述
 */
@property(nonatomic,strong,readonly)NSError *taskError;


/**
 重写初始化方法:根据任务下载路径初始化任务对象

 @param url 下载任务的链接
 @return 某个任务对象
 */
- (instancetype)initWithURL:(NSURL *)url;

@end
