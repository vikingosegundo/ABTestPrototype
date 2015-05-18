//
//  UIView+Extra.m
//  ABTestPrototype
//
//  Created by Manuel Meyer on 18.05.15.
//  Copyright (c) 2015 Manuel Meyer. All rights reserved.
//

#import "UIView+Extra.h"

@implementation UIView (Extra)

- (UIView *)findTopMostViewForPoint:(CGPoint)point
{
    for(NSInteger i = self.subviews.count - 1; i >= 0; --i)
    {
        UIView *subview = [self.subviews objectAtIndex:i];
        if(!subview.hidden && CGRectContainsPoint(subview.frame, point))
        {
            CGPoint pointConverted = [self convertPoint:point toView:subview];
            return [subview findTopMostViewForPoint:pointConverted];
        }
    }
    
    return self;
}

- (BOOL)isTopmostViewInWindow
{
    if(self.window == nil)
    {
        return NO;
    }
    
    CGPoint centerPointInSelf = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGPoint centerPointOfSelfInWindow = [self convertPoint:centerPointInSelf toView:self.window];
    UIView *view = [self.window findTopMostViewForPoint:centerPointOfSelfInWindow];
    BOOL isTopMost = view == self || [view isDescendantOfView:self];
    return isTopMost;
}

@end
