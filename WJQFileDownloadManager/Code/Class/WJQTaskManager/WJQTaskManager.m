//
//  WJQTaskManager.m
//  WJQFileDownloadManager
//
//  Created by 吴 吴 on 2017/3/30.
//  Copyright © 2017年 JackWu. All rights reserved.
//

#import "WJQTaskManager.h"
#import <objc/runtime.h>

typedef void(^ProgressCallBack)(WJQTask *task);

static WJQTaskManager *myManager = nil;

@interface WJQTaskManager()

@property(nonatomic,strong,readwrite)NSMutableArray<WJQTask *>*downloadingTaskArr;
@property(nonatomic,strong,readwrite)NSMutableArray<WJQTask *>*finishedTaskArr;
@property(nonatomic,strong,readwrite)NSMutableArray<WJQTask *>*failedTaskArr;

@property(nonatomic,copy)ProgressCallBack progressCallBack;

/**
 AFURLSessionManager:任务管理对象
 */
@property(nonatomic,strong)AFURLSessionManager *sessionManager;
/**
 临时任务存放路径
 */
@property(nonatomic,strong)NSString *taskTmpPath;

@end

@implementation WJQTaskManager

+(instancetype)sharedManager {
    @synchronized (self) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            myManager = [[super allocWithZone:NULL]init];
        });
    }
    return myManager;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone {
    return [WJQTaskManager sharedManager];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return [WJQTaskManager sharedManager];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.downloadingTaskArr = [NSMutableArray array];
        self.finishedTaskArr    = [NSMutableArray array];
        self.failedTaskArr      = [NSMutableArray array];
        
        self.sessionManager     = [[AFURLSessionManager alloc]init];
        
        //加载下载中任务
        [self loadTmpTask];
        //加载已完成任务
        [self loadFinishedTask];
        //加载失败任务
        [self loadFailedTask];
        
        //当程序进来时若有等待下载的任务，执行下载
        if (self.downloadingTaskArr.count >0 && self.downloadMaxCount == 0 )
        {
            self.downloadMaxCount = 1;
            [self runTask];
        }
        
        //当和服务器进行下载请求交互的时候，服务器会返回目标任务的总大小和当前下载的大小
        __weak typeof(self)WeakSelf = self;
        [self.sessionManager setDownloadTaskDidWriteDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            if (WeakSelf.downloadingTaskArr.count >0)
            {
                for(WJQTask *obj in WeakSelf.downloadingTaskArr)
                {
                    NSURLSessionDownloadTask *_downloadTask = [obj valueForKey:@"downloadTask"];
                    if (_downloadTask == downloadTask)
                    {
                        [obj setValue:[NSNumber numberWithUnsignedInteger:(unsigned int)bytesWritten] forKey:@"bytesWritten"];
                        [obj setValue:[NSNumber numberWithUnsignedInteger:(unsigned int)totalBytesWritten] forKey:@"totalBytesWritten"];
                        NSUInteger expectedToWrite = [[obj valueForKey:@"totalBytesExpectedToWrite"]unsignedIntegerValue];
                        if (expectedToWrite < totalBytesExpectedToWrite)
                        {
                            [obj setValue:[NSNumber numberWithUnsignedInteger:(unsigned int)totalBytesExpectedToWrite] forKey:@"totalBytesExpectedToWrite"];
                        }
                        
                        //重要:保存下载信息到文件
                        [WeakSelf saveTaskWithTargetTask:obj];
                        
                        //下载进度回调
                        if (WeakSelf.progressCallBack)
                        {
                            WeakSelf.progressCallBack(obj);
                        }
                    }
                }
            }
        }];
    }
    return self;
}

#pragma mark - Getter

- (NSString *)downloadPath {
    if (!_downloadPath)
    {
        _downloadPath = [self createPath:@"WJQTaskManager/DownloadPath"];
    }
    return _downloadPath;
}

- (NSString *)taskTmpPath {
    if (!_taskTmpPath)
    {
        _taskTmpPath = [self createPath:@"WJQTaskManager/TmpPath"];
    }
    return _taskTmpPath;
}


#pragma mark - 添加下载任务

