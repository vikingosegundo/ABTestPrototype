//
//  ABController.m
//  ABTestPrototype
//
//  Created by Manuel Meyer on 12.05.15.
//  Copyright (c) 2015 Manuel Meyer. All rights reserved.
//

#import "ABController.h"

#import <Aspects/Aspects.h>
#import <OCFWebServer/OCFWebServer.h>
#import <OCFWebServer/OCFWebServerRequest.h>
#import <OCFWebServer/OCFWebServerResponse.h>


#import <objc/runtime.h>
#import "UIViewController+Updating.h"
#import "UIView+ABTesting.h"


@import UIKit;

@interface ABController ()
@property (nonatomic, strong) OCFWebServer *webserver;
@end
@implementation ABController


void _ab_register_ab_notificaction(id self, SEL _cmd)
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"ab_notifaction") name:@"ABTestUpdate" object:nil];
}


void _ab_notificaction(id self, SEL _cmd)
{
    NSLog(@"UPDATE %@", self);
}

+(instancetype)sharedABController{
    static dispatch_once_t onceToken;
    static ABController *abController;
    dispatch_once(&onceToken, ^{
        
        OCFWebServer *server = [OCFWebServer new];
        
        [server addDefaultHandlerForMethod:@"GET"
                              requestClass:[OCFWebServerRequest class]
                              processBlock:^void(OCFWebServerRequest *request) {
                                  OCFWebServerResponse *response = [OCFWebServerDataResponse responseWithText:[[[UIApplication sharedApplication] keyWindow] listOfSubviews]];
                                  [request respondWith:response];
                              }];
        
        [server runWithPort:8080];
        
        
        abController = [[ABController alloc] initWithWebServer:server];
    });
    return abController;
}

-(instancetype)initWithWebServer:(OCFWebServer *)webserver
{
    self = [super init];
    if (self) {
        self.webserver = webserver;
    }
    return self;
}

+(NSDictionary *)attributesOfView:(UIView *)view
{
    NSMutableDictionary *dict = [@{} mutableCopy];

    dict[@"frame"] = NSStringFromCGRect(view.frame);
    
    return [dict copy];
}

+(void)load
{
    class_addMethod([UIViewController class], NSSelectorFromString(@"ab_notifaction"), (IMP)_ab_notificaction, "v@:");
    class_addMethod([UIViewController class], NSSelectorFromString(@"ab_register_notifaction"), (IMP)_ab_register_ab_notificaction, "v@:");
    
//    [self sharedABController];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.00001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sharedABController];
    });
    [UIViewController aspect_hookSelector:@selector(viewDidLoad)
                              withOptions:AspectPositionAfter
                               usingBlock:^(id<AspectInfo> aspectInfo) {
                                   UIViewController *vc = aspectInfo.instance;
                                   SEL selector = NSSelectorFromString(@"ab_register_notifaction");
                                   IMP imp = [vc methodForSelector:selector];
                                   void (*func)(id, SEL) = (void *)imp;
                                   func(vc, selector);
      } error:NULL];
    
    [UIViewController aspect_hookSelector:NSSelectorFromString(@"ab_notifaction")
                              withOptions:AspectPositionAfter
                               usingBlock:^(id<AspectInfo> aspectInfo) {
                                   UIViewController *vc = aspectInfo.instance;
                                   [vc updateViewWithAttributes:@{@"backgroundColor": [UIColor orangeColor]}];
    } error:NULL];
    
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ABTestUpdate" object:nil];
    });
}
@end
