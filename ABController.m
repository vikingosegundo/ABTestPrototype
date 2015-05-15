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
#import "UIColor+Creation.h"


@import UIKit;

@interface ABController ()
@property (nonatomic, strong) OCFWebServer *webserver;
@end
@implementation ABController


void _ab_register_ab_notificaction(id self, SEL _cmd)
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:NSSelectorFromString(@"ab_notifaction:")
                                                 name:@"ABTestUpdate"
                                               object:nil];
}


void _ab_notificaction(id self, SEL _cmd, id userObj)
{
    NSLog(@"UPDATE %@", self);
}

+(void)load
{
    class_addMethod([UIViewController class], NSSelectorFromString(@"ab_notifaction:"), (IMP)_ab_notificaction, "v@:@");
    class_addMethod([UIViewController class], NSSelectorFromString(@"ab_register_ab_notificaction"), (IMP)_ab_register_ab_notificaction, "v@:");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.00001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sharedABController];
    });
    
    [UIViewController aspect_hookSelector:@selector(viewDidLoad)
                              withOptions:AspectPositionAfter
                               usingBlock:^(id<AspectInfo> aspectInfo) {
                                   UIViewController *vc = aspectInfo.instance;
                                   SEL selector = NSSelectorFromString(@"ab_register_ab_notificaction");
                                   IMP imp = [vc methodForSelector:selector];
                                   void (*func)(id, SEL) = (void *)imp;func(vc, selector);
                               } error:NULL];
    
    [UIViewController aspect_hookSelector:NSSelectorFromString(@"ab_notifaction:")
                              withOptions:AspectPositionAfter
                               usingBlock:^(id<AspectInfo> aspectInfo, NSNotification *noti) {
                                   dispatch_async(dispatch_get_main_queue(),
                                                  ^{
                                                      UIViewController *vc = aspectInfo.instance;
                                                      [vc updateViewWithAttributes:@{@"backgroundColor": noti.object}];
                                                  });
                               } error:NULL];
}


-(instancetype)initWithWebServer:(OCFWebServer *)webserver
{
    self = [super init];
    if (self) {
        self.webserver = webserver;
        [self startServer];
        
        void (^registerNotification)(SEL, NSString *) = ^(SEL selector, NSString *name){
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:selector
                                                         name:name
                                                       object:nil];
        };
        registerNotification(@selector(startServer), UIApplicationDidBecomeActiveNotification);
        registerNotification(@selector(stopServer),  UIApplicationDidEnterBackgroundNotification);
    }
    return self;
}


+(instancetype)sharedABController
{
    static dispatch_once_t onceToken;
    static ABController *abController;
    dispatch_once(&onceToken, ^{
        
        OCFWebServer *server = [OCFWebServer new];
        
        OCFWebServerResponse *(^responseWithViewHierachy)(void) = ^OCFWebServerResponse* {
            return [OCFWebServerDataResponse responseWithText:[[[UIApplication sharedApplication] keyWindow] listOfSubviews]];
        };
        
        [server addHandlerForMethod:@"GET"
                               path:@"/"
                       requestClass:[OCFWebServerRequest class]
                       processBlock:^void(OCFWebServerRequest *request) {
                           [request respondWith:responseWithViewHierachy()];
                       }];
        
        [server addHandlerForMethod:@"GET"
                          pathRegex:@"/color/[0-9]{1,3}/[0-9]{1,3}/[0-9]{1,3}/$"
                       requestClass:[OCFWebServerRequest class]
                       processBlock:^(OCFWebServerRequest *request) {
                           NSArray *comps = request.URL.pathComponents;
                           
                           CGFloat (^colorComponent)(NSString *cc) = ^CGFloat(NSString *cc){
                               CGFloat c = [cc integerValue] / 255.0;
                               return c < 1.0 ? c : 1.0;
                           };
                           
                           UIColor *c = [UIColor colorWithRed:colorComponent(comps[2])
                                                        green:colorComponent(comps[3])
                                                         blue:colorComponent(comps[4])
                                                        alpha:1.0];
                           
                           [[NSNotificationCenter defaultCenter] postNotificationName:@"ABTestUpdate" object:c];
                           [request respondWith:responseWithViewHierachy()];
                       }];
        
        [server addHandlerForMethod:@"GET"
                               path:@"/screenshot/"
                       requestClass:[OCFWebServerRequest class]
                       processBlock:^void(OCFWebServerRequest *request) {
                           __block OCFWebServerResponse *response;
                           dispatch_sync(dispatch_get_main_queue(), ^{
                               UIImage *img = [[[UIApplication sharedApplication] keyWindow] ab_takeSnapshot];
                               NSData *pngData = UIImagePNGRepresentation(img);
                               response = [OCFWebServerDataResponse responseWithData:pngData
                                                                         contentType:@"image/png"];
                           });
                           [request respondWith:response];
                       }];
        
        
        [server addHandlerForMethod:@"GET"
                               path:@"/color/"
                       requestClass:[OCFWebServerRequest class]
                       processBlock:^(OCFWebServerRequest *request)
         {
             OCFWebServerResponse *response = [OCFWebServerDataResponse responseWithHTML:@"<form action=\"/color/\" method=\"post\" enctype=\"application/x-www-form-urlencoded\">\
                                               Select your favorite color:\
                                               <input type=\"color\" name=\"color\" onchange=\"this.form.submit()\">\
                                               </form>"];
             
             [request respondWith:response];
        }];
        
        
        [server addHandlerForMethod:@"POST"
                               path:@"/color/"
                       requestClass:[OCFWebServerURLEncodedFormRequest class]
                       processBlock:^(OCFWebServerRequest *request)
         {
             
             
             OCFWebServerURLEncodedFormRequest *formRequest = (OCFWebServerURLEncodedFormRequest *)request;
             
             NSString *colorString = [formRequest arguments][@"color"];
             NSString *html;
             
             if (colorString) {
                 UIColor *color = [UIColor colorFromHexString:colorString];
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"ABTestUpdate" object:color];
                 html = [NSString stringWithFormat:@"<form action=\"/color/\" method=\"post\" enctype=\"application/x-www-form-urlencoded\">\
                         Select your favorite color:\
                         <input type=\"color\" name=\"color\" value=\"%@\"onchange=\"this.form.submit()\">\
                         </form>", colorString];
             } else {
                 html = [NSString stringWithFormat:@"<form action=\"/color/\" method=\"post\" enctype=\"application/x-www-form-urlencoded\">\
                         Select your favorite color:\
                         <input type=\"color\" name=\"color\" value=\"#778899\"onchange=\"this.form.submit()\">\
                         </form>"];
             }
            
             OCFWebServerResponse *response = [OCFWebServerDataResponse responseWithHTML:html];
             [request respondWith:response];
         }];
        
        abController = [[ABController alloc] initWithWebServer:server];
    });
    return abController;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)startServer
{
    if(![self.webserver isRunning]){
        [self.webserver startWithPort:8080
                          bonjourName:^{
                              NSString *appName     = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                              if(appName){ appName  = [NSString stringWithFormat:@"%@: %@", [[UIDevice currentDevice] name],appName];
                              } else { appName      = [NSString stringWithFormat:@"%@", [[UIDevice currentDevice] name]]; }
                              return appName;
                          }()];
    }
}

-(void)stopServer
{
    if([self.webserver isRunning]){
        [self.webserver stop];
    }
}


@end
