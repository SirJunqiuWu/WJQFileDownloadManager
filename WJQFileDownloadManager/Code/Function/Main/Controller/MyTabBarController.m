//
//  MyTabBarController.m
//  WJQFileDownloadManager
//
//  Created by 吴 吴 on 2017/3/29.
//  Copyright © 2017年 JackWu. All rights reserved.
//

#import "MyTabBarController.h"
#import "TaskViewController.h"
#import "DownloadViewController.h"

@interface MyTabBarController ()

@end

@implementation MyTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    TaskViewController *taskVC = [[TaskViewController alloc]init];
    UINavigationController *navOne = [[UINavigationController alloc]initWithRootViewController:taskVC];
    
    DownloadViewController *downloadVC = [[DownloadViewController alloc]init];
    UINavigationController *navTwo = [[UINavigationController alloc]initWithRootViewController:downloadVC];
    
    self.viewControllers = [NSArray arrayWithObjects:navOne,navTwo,nil];
    
    navOne.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemBookmarks tag:0];
    navTwo.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemDownloads tag:1];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
