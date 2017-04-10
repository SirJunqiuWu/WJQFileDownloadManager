//
//  VCManager.m
//  JumpTest
//
//  Created by Jack on 15/11/2.
//  Copyright © 2015年 Jack. All rights reserved.
//

#import "TWVCManager.h"
#import "AppDelegate.h"

static TWVCManager *vcManager = nil;

@interface TWVCManager()
{
    UIViewController *m_rootViewController;
}

@end

@implementation TWVCManager

+ (TWVCManager *)shareVCManager
{
    @synchronized(self)
    {
        static dispatch_once_t pred;
        dispatch_once(&pred, ^{
            vcManager = [[self alloc] init];
        });
    }
    return vcManager;
}

- (UIViewController*)getRootViewController
{
    m_rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return m_rootViewController;
}

- (UIViewController*)getTopViewController
{
    return [self topViewControllerOfViewController:[self getRootViewController]];
}

- (UIViewController*)topViewControllerOfViewController:(UIViewController*)rootVC
{
    if ([rootVC isKindOfClass:[UINavigationController class]])
    {
        return [self topViewControllerOfViewController:[(UINavigationController*)rootVC visibleViewController]];
    }
    else if (rootVC.presentedViewController)
    {
        return [self topViewControllerOfViewController:rootVC.presentedViewController];
    }
    else if ([rootVC isKindOfClass:[UITabBarController class]])
    {
        return [self topViewControllerOfViewController:[(UITabBarController*)rootVC selectedViewController]];
    }
    else
    {
        return rootVC;
    }
}
@end