- (void)addTaskWithTargetTask:(WJQTask *)task {
    //更新任务对象里面的时间字段
    task = [[WJQTask alloc]initWithURL:task.taskURL];
    [task setValue:self forKey:@"manager"];
    
    if ([self taskIsLoaded:task] || [self taskIsInTmp:task])
    {
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self confirmDownloadTaskWithTask:task];
        }];
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"任务已经在列表中,是否重新下载" preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:cancel];
        [alertVC addAction:ok];
        [[[TWVCManager shareVCManager]getTopViewController].navigationController presentViewController:alertVC animated:YES  completion:NULL];
    }
    else
    {
        [self confirmDownloadTaskWithTask:task];
    }
}

- (void)confirmDownloadTaskWithTask:(WJQTask *)task {
    NSError *error = nil;
    
    //需要判断当前添加的任务是否已经下载 或者 已经在缓存中(缓存没结果的，缓存结果为失败的)
    if ([self taskIsLoaded:task])
    {
        error = [NSError errorWithDomain:@"任务已经下载" code:0 userInfo:nil];
    }
    if ([self taskIsInTmp:task])
    {
        error = [NSError errorWithDomain:@"任务已经在缓存中" code:0 userInfo:nil];
    }
    if ([self taskIsInFailed:task])
    {
        error = [NSError errorWithDomain:@"任务下载失败过" code:0 userInfo:nil];
    }
    
    
    //任务将要被添加
    if ([self.delegate respondsToSelector:@selector(taskWillAdd:Error:)])
    {
        [self.delegate taskWillAdd:task Error:error];
    }
    
    //开始往后走，看是否需要删除原有的文件继续下载还是直接下载
    if (error)
    {
        //存在删除原来在本地的文件
        [self deleteTaskWithTargetTask:task Callback:^(NSError *error) {
            if (error)
            {
                NSLog(@"添加下载时，删除原来在本地的文件失败%@",error.domain);
            }
            else
            {
                NSLog(@"添加下载时，删除原来在本地的文件成功");
            }
        }];
    }
    //下载前的数据变化:任务状态变更为等待下载
    [task setValue:[NSNumber numberWithUnsignedInteger:WaitingDownload] forKey:@"taskState"];
    [self.downloadingTaskArr addObject:task];
    
    //任务保存到本地
    [self saveTaskWithTargetTask:task];
    
    
    //任务执行添加
    if ([self.delegate respondsToSelector:@selector(taskDidAdd:)])
    {
        [self.delegate taskDidAdd:task];
    }
    
    //执行任务下载
    [self runTask];
}

- (void)runTask {
    if (self.downloadingTaskArr.count >0)
    {
        //获取队列中正在执行、将要执行、等待执行的任务数
        NSInteger downloading_count = 0;
        NSInteger will_downloading_count = 0;
        NSInteger waiting_downloading_count = 0;
        for(WJQTask *obj in self.downloadingTaskArr)
        {
            if (obj.taskState == Downloading)
            {
                downloading_count+=1;
            }
            else if (obj.taskState == WillDownload)
            {
                will_downloading_count+=1;
            }
            else if (obj.taskState == WaitingDownload)
            {
                waiting_downloading_count += waiting_downloading_count+1;
            }
            else
            {
                NSAssert(@"", nil);
            }
        }
        
        //获取还可以执行的任务数,进行状态的预处理（能支持的并发数-正在下载的任务个数）
        NSInteger sepCount = self.downloadMaxCount - downloading_count;
        if (sepCount>0)
        {
            //获取可执行任务数量 （当将要下载的任务数目超过可执行的任务数，我们把超过的任务状态全部修改为等待下载）
            if (will_downloading_count>sepCount)
            {
                //通常情况下会进入这个判断，但不执行for循环
                NSInteger t_count = will_downloading_count - sepCount;
                for (WJQTask *obj in self.downloadingTaskArr)
                {
                    if (obj.taskState == WillDownload)
                    {
                        [obj setValue:[NSNumber numberWithUnsignedInteger:WaitingDownload] forKey:@"taskState"];
                        t_count = t_count - 1;
                        if (t_count <= 0)
                        {
                            break;
                        }
                    }
                }
            }
            else
            {
                //（没有超过可以执行的任务数目，预取出剩余可以执行的数目任务到将要下载的状态）从等待队列中，预取出指定数量的任务，更改状态，预下载
                NSInteger t_count = sepCount - will_downloading_count;
                if (t_count > 0)
                {
                    for(WJQTask *obj in self.downloadingTaskArr)
                    {
                        if (obj.taskState == WaitingDownload)
                        {
                            [obj setValue:[NSNumber numberWithUnsignedInteger:WillDownload] forKey:@"taskState"];
                            t_count = t_count-1;
                            if (t_count <=0)
                            {
                                break;
                            }
                        }
                    }
                }
            }
            
            //任务预处理完毕、现在执行状态为WillDownload的任务
            NSInteger t_count = sepCount;
            for(WJQTask *obj in self.downloadingTaskArr)
            {
                if (obj.taskState == WillDownload)
                {
                    if (![obj valueForKey:@"manager"])
                    {
                        [obj setValue:self forKey:@"manager"];
                    }
                    //开始下载
                    [self downloadTaskWithTargetTask:obj];
                    
                    //将要下载的任务数目减1
                    t_count = t_count - 1;
                    if (t_count <= 0)
                    {
                        //所有可执行的任务下载出现结果，循环结束
                        break;
                    }
                }
            }
        }
    }
}

