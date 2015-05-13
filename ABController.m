    //
//  ABController.m
//  ABTestPrototype
//
//  Created by Manuel Meyer on 12.05.15.
//  Copyright (c) 2015 Manuel Meyer. All rights reserved.
//

#import "ABController.h"

#import <Aspects/Aspects.h>
#import <OCFWeb/OCFWebApplication.h>
#import <OCFWeb/OCFRequest.h>


#import <objc/runtime.h>
#import "UIViewController+Updating.h"
#import "UIView+ABTesting.h"


@import UIKit;

@interface ABController ()
@property (nonatomic, strong) OCFWebApplication *webApp;
@end
@implementation ABController


void _ab_register_ab_notificaction(id self, SEL _cmd)
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:NSSelectorFromString(@"ab_notifaction:") name:@"ABTestUpdate" object:nil];
}


void _ab_notificaction(id self, SEL _cmd, id userObj)
{
    NSLog(@"UPDATE %@", self);
}

+(instancetype)sharedABController{
    static dispatch_once_t onceToken;
    static ABController *abController;
    dispatch_once(&onceToken, ^{
        
        OCFWebApplication *app = [OCFWebApplication new];
        
        // Add a handler for GET requests

        
        app[@"GET"][@"/color/:color/"]  = ^(OCFRequest *request) {
            // request contains a lot of properties which describe the incoming request.
            // Respond to the request:
            [[UIApplication sharedApplication].keyWindow.rootViewController.view setBackgroundColor:[UIColor greenColor]];
            request.respondWith(@"Hello World");
        };
        
        app[@"GET"][@"/"]  = ^(OCFRequest *request) {
            request.respondWith(@"Hello World");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ABTestUpdate" object:[UIColor greenColor]];
            
        };
        app[@"GET"][@"/countries/:country/states/:state/cities/:city/bla/:b/"] = ^(OCFRequest *request) {
            request.respondWith([request.parameters description]);
        };
        
        [app run];
        
        
        abController = [[ABController alloc] initWithWebApp:app];
    });
    return abController;
}

-(instancetype)initWithWebApp:(OCFWebApplication *)webApp
{
    self = [super init];
    if (self) {
        self.webApp = webApp;
    }
    return self;
}


+(void)load
{
    class_addMethod([UIViewController class], NSSelectorFromString(@"ab_notifaction:"), (IMP)_ab_notificaction, "v@:@");
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
    
    [UIViewController aspect_hookSelector:NSSelectorFromString(@"ab_notifaction:")
                              withOptions:AspectPositionAfter
                               usingBlock:^(id<AspectInfo> aspectInfo, NSNotification *noti) {
                                   UIViewController *vc = aspectInfo.instance;
                                   [vc updateViewWithAttributes:@{@"backgroundColor": noti.object}];
    } error:NULL];
    
    
    
}
@end
