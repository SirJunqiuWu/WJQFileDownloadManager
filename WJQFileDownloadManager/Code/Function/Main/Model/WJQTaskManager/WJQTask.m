//
//  WJQTask.m
//  WJQFileDownloadManager
//
//  Created by 吴 吴 on 2017/3/30.
//  Copyright © 2017年 JackWu. All rights reserved.
//

#import "WJQTask.h"
#import <CommonCrypto/CommonDigest.h>

@interface WJQTask ()
{
    //记录下载某一个任务时的上一刻时间(用于计算下载速度)
    NSDate *_last_date;
    //记录下载某一个任务时的上一刻任务下载的字节数(用于计算下载速度)
    NSUInteger _last_file_received_size;
}

@property(nonatomic,strong,readwrite)NSURL *taskURL;
@property(nonatomic,assign,readwrite)TaskState taskState;

@property(nonatomic,strong,readwrite)NSString *taskFileName;
@property(nonatomic,strong,readwrite)NSString *taskFileType;
@property(nonatomic,strong,readwrite)NSString *taskFilePath;

@property(nonatomic,assign,readwrite)NSUInteger bytesWritten;
@property(nonatomic,assign,readwrite)NSUInteger totalBytesWritten;
@property(nonatomic,assign,readwrite)NSUInteger totalBytesExpectedToWrite;

@property(nonatomic,strong,readwrite)NSString *taskDownloadSpeed;
@property(nonatomic,strong,readwrite)NSString *taskAddTime;
@property(nonatomic,strong,readwrite)NSError *taskError;


/**
 manager
 */
@property(nonatomic,weak)WJQTaskManager *manager;
/**
 downloadTask
 */
@property (nonatomic , strong) NSURLSessionDownloadTask *downloadTask;


/**
 保存文件名(md5加密)
 */
@property(nonatomic,strong)NSString *taskSaveName;
/**
 缓存文件存储路径
 */
@property(nonatomic,strong)NSString *taskTmpPath;

@end

@implementation WJQTask

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _last_date = [NSDate date];
        _last_file_received_size = 0;
        
        self.taskURL = url;
        self.taskState = WaitingDownload;
        self.taskFileName = [[url absoluteString]lastPathComponent];
        self.taskFileType = self.taskFileName.pathExtension;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
        self.taskAddTime = [dateFormatter stringFromDate:[NSDate date]];
        
        self.taskSaveName = [self stringMD5:[url absoluteString]];
        self.taskTmpPath  = @"";
        
        self.bytesWritten = 0;
        self.totalBytesWritten = 0;
        self.totalBytesExpectedToWrite = 0;
    }
    return self;
}

#pragma mark - Setter && Getter

- (void)setManager:(WJQTaskManager *)manager {
    _manager = manager;
    _taskFilePath = self.taskFilePath;
}

- (NSString *)taskFilePath {
    NSString *targetPath = [self.manager.downloadPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",self.taskSaveName,self.taskFileType]];
    return targetPath;
}

/**
 set
 
 @param totalBytesWritten totalBytesWritten
 */
- (void)setTotalBytesWritten:(NSUInteger)totalBytesWritten{
    _totalBytesWritten = totalBytesWritten;
    [self caculateSpeed];
}

/**
 下载速度计算
 */
- (void)caculateSpeed {
    NSDate *currentDate = [NSDate date];
    if ([currentDate timeIntervalSinceDate:_last_date] >= 1)
    {
        NSTimeInterval tpTime = [currentDate timeIntervalSinceDate:_last_date];
        NSUInteger tpData;
        if (_totalBytesWritten <_last_file_received_size)
        {
            tpData = 0;
        }
        else
        {
            tpData = _totalBytesWritten - _last_file_received_size;
        }
        _last_date = currentDate;
        _last_file_received_size = _totalBytesWritten;
        
        //根据单位时间内的数据接收量计算下载速度
        NSUInteger tpReceivedDataSpeed = tpData/tpTime;
        NSString *tpSpeed;
        if (tpReceivedDataSpeed<1024.0)
        {
            tpSpeed = [NSString stringWithFormat:@"%.2f B/S",(float)tpReceivedDataSpeed];
        }
        else if (tpReceivedDataSpeed < 1024.0*1024.0)
        {
            tpSpeed = [NSString stringWithFormat:@"%.2f K/S",tpReceivedDataSpeed/1024.0];
        }
        else
        {
            tpSpeed = [NSString stringWithFormat:@"%.2f M/S",tpReceivedDataSpeed/1024.0/1024.0];
        }
        self.taskDownloadSpeed = tpSpeed;
    }
}


#pragma mark - MD5加密

/**
 *  NSStringmd5加密
 *
 *  @return NSString
 */
- (NSString *)stringMD5:(NSString *)md5String {
    if (md5String.length == 0)
    {
        md5String = @"";
    }
    const char *cStr = [md5String UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}


@end