//下载某个任务
-(void)downloadTaskWithTargetTask:(WJQTask *)task {
    
    NSURLSessionDownloadTask *downloadTask = [self dolTask:task Progress:^(NSProgress *downloadProgress) {
        //更新下载进度
        if ([self.delegate respondsToSelector:@selector(updateProgress:)])
        {
            [self.delegate updateProgress:task];
        }
    } Destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        //有返回值,下载路径WJQTaskManager/DownloadPath/taskSaveName.taskFileType
        return [NSURL fileURLWithPath:task.taskFilePath];
    } CompletionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(updateProgress:)])
        {
            [self.delegate updateProgress:task];
        }
        if (task.taskState == Suspended)
        {
            //下载完成前任务是挂起的状态
            if ([self.delegate respondsToSelector:@selector(taskDidSuspend:)])
            {
                [self.delegate taskDidSuspend:task];
            }
        }
        if (task.taskState == Downloading)
        {
            [task setValue:error forKey:@"taskError"];
            //下载完成前任务是正在下载的状态
            if (error)
            {
               //下载结果为失败
                if (![self taskIsInFailed:task])
                {
                    [self.failedTaskArr addObject:task];
                }
                [task setValue:[NSNumber numberWithUnsignedInteger:Failed] forKey:@"taskState"];
            }
            else
            {
                //下载结果为成功
                [self.finishedTaskArr addObject:task];
                [task setValue:[NSNumber numberWithUnsignedInteger:Complete] forKey:@"taskState"];
            }
            
            
            //状态修改完毕，数据变更 和 保存到本地
            [self.downloadingTaskArr removeObject:task];
            
            [self saveTaskWithTargetTask:task];
            
            if ([self.delegate respondsToSelector:@selector(taskDidEnd:)])
            {
                [self.delegate taskDidEnd:task];
            }
        }
        if (task.taskState !=WaitingDownload)
        {
            [self runTask];
        }
    }];
    
    //修改该任务的状态为 正在下载
    [task setValue:[NSNumber numberWithUnsignedInteger:Downloading] forKey:@"taskState"];
    [downloadTask resume];
    
    if ([self.delegate respondsToSelector:@selector(taskDidStart:)])
    {
        [self.delegate taskDidStart:task];
    }
}


