// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTKitUserModule.h"

#import <LTKit/LTKit.h>

@implementation LTKitUserModule

- (void)configure {
  [self bind:[UIScreen mainScreen] toClass:[UIScreen class]];
  [self bind:[UIDevice currentDevice] toClass:[UIDevice class]];
  [self bind:[LTDevice currentDevice] toClass:[LTDevice class]];
  [self bind:[UIApplication sharedApplication] toClass:[UIApplication class]];
  [self bind:[NSFileManager defaultManager] toClass:[NSFileManager class]];
  [self bind:[LTFileManager sharedManager] toClass:[LTFileManager class]];
}

@end
