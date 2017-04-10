//
//  TaskViewController.m
//  WJQFileDownloadManager
//
//  Created by 吴 吴 on 2017/3/29.
//  Copyright © 2017年 JackWu. All rights reserved.
//

#import "TaskViewController.h"
#import "TaskListCell.h"

@interface TaskViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    UITableView *infoTable;
    NSMutableArray *dataArray;
}

@end

@implementation TaskViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"任务列表";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self uploadDataReq];
    [self setupUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 创建UI

- (void)setupUI {
    infoTable = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
    infoTable.dataSource = self;
    infoTable.delegate  = self;
    infoTable.separatorStyle = UITableViewCellSeparatorStyleNone;
    [infoTable registerClass:[TaskListCell class] forCellReuseIdentifier:@"TaskListCell"];
    [self.view addSubview:infoTable];
    
    [infoTable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

#pragma mark - 网络请求

- (void)uploadDataReq {
    dataArray = [NSMutableArray array];
    
    NSURL *urlOne = [NSURL URLWithString:@"http://sw.bos.baidu.com/sw-search-sp/software/de4fe04c2280e/SogouInput_mac_4.0.0.3127.dmg"];
    WJQTask *taskOne = [[WJQTask alloc]initWithURL:urlOne];
    [dataArray addObject:taskOne];
    
    NSURL *urlTwo = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1489478928414&di=b5a21234a686ae792f3f56caedc4fed7&imgtype=0&src=http%3A%2F%2Fpic.qiantucdn.com%2F58pic%2F18%2F30%2F22%2F19P58PICdxw_1024.jpg"];
    WJQTask *taskTwo = [[WJQTask alloc]initWithURL:urlTwo];
    [dataArray addObject:taskTwo];
    
    NSURL *urlThree = [NSURL URLWithString:@"http://img3.imgtn.bdimg.com/it/u=1379837709,350449962&fm=23&gp=0.jpg"];
    WJQTask *taskThree = [[WJQTask alloc]initWithURL:urlThree];
    [dataArray addObject:taskThree];
    
    NSURL *urlFour = [NSURL URLWithString:@"http://img3.imgtn.bdimg.com/it/u=2140696183,3131076942&fm=23&gp=0.jpg"];
    WJQTask *taskFour = [[WJQTask alloc]initWithURL:urlFour];
    [dataArray addObject:taskFour];
}

#pragma mark - UITableViewDataSource && Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"TaskListCell";
    TaskListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    ((TaskListCell *)cell).task = dataArray[indexPath.row];
    [((TaskListCell *)cell) setDownloadBlock:^{
        self.tabBarController.selectedIndex = 1;
    }];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