- (NSURLSessionDownloadTask *)dolTask:(WJQTask *)task Progress:(void(^)(NSProgress *downloadProgress))downloadProgressBlock
                      Destination:(NSURL *(^)(NSURL *targetPath,NSURLResponse *response))destination CompletionHandler:(void(^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler {
    NSURLSessionDownloadTask *downloadTask = nil;
    NSData               *resumeData   = nil;
    NSString             *tmpPath      = [task valueForKey:@"taskTmpPath"];
    if (tmpPath && tmpPath.length >0)
    {
        //缓存中存在，则继续断点处下载
        NSData *tmpData = [NSData dataWithContentsOfFile:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpPath]];
        if (tmpData)
        {
            NSMutableURLRequest *newResumeRequest = [NSMutableURLRequest requestWithURL:task.taskURL];
            [newResumeRequest addValue:[NSString stringWithFormat:@"bytes=%ld-",(unsigned long)tmpData.length] forHTTPHeaderField:@"Range"];
            NSData *newResumeRequestData = [NSKeyedArchiver archivedDataWithRootObject:newResumeRequest];
            
            NSMutableDictionary *resumeDataDic = [NSMutableDictionary dictionary];
            [resumeDataDic setValue:task.taskURL.absoluteString forKey:@"NSURLSessionDownloadURL"];
            [resumeDataDic setObject:[NSNumber numberWithInteger:tmpData.length]forKey:@"NSURLSessionResumeBytesReceived"];
            [resumeDataDic setObject:newResumeRequestData forKey:@"NSURLSessionResumeCurrentRequest"];
            [resumeDataDic setObject:[[NSTemporaryDirectory() stringByAppendingPathComponent:tmpPath] lastPathComponent]forKey:@"NSURLSessionResumeInfoTempFileName"];
            
            //查看缓存中是否存在该任务已经下载的数据，如果有则从断点处继续向服务器请求下载
            resumeData = [NSPropertyListSerialization dataWithPropertyList:resumeDataDic format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
        }
    }
    
    
    if (resumeData && resumeData.length >0)
    {
        //缓存中存在已经下载的数据，断点处继续下载
        downloadTask = [self.sessionManager downloadTaskWithResumeData:resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
            downloadProgressBlock(downloadProgress);
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return destination(targetPath,response);
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            completionHandler(response,filePath,error);
        }];
        [task setValue:downloadTask forKey:@"downloadTask"];
    }
    else
    {
        //不存在缓存数据，则从0开始 并获取缓存中系统临时分配的地址
        NSURLRequest *newRequest = [NSURLRequest requestWithURL:task.taskURL];
        downloadTask = [self.sessionManager downloadTaskWithRequest:newRequest progress:^(NSProgress * _Nonnull downloadProgress) {
            downloadProgressBlock(downloadProgress);
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return destination(targetPath,response);
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            completionHandler(response,filePath,error);
        }];
        [task setValue:downloadTask forKey:@"downloadTask"];
        [self loadTmp:task];
    }
    return downloadTask;
}

#pragma mark - 删除任务

- (void)deleteTaskWithTargetTask:(WJQTask *)task {
    [self deleteTaskWithTargetTask:task Callback:^(NSError *error) {
        if ([self.delegate respondsToSelector:@selector(taskDidDelete:Error:)])
        {
            [self.delegate taskDidDelete:task Error:error];
        }
    }];
}

- (void)startAll {
    //开始全部，将正在下载中有挂起的任务变为将要下载
    [self.downloadingTaskArr enumerateObjectsUsingBlock:^(WJQTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.taskState == Suspended)
        {
            [obj setValue:[NSNumber numberWithUnsignedInteger:WillDownload] forKey:@"taskState"];
        }
    }];
    if ([self.delegate respondsToSelector:@selector(allTaskDidStart)])
    {
        [self.delegate allTaskDidStart];
    }
    [self runTask];
}

- (void)cancelAll {
    //取消所有下载中的和将要下载的
    [self.downloadingTaskArr enumerateObjectsUsingBlock:^(WJQTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.taskState == WillDownload)
        {
            [obj setValue:[NSNumber numberWithUnsignedInteger:WaitingDownload] forKey:@"taskState"];
        }
        if (obj.taskState == Downloading)
        {
            [obj setValue:[NSNumber numberWithUnsignedInteger:WaitingDownload] forKey:@"taskState"];
            NSURLSessionDownloadTask *downloadTask = [obj valueForKey:@"downloadTask"];
            [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                
            }];
        }
    }];
}

- (void)suspendTaskWithTargetTask:(WJQTask *)task {
    [task setValue:[NSNumber numberWithUnsignedInteger:Suspended] forKey:@"taskState"];
    NSURLSessionDownloadTask *downloadTask = [task valueForKey:@"downloadTask"];
    [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
    }];
    [self runTask];
}

