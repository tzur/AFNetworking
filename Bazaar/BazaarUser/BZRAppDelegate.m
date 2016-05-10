// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRAppDelegate.h"

@implementation BZRAppDelegate

- (BOOL)application:(UIApplication __unused *)application
    didFinishLaunchingWithOptions:(NSDictionary __unused *)launchOptions {
  self.window = [[UIWindow alloc] init];
  self.window.rootViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
  self.window.rootViewController.view.backgroundColor = [UIColor whiteColor];
  [self.window makeKeyAndVisible];
  return YES;
}

@end
