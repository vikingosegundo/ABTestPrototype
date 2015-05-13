//
//  UIView+Screenshot.m
//  ABTestPrototype
//
//  Created by Manuel Meyer on 13.05.15.
//  Copyright (c) 2015 Manuel Meyer. All rights reserved.
//

#import "UIView+ABTesting.h"

@implementation UIView (ABTesting)
- (UIImage *)ab_takeSnapshot
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    
    // old style [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}



- (NSInteger)depth
{
    NSInteger depth = 0;
    if ([self superview]) {
        depth = [[self superview] depth] + 1;
    }
    return depth;
}
- (NSString *)listOfSubviews
{
    NSString * indent = @"";
    NSInteger depth = [self depth];
    
    for (int counter = 0; counter < depth; counter ++) {
        indent = [indent stringByAppendingString:@"  "];
    }
    
    __block NSString * listOfSubviews = [NSString stringWithFormat:@"\n%@%@", indent, [self description]];
                                         
    if ([self.subviews count] > 0) {
        [self.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIView * subview = obj;
            listOfSubviews = [listOfSubviews stringByAppendingFormat:@"%@", [subview listOfSubviews]];
        }];
    }
    return listOfSubviews;
}

@end
