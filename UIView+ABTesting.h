//
//  UIView+Screenshot.h
//  ABTestPrototype
//
//  Created by Manuel Meyer on 13.05.15.
//  Copyright (c) 2015 Manuel Meyer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (ABTesting)
- (UIImage *)ab_takeSnapshot;
- (NSString *)listOfSubviews;
@end
