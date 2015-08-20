// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTAppDelegate.h"

#import <LTKit/LTDefaultModule.h>

static BOOL LTRunningApplicationTests() {
  NSDictionary *environment = [[NSProcessInfo processInfo] environment];
  return environment[@"XCInjectBundle"] != nil;
}

@implementation LTAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  if (LTRunningApplicationTests()) {
    return YES;
  }
  
  JSObjectionInjector *injector = [JSObjection createInjector:[[LTDefaultModule alloc] init]];
  [JSObjection setDefaultInjector:injector];
  return YES;
}

@end
