//
//  UIViewController+Updating.m
//  ABTestPrototype
//
//  Created by Manuel Meyer on 12.05.15.
//  Copyright (c) 2015 Manuel Meyer. All rights reserved.
//

#import "UIViewController+Updating.h"

@implementation UIViewController (Updating)
-(void)updateViewWithAttributes:(NSDictionary *)attributes
{
    [[attributes allKeys] enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        
        if ([obj isEqualToString:@"backgroundColor"]) {
            
                [self.view setBackgroundColor:attributes[obj]];
        }
    }];
}
@end
