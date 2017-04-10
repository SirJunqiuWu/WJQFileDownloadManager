//
//  TWVCManager.h
//  JumpTest
//
//  Created by Jack on 15/11/2.
//  Copyright © 2015年 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TWVCManager : NSObject

/**
 *  创建单例
 *
 *  @return VCManager
 */
+ (TWVCManager *)shareVCManager;


/**
 *  获取当前显示视图
 *
 *  @return 当前顶层显示视图
 */
- (UIViewController*)getTopViewController;
@end
