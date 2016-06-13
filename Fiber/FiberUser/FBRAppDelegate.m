// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRAppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBRAppDelegate

- (BOOL)application:(UIApplication __unused *)application
    didFinishLaunchingWithOptions:(nullable NSDictionary __unused *)launchOptions {
  self.window = [[UIWindow alloc] init];
  self.window.rootViewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
  self.window.rootViewController.view.backgroundColor = [UIColor whiteColor];
  [self.window makeKeyAndVisible];
  return YES;
}

@end

NS_ASSUME_NONNULL_END