- (void)resumeTaskWithTargetTask:(WJQTask *)task {
    __block NSInteger downloading_count = 0;
    __block NSInteger will_downloading_count = 0;
    __block NSInteger waiting_downloading_count = 0;
    [self.downloadingTaskArr enumerateObjectsUsingBlock:^(WJQTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.taskState == Downloading)
        {
            downloading_count+=1;
        }
        else if (obj.taskState == WillDownload)
        {
            will_downloading_count+=1;
        }
        else if (obj.taskState == waiting_downloading_count)
        {
            waiting_downloading_count+=1;
        }
        else
        {
            NSAssert(@"", nil);
        }
    }];
    
    NSInteger sepCount = self.downloadMaxCount - downloading_count;
    if (sepCount <=0)
    {
        //队列已满，暂停一个,给当前这个开始的任务让出一个位置 那么。该暂停哪一个呢?(可以将最后添加进来的任务第一个暂停)
        if (downloading_count>0)
        {
            __block NSInteger tp_count = downloading_count;
            [self.downloadingTaskArr enumerateObjectsUsingBlock:^(WJQTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.taskState == Downloading)
                {
                    tp_count -=1;
                    if (tp_count == self.downloadMaxCount-1)
                    {
                        //刚好释放出一个位置
                        [obj setValue:[NSNumber numberWithUnsignedInteger:WaitingDownload] forKey:@"taskState"];
                        NSURLSessionDownloadTask *downloadTask = [obj valueForKey:@"downloadTask"];
                        [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                        }];
                        *stop = YES;
                    }
                }
            }];
        }
    }
    //修改当前任务的状态，执行下载
    [task setValue:[NSNumber numberWithUnsignedInteger:WillDownload] forKey:@"taskState"];
    [self runTask];
}

#pragma mark - 获取文件在下载时的临时缓存路径

/**
 获取缓存路径
 
 @param task task
 */
-(void)loadTmp:(WJQTask *)task{
    NSURLSessionDownloadTask *downloadTask = [task valueForKey:@"downloadTask"];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([downloadTask class], &outCount);
    for (i = 0; i<outCount; i++)
    {
        objc_property_t property = properties[i];
        const char* char_f =property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:char_f];
        if ([@"downloadFile" isEqualToString:propertyName])
        {
            id propertyValue = [downloadTask valueForKey:(NSString *)propertyName];
            unsigned int downloadFileoutCount, downloadFileIndex;
            objc_property_t *downloadFileproperties = class_copyPropertyList([propertyValue class], &downloadFileoutCount);
            for (downloadFileIndex = 0; downloadFileIndex < downloadFileoutCount; downloadFileIndex++)
            {
                objc_property_t downloadFileproperty = downloadFileproperties[downloadFileIndex];
                const char* downloadFilechar_f =property_getName(downloadFileproperty);
                NSString *downloadFilepropertyName = [NSString stringWithUTF8String:downloadFilechar_f];
                if([@"path" isEqualToString:downloadFilepropertyName])
                {
                    id downloadFilepropertyValue = [propertyValue valueForKey:(NSString *)downloadFilepropertyName];
                    if(downloadFilepropertyValue)
                    {
                        //用空字符代替了沙盒的根目录
                        NSLog(@"aaaaaa%@",NSTemporaryDirectory());
                        NSString *tmpPath = [downloadFilepropertyValue stringByReplacingOccurrencesOfString:NSTemporaryDirectory() withString:@""];
                        [task setValue:tmpPath forKey:@"taskTmpPath"];
                    }
                    break;
                }
            }
            free(downloadFileproperties);
        }
        else
        {
            continue;
        }
    }
    free(properties);
}

