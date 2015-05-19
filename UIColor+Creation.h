//
//  UIColor+Creation.h
//  ABTestPrototype
//
//  Created by Manuel Meyer on 14.05.15.
//  Copyright (c) 2015 Manuel Meyer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Creation)
+(UIColor *)colorFromHexString:(NSString *)hexString;
-(NSString *)hexString;
@end
