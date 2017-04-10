//
//  DownloadViewController.m
//  WJQFileDownloadManager
//
//  Created by 吴 吴 on 2017/3/29.
//  Copyright © 2017年 JackWu. All rights reserved.
//

#import "DownloadViewController.h"
#import "TaskFinishedCell.h"
#import "TaskLoadingCell.h"
#import "TaskFailedCell.h"
#import "HeaderView.h"

@interface DownloadViewController ()<WJQTaskManagerDelegate,UITableViewDataSource,UITableViewDelegate>
{
    UITableView *infoTable;
    NSMutableArray *downloadingArr;
    NSMutableArray *finishedArr;
    NSMutableArray *failedArr;
    NSMutableArray *dataArr;
}

@end

@implementation DownloadViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"下载列表";
        dataArr = [NSMutableArray array];
        [WJQTaskManager sharedManager].delegate = self;
        [WJQTaskManager sharedManager].downloadMaxCount = 2;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    // Do any additional setup after loading the view.
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc]initWithTitle:@"开始全部" style:UIBarButtonItemStylePlain target:self action:@selector(startAllTask)];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]initWithTitle:@"取消全部" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAllTask)];
    
    self.navigationItem.leftBarButtonItem = leftItem;
    self.navigationItem.rightBarButtonItem = rightItem;

    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self uploadDataReq];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 创建UI

- (void)setupUI {
    infoTable = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
    infoTable.dataSource = self;
    infoTable.delegate = self;
    infoTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    [infoTable registerClass:[TaskFinishedCell class] forCellReuseIdentifier:@"TaskFinishedCell"];
    [infoTable registerClass:[TaskLoadingCell class] forCellReuseIdentifier:@"TaskLoadingCell"];
    [infoTable registerClass:[TaskFailedCell class] forCellReuseIdentifier:@"TaskFailedCell"];
    [infoTable registerClass:[HeaderView class] forHeaderFooterViewReuseIdentifier:@"HeaderView"];
    [self.view addSubview:infoTable];

    NSLog(@"%f",self.view.frame.size.height);
    
    [infoTable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(64);
        make.width.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(49);
    }];
}

#pragma mark - 网络请求

- (void)uploadDataReq {
    downloadingArr = [WJQTaskManager sharedManager].downloadingTaskArr;
    finishedArr    = [WJQTaskManager sharedManager].finishedTaskArr;
    failedArr      = [WJQTaskManager sharedManager].failedTaskArr;
    [dataArr removeAllObjects];
    [dataArr addObject:finishedArr];
    [dataArr addObject:downloadingArr];
    [dataArr addObject:failedArr];
    [infoTable reloadData];
}

#pragma mark - 按钮点击事件

- (void)startAllTask {
    NSLog(@"开始下载全部任务");
    [[WJQTaskManager sharedManager]startAll];
}

- (void)cancelAllTask {
    NSLog(@"取消下载全部任务");
    [[WJQTaskManager sharedManager]cancelAll];
}

#pragma mark - WJQTaskManagerDelegate

- (void)taskWillAdd:(WJQTask *)task Error:(NSError *)error {
    if (error)
    {
        NSLog(@"%@",error.domain);
    }
}

- (void)taskDidAdd:(WJQTask *)task {
    NSLog(@"添加成功");
    [self uploadDataReq];
}

- (void)taskDidStart:(WJQTask *)task {
    NSLog(@"任务开始下载");
    [self uploadDataReq];
}

- (void)allTaskDidStart {
    NSLog(@"开始全部");
    [self uploadDataReq];
}

- (void)taskDidSuspend:(WJQTask *)task {
    NSLog(@"任务被暂停");
    [self uploadDataReq];
}

- (void)taskDidEnd:(WJQTask *)task {
    if (task.taskError)
    {
        NSLog(@"下载失败");
    }
    else
    {
        NSLog(@"下载完成");
    }
    [self uploadDataReq];
}

- (void)taskDidDelete:(WJQTask *)task Error:(NSError *)error {
    if (error)
    {
        NSLog(@"删除失败 %@",error.domain);
    }
    else
    {
        NSLog(@"删除成功");
    }
    [self uploadDataReq];
}

- (void)updateProgress:(WJQTask *)task {
    //在主线程里更新下载进度
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *cellArr = [infoTable visibleCells];
        for(id obj in cellArr)
        {
            if ([obj isKindOfClass:[TaskLoadingCell class]])
            {
                TaskLoadingCell *cell = (TaskLoadingCell *)obj;
                if (cell.task == task)
                {
                    cell.task = task;
                }
            }
        }
    });
}

#pragma mark - UITableViewDataSource && Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return dataArr.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section>=dataArr.count)
    {
        return 0;
    }
    NSArray *sectionArr = dataArr[section];
    return sectionArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
    {
        static NSString *cellID = @"TaskFinishedCell";
        TaskFinishedCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
        return cell;
    }
    else if (indexPath.section == 1)
    {
        static NSString *cellID = @"TaskLoadingCell";
        TaskLoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
        return cell;
    }
    else
    {
        static NSString *cellID = @"TaskFailedCell";
        TaskFailedCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section >=dataArr.count)
    {
        return;
    }
    NSArray *tpArr = dataArr[indexPath.section];
    if (indexPath.row >=tpArr.count)
    {
        return;
    }
    if (indexPath.section == 0)
    {
        WJQTask *tpTask = tpArr[indexPath.row];
        ((TaskFinishedCell *)cell).task = tpTask;
    }
    else if (indexPath.section == 1)
    {
        WJQTask *tpTask = tpArr[indexPath.row];
        ((TaskLoadingCell *)cell).task = tpTask;
    }
    else
    {
        WJQTask *tpTask = tpArr[indexPath.row];
        ((TaskFailedCell *)cell).task = tpTask;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        if (indexPath.section >=dataArr.count)
        {
            return;
        }
        NSArray *tpArr = dataArr[indexPath.section];
        if (indexPath.row>=tpArr.count)
        {
            return;
        }
        WJQTask *tpTask = tpArr[indexPath.row];
        [[WJQTaskManager sharedManager]deleteTaskWithTargetTask:tpTask];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    HeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"HeaderView"];
    if (section == 0)
    {
        headerView.textLabel.text = @"下载完成";
    }
    else if (section == 1)
    {
        headerView.textLabel.text = @"下载中";
    }
    else
    {
        headerView.textLabel.text = @"下载失败";
    }
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}


@end