//删除目标任务
- (void)deleteTaskWithTargetTask:(WJQTask *)task Callback:(void(^)(NSError *error))callback {
    if ([task valueForKey:@"manager"])
    {
        [task setValue:self forKey:@"manager"];
    }
    
    //停止下载session
    NSURLSessionDataTask *downloadTask = [task valueForKey:@"downloadTask"];
    [downloadTask cancel];

    //=================1.下载完成的任务以及plist文件更新掉 完成数组也更新
    if ([[NSFileManager defaultManager]fileExistsAtPath:task.taskFilePath])
    {
        NSError *error = nil;
        [[NSFileManager defaultManager]removeItemAtPath:task.taskFilePath error:&error];
        if (error)
        {
            callback(error);
        }
        
        NSString *tpPath = [self.taskTmpPath stringByAppendingPathComponent:@"FinishedTask.plist"];
        NSArray  *tpArr = [NSArray arrayWithContentsOfFile:tpPath];
        NSMutableArray *tpFinishedTaskArr = [NSMutableArray arrayWithArray:tpArr];
        for(NSDictionary *obj in tpFinishedTaskArr)
        {
            if ([[obj objectForKey:@"taskURL"] isEqualToString:[task.taskURL absoluteString]])
            {
                //在plist中找到已经下载的文件，删除掉，跳出勋魂
                [tpFinishedTaskArr removeObject:obj];
                break;
            }
        }
        
        //FinishedTask.plist文件更新掉
        if (tpFinishedTaskArr)
        {
            [tpFinishedTaskArr writeToFile:tpPath atomically:YES];
        }
        
        //完成数组也更新
        [self.finishedTaskArr enumerateObjectsUsingBlock:^(WJQTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.taskURL.absoluteString isEqualToString:task.taskURL.absoluteString])
            {
                [self.finishedTaskArr removeObject:obj];
                *stop = YES;
            }
        }];
    }
    
    //====================下载中的临时文件
    NSString *path = [self.taskTmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",[task valueForKey:@"taskSaveName"]]];
    if ([[NSFileManager defaultManager]fileExistsAtPath:path])
    {
        //删除文件
        NSError *error = nil;
        [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
        if (error)
        {
            callback(error);
        }
        
        [self.downloadingTaskArr enumerateObjectsUsingBlock:^(WJQTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.taskURL.absoluteString isEqualToString:task.taskURL.absoluteString])
            {
                NSString *tmpPath = [obj valueForKey:@"taskTmpPath"];
                if (tmpPath && tmpPath.length>0)
                {
                    [[NSFileManager defaultManager]removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpPath] error:nil];
                }
                [self.downloadingTaskArr removeObject:obj];
                *stop = YES;
            }
        }];
    }
    
    
    //===============更新下载失败数据 plist文件以及数组
    NSString *failedPath = [self.taskTmpPath stringByAppendingPathComponent:@"FailedTask.plist"];
    NSArray  *failedArr  = [NSArray arrayWithContentsOfFile:failedPath];
    NSMutableArray *tpFailedArray = [NSMutableArray arrayWithArray:failedArr];
    for(NSDictionary *obj in tpFailedArray)
    {
        if ([[obj objectForKey:@"taskURL"]isEqualToString:[task.taskURL absoluteString]])
        {
            [tpFailedArray removeObject:obj];
            break;
        }
    }
    if (tpFailedArray)
    {
        [tpFailedArray writeToFile:failedPath atomically:YES];
    }
    
    [self.failedTaskArr enumerateObjectsUsingBlock:^(WJQTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.taskURL.absoluteString isEqualToString:task.taskURL.absoluteString])
        {
            [self.failedTaskArr removeObject:obj];
            *stop = YES;
        }
    }];
    
    callback(nil);
}

