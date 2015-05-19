//
//  UIColor+Creation.m
//  ABTestPrototype
//
//  Created by Manuel Meyer on 14.05.15.
//  Copyright (c) 2015 Manuel Meyer. All rights reserved.
//

#import "UIColor+Creation.h"

@implementation UIColor (Creation)

+(UIColor *)_colorFromHex:(NSUInteger)hexInt
{
    int r,g,b,a;
    
    r = (hexInt >> 030) & 0xFF;
    g = (hexInt >> 020) & 0xFF;
    b = (hexInt >> 010) & 0xFF;
    a = hexInt & 0xFF;
    
    return [UIColor colorWithRed:r / 255.0f
                           green:g / 255.0f
                            blue:b / 255.0f
                           alpha:a / 255.0f];
}

+(UIColor *)colorFromHexString:(NSString *)hexString
{
    hexString = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([hexString hasPrefix:@"#"])
        hexString = [hexString substringFromIndex:1];
    else if([hexString hasPrefix:@"0x"])
        hexString = [hexString substringFromIndex:2];
    
    NSUInteger l = [hexString length];
    if ((l!=3) && (l!=4) && (l!=6) && (l!=8))
        return nil;
    
    if ([hexString length] > 2 && [hexString length]< 5) {
        NSMutableString *newHexString = [[NSMutableString alloc] initWithCapacity:[hexString length]*2];
        [hexString enumerateSubstringsInRange:NSMakeRange(0, [hexString length])
                                      options:NSStringEnumerationByComposedCharacterSequences
                                   usingBlock:^(NSString *substring,
                                                NSRange substringRange,
                                                NSRange enclosingRange,
                                                BOOL *stop)
         {
             [newHexString appendFormat:@"%@%@", substring, substring];
         }];
        hexString = newHexString;
    }
    
    if ([hexString length] == 6)
        hexString = [hexString stringByAppendingString:@"ff"];
    
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    unsigned hexNum;
    if (![scanner scanHexInt:&hexNum])
        return nil;
    return [self _colorFromHex:hexNum];
}



-(NSString *)hexString {
  
  if (!self) return nil;
  if (self == [UIColor whiteColor]) return @"#ffffff";
  
  CGFloat red, blue, green, alpha;
  [self getRed:&red green:&green blue:&blue alpha:&alpha];
  
  NSUInteger redDec =   (NSUInteger)(red   * 255);
  NSUInteger greenDec = (NSUInteger)(green * 255);
  NSUInteger blueDec =  (NSUInteger)(blue  * 255);
  
  NSString *returnString = [NSString stringWithFormat:@"#%02x%02x%02x", (unsigned int)redDec, (unsigned int)greenDec, (unsigned int)blueDec];
  NSLog(@"%@", returnString);
  return returnString;
  
}


@end