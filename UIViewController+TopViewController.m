//
//  UIViewController+TopViewController.m
//  ABTestPrototype
//
//  Created by Manuel Meyer on 20.05.15.
//  Copyright (c) 2015 Manuel Meyer. All rights reserved.
//

#import "UIViewController+TopViewController.h"

@implementation UIViewController (TopViewController)
+(UIViewController *)topViewController
{
  UIViewController *topController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
  if ([topController isKindOfClass:[UITabBarController class]]) {
    topController = [(UITabBarController *)topController selectedViewController];
  } else if([topController isKindOfClass:[UINavigationController class]]){
    topController = [(UINavigationController *)topController visibleViewController];
  } else {
    while (topController.presentedViewController) {
      topController = topController.presentedViewController;
    }
  }
  return topController;
}
@end