- (void)saveTaskWithTargetTask:(WJQTask *)task {
    if (task.taskState == WaitingDownload || task.taskState == Downloading)
    {
        //临时文件存储路径样式:self.taskTmpPath/b17ca2aa6aa119c728876bc2cbc75e06.plist
       NSString *path = [self.taskTmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",[task valueForKey:@"taskSaveName"]]];
        
        NSDictionary *tpDic = [self getDicWithTargetTask:task];
        [tpDic writeToFile:path atomically:YES];
    }
    else if(task.taskState == Complete)
    {
        NSString *component = [NSString stringWithFormat:@"%@.plist",[task valueForKey:@"taskSaveName"]];
        NSString *path = [self.taskTmpPath stringByAppendingPathComponent:component];
        if ([[NSFileManager defaultManager]fileExistsAtPath:path])
        {
            [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
        }
        
        NSMutableArray *array = [NSMutableArray array];
        for(WJQTask *obj in self.finishedTaskArr)
        {
            NSMutableDictionary *dic = [self getDicWithTargetTask:obj];
            [array addObject:dic];
        }
        NSString *tpPath = [self.taskTmpPath stringByAppendingPathComponent:@"FinishedTask.plist"];
        [array writeToFile:tpPath atomically:YES];
    }
    else if (task.taskState == Failed)
    {
        //下载失败 -- 删除文件、tmp和plist
        if ([[NSFileManager defaultManager]fileExistsAtPath:task.taskFilePath])
        {
            [[NSFileManager defaultManager]removeItemAtPath:task.taskFilePath error:nil];
        }
        
        
        //删除掉下载时系统分配的临时地址下的文件
        NSString *tmpPath = [task valueForKey:@"taskTmpPath"];
        if (tmpPath && tmpPath.length >0)
        {
            if ([[NSFileManager defaultManager]fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpPath]])
            {
                [[NSFileManager defaultManager]removeItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpPath] error:nil];
            }
        }
        
        NSString *path = [self.taskTmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",[task valueForKey:@"taskSaveName"]]];
        if ([[NSFileManager defaultManager]fileExistsAtPath:path])
        {
            [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
        }
        
        NSMutableArray *array = [NSMutableArray array];
        for (WJQTask *obj in self.failedTaskArr)
        {
            NSMutableDictionary *tpDic = [self getDicWithTargetTask:obj];
            [array addObject:tpDic];
        }
        NSString *tpPath = [self.taskTmpPath stringByAppendingPathComponent:@"FailedTask.plist"];
        [array writeToFile:tpPath atomically:YES];
    }
    else
    {
        NSAssert(@"",nil);
    }
}

#pragma mark - 初始化时加载各类型的任务

#pragma mark - 加载完成任务
- (void)loadFinishedTask {
    NSString *path = [self.taskTmpPath stringByAppendingPathComponent:@"FinishedTask.plist"];
    BOOL fileExit = [[NSFileManager defaultManager]fileExistsAtPath:path];
    if (fileExit)
    {
        NSArray *array = [NSArray arrayWithContentsOfFile:path];
        for(NSDictionary *obj in array)
        {
            WJQTask *task = [self getTaskWithDic:obj];
            [task setValue:[NSNumber numberWithUnsignedInteger:Complete] forKey:@"taskState"];
            [self.finishedTaskArr addObject:task];
        }
    }
}

- (void)loadFailedTask {
    NSString *path = [self.taskTmpPath stringByAppendingPathComponent:@"FailedTask.plist"];
    BOOL fileExit = [[NSFileManager defaultManager]fileExistsAtPath:path];
    if (fileExit)
    {
        NSArray *array = [NSArray arrayWithContentsOfFile:path];
        for(NSDictionary *obj in array)
        {
            WJQTask *task = [self getTaskWithDic:obj];
            [task setValue:[NSNumber numberWithUnsignedInteger:Failed] forKey:@"taskState"];
            [self.failedTaskArr addObject:task];
        }
    }
}

- (void)loadTmpTask {
    NSError *error = nil;
    //获取WJQTaskManager/TmpPath路径下的所有文件目录路径
    NSArray *fileListArr = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:self.taskTmpPath error:&error];
    if (!error)
    {
        NSMutableArray *tpArr = [NSMutableArray array];
        for(NSString *file in fileListArr)
        {
            NSString *fileType = file.pathExtension;
            if ([fileType isEqualToString:@"plist"])
            {
                if (![file isEqualToString:@"FinishedTask.plist"] && ![file isEqualToString:@"FailedTask.plist"])
                {
                    //文件的真实路径
                    NSString *filePath =  [self.taskTmpPath stringByAppendingPathComponent:file];
                    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:filePath];
                    WJQTask *tpTask = [self getTaskWithDic:dic];
                    [tpArr addObject:tpTask];
                }
            }
        }
        [self.downloadingTaskArr addObjectsFromArray:[self sortbyTime:tpArr]];
    }
}
/**
 根据时间进行排序
 
 @param array 任务队列
 @return 新队列
 */
- (NSArray *)sortbyTime:(NSArray *)array {
    NSArray *sorteArray1 = [array sortedArrayUsingComparator:^(id obj1, id obj2){
        WJQTask *task1 = (WJQTask *)obj1;
        WJQTask *task2 = (WJQTask *)obj2;
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *date1 = [df dateFromString:task1.taskAddTime];
        NSDate *date2 = [df dateFromString:task2.taskAddTime];
        if ([[date1 earlierDate:date2]isEqualToDate:date2])
        {
            return (NSComparisonResult)NSOrderedDescending;
        }
        
        else if ([[date1 earlierDate:date2]isEqualToDate:date1])
        {
            return (NSComparisonResult)NSOrderedAscending;
        }
        else
        {
            return (NSComparisonResult)NSOrderedSame;
        }
    }];
    return sorteArray1;
}

#pragma mark - 判断任务状态 1.是否已经下载 2.是否在缓存中  3.是否已经在失败队列中

- (BOOL)taskIsLoaded:(WJQTask *)task {
    return [[NSFileManager defaultManager]fileExistsAtPath:task.taskFilePath];
}

