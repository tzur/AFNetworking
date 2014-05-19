// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTAppDelegate.h"

#import "LTKitUserModule.h"

@implementation LTAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  JSObjectionInjector *injector = [JSObjection createInjector:[[LTKitUserModule alloc] init]];
  [JSObjection setDefaultInjector:injector];
  return YES;
}

@end
