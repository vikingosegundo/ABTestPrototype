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
#import "UIViewController+TopViewController.h"
#import "UIView+ABTesting.h"
#import "UIView+Extra.h"
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
  class_addMethod([UIViewController class], NSSelectorFromString(@"ab_register_ab_notificaction"), (IMP)_ab_register_ab_notificaction, "v@:v");
  
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
                               dispatch_async(dispatch_get_main_queue(),^{
                                 UIViewController *vc = aspectInfo.instance;
                                 if (vc.isViewLoaded && vc.view.window) {
                                   [vc updateViewWithAttributes:@{@"backgroundColor": noti.object}];
                                 }
                               });
                             } error:NULL];
}


+(instancetype)sharedABController
{
  static dispatch_once_t onceToken;
  static ABController *abController;
  dispatch_once(&onceToken, ^{
    abController = [[ABController alloc] initWithWebServer:[self attachHandlersToServer:[OCFWebServer new]]];
  });
  return abController;
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


-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)startServer
{
  if(![self.webserver isRunning]){
    [self.webserver startWithPort:8080
                      bonjourName:[self nameForBonjourAnnouncement]];
  }
}


-(void)stopServer
{
  if([self.webserver isRunning]){
    [self.webserver stop];
  }
}


#pragma mark - helper

- (NSString *)nameForBonjourAnnouncement
{
  NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
  if(appName){
    appName = [NSString stringWithFormat:@"%@: %@", [[UIDevice currentDevice] name],appName];
  } else {
    appName = [NSString stringWithFormat:@"%@", [[UIDevice currentDevice] name]]; }
  return appName;
}


+(NSString *)htmlForColorRespondsWithColorString:(NSString *)hexColorString
                                      jqueryPath:(NSString *)jqueryPath
                                      imageWidth:(CGFloat)imgWidth
                                     imageHeight:(CGFloat)imgheight
{
  
  __block NSString *colorString = hexColorString;

  dispatch_sync(dispatch_get_main_queue(), ^{
    if (!colorString) {
      UIView *v =[UIViewController topViewController].view;
      colorString = [v.backgroundColor hexString];
    }
    NSLog(@"%@", colorString);
  });
  
  NSString *html = [NSString stringWithFormat:@"<html><head><script type='text/javascript' src='%@'></script></head><body><form action=\"/color/\" method=\"post\" enctype=\"application/x-www-form-urlencoded\">\
                    Select your favorite color:\
                    <input type=\"color\" name=\"color\" value=\"%@\"onchange=\"this.form.submit()\">\
                    </form><div id=\"C\" style=\"width:%f; height:%f\"><img width=\"%f\" height=\"%f\"  src=\"/screenshot/\"></div><script type='text/javascript'>\
                    $(window).load(function(){\
                    $(document).ready(function(e) {\
                    $('#C').click(function(e) {\
                    var posX = $(this).position().left,posY = $(this).position().top;\
                    $.post('/viewatposition/', {'x':(e.pageX - posX), 'y':(e.pageY - posY)}, function(result){\
                    alert(result);\
                    });\
                    });\
                    });\
                    });\
                    </script></body></html>",jqueryPath, colorString,imgWidth, imgheight,imgWidth, imgheight];
  return html;
}


+ (OCFWebServer *)attachHandlersToServer:(OCFWebServer *)server
{
  NSString *jqueryPath = [[NSBundle mainBundle] pathForResource:@"jquery" ofType:@"js"];
  CGFloat imgWidth = [[UIScreen mainScreen] bounds].size.width ;
  CGFloat imgheight = [[UIScreen mainScreen] bounds].size.height;
  
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
                         path:jqueryPath
                 requestClass:[OCFWebServerRequest class]
                 processBlock:^(OCFWebServerRequest *request) {
                   NSData *jqfile = [NSData dataWithContentsOfFile:jqueryPath];
                   OCFWebServerResponse *response = [OCFWebServerDataResponse responseWithData:jqfile contentType:@"application/javascript"];
                   [request respondWith:response];
                 }];
  
  [server addHandlerForMethod:@"POST"
                         path:@"/viewatposition/"
                 requestClass:[OCFWebServerURLEncodedFormRequest class]
                 processBlock:^(OCFWebServerRequest *request) {
                   
                   OCFWebServerURLEncodedFormRequest *formRequest = (OCFWebServerURLEncodedFormRequest *)request;
                   id arg = [formRequest arguments];
                   NSLog(@"%@", arg);
                   CGFloat x = [arg[@"x"] floatValue];
                   CGFloat y = [arg[@"y"] floatValue];
                   NSLog(@"%f, %f", x,y);
                   
                   UIView *v =[[UIApplication sharedApplication].keyWindow.rootViewController.view findTopMostViewForPoint:CGPointMake(x, y)];
                   OCFWebServerResponse *response = [OCFWebServerDataResponse responseWithText:[NSString stringWithFormat:@"%@", v]];
                   [request respondWith:response];
                 }];
  
  [server addHandlerForMethod:@"GET"
                         path:@"/color/"
                 requestClass:[OCFWebServerRequest class]
                 processBlock:^(OCFWebServerRequest *request) {
                   NSString *html = [self htmlForColorRespondsWithColorString:nil
                                                                   jqueryPath:jqueryPath
                                                                   imageWidth:imgWidth
                                                                  imageHeight:imgheight];
                   
                   OCFWebServerResponse *response = [OCFWebServerDataResponse responseWithHTML:html];
                   [request respondWith:response];
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
  
  [server addHandlerForMethod:@"POST"
                         path:@"/color/"
                 requestClass:[OCFWebServerURLEncodedFormRequest class]
                 processBlock:^(OCFWebServerRequest *request) {
                   
                   
                   OCFWebServerURLEncodedFormRequest *formRequest = (OCFWebServerURLEncodedFormRequest *)request;
                   
                   NSString *colorString = [formRequest arguments][@"color"];
                   if (colorString) {
                     UIColor *color = [UIColor colorFromHexString:colorString];
                     [[NSNotificationCenter defaultCenter] postNotificationName:@"ABTestUpdate" object:color];
                     
                   }
                   NSString *html = [self htmlForColorRespondsWithColorString:colorString
                                                                   jqueryPath:jqueryPath
                                                                   imageWidth:imgWidth
                                                                  imageHeight:imgheight];
                   
                   OCFWebServerResponse *response = [OCFWebServerDataResponse responseWithHTML:html];
                   [request respondWith:response];
                 }];
  
  return server;
}

@end