- (BOOL)taskIsInTmp:(WJQTask *)task {
    //缓存中的文件
    NSString *component = [NSString stringWithFormat:@"%@.plist",[task valueForKey:@"taskSaveName"]];
    NSString *tmpPath = [self.taskTmpPath stringByAppendingPathComponent:component];
    return [[NSFileManager defaultManager]fileExistsAtPath:tmpPath];
}

- (BOOL)taskIsInFailed:(WJQTask *)task {
    NSString *failedPlistPath = [self.taskTmpPath stringByAppendingPathComponent:@"FailedTask.plist"];
    //失败plist文件下为一个数组，数组元素为字典，每一个字典元素描述的都是一个下载文件的信息
    NSArray *failedTaskArr = [NSArray arrayWithContentsOfFile:failedPlistPath];
    for(NSDictionary *obj in failedTaskArr)
    {
        WJQTask *tpTask = [self getTaskWithDic:obj];
        if ([[tpTask valueForKey:@"taskSaveName"]isEqualToString:[task valueForKey:@"taskSaveName"]])
        {
            //发现失败plist中有这个文件时，跳出循环
            return YES;
            break;
        }
    }
    return NO;
}


#pragma mark - 从沙盒文件中取出的任务字典构造任务对象 && 根据任务对象转化为可以存储到文件沙盒的字典

- (WJQTask *)getTaskWithDic:(NSDictionary *)dic {
    WJQTask *task = [[WJQTask alloc]initWithURL:[NSURL URLWithString:[dic objectForKey:@"taskURL"]]];
    [task setValue:self forKey:@"manager"];
    [task setValue:[NSNumber numberWithUnsignedInteger:WaitingDownload] forKey:@"taskState"];
    if (![dic objectForKey:@"totalBytesWritten"])
    {
        [task setValue:[NSNumber numberWithUnsignedInteger:0] forKey:@"totalBytesWritten"];
    }
    else
    {
        [task setValue:[dic objectForKey:@"totalBytesWritten"] forKey:@"totalBytesWritten"];
    }
    
    if (![dic objectForKey:@"totalBytesExpectedToWrite"])
    {
        [task setValue:[NSNumber numberWithUnsignedInteger:0]  forKey:@"totalBytesWritten"];
    }
    else
    {
       [task setValue:[dic objectForKey:@"totalBytesExpectedToWrite"] forKey:@"totalBytesExpectedToWrite"];
    }
    [task setValue:[dic objectForKey:@"taskTmpPath"] forKey:@"taskTmpPath"];
    [task setValue:[dic objectForKey:@"taskAddTime"] forKey:@"taskAddTime"];
    return task;
}

- (NSMutableDictionary *)getDicWithTargetTask:(WJQTask *)task {
    NSMutableDictionary *tpDic = [NSMutableDictionary dictionary];
    [tpDic setValue:[task.taskURL absoluteString] forKey:@"taskURL"];
    [tpDic setValue:task.taskFileName forKey:@"fileName"];
    [tpDic setValue:task.taskFileType forKey:@"fileType"];
    [tpDic setValue:[NSNumber numberWithUnsignedInteger:task.totalBytesWritten] forKey:@"totalBytesWritten"];
    [tpDic setValue:[NSNumber numberWithUnsignedInteger:task.totalBytesExpectedToWrite] forKey:@"totalBytesExpectedToWrite"];
    [tpDic setValue:[task valueForKey:@"taskSaveName"] forKey:@"taskSaveName"];
    [tpDic setValue:[task valueForKey:@"taskTmpPath"] forKey:@"taskTmpPath"];
    [tpDic setValue:task.taskAddTime forKey:@"taskAddTime"];
    return tpDic;
}


#pragma mark - 文件管理模块

/**
 根据路径，创建文件夹

 @param path 文件夹路径
 @return 文件夹路径
 */
- (NSString *)createPath:(NSString *)path {
    NSString *libDir   = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES)objectAtIndex:0];
    NSString *filePath = [libDir stringByAppendingPathComponent:path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //判断该路径下是否存在文件夹
    BOOL isFileExit = [fileManager fileExistsAtPath:filePath];
    if (!isFileExit)
    {
        //不存在则创建文件夹
        BOOL result = [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        if (!result)
        {
            //创建失败
            return nil;
        }
    }
    return filePath;
}

@end
