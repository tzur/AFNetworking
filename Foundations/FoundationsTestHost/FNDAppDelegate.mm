// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FNDAppDelegate.h"

@implementation FNDAppDelegate

- (BOOL)application:(UIApplication __unused *)application
    didFinishLaunchingWithOptions:(NSDictionary __unused *)launchOptions {
  self.window = [[UIWindow alloc] init];
  self.window.rootViewController = [[UIViewController alloc] init];
  [self.window makeKeyAndVisible];
  return YES;
}

@end
