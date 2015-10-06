// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTDefaultModule.h"

#import <LTKit/LTRandom.h>

@implementation LTDefaultModule

- (void)configure {
  [self bind:[UIScreen mainScreen] toClass:[UIScreen class]];
  [self bind:[UIDevice currentDevice] toClass:[UIDevice class]];
  [self bind:[UIApplication sharedApplication] toClass:[UIApplication class]];
  [self bind:[NSFileManager defaultManager] toClass:[NSFileManager class]];
  [self bindBlock:^id(JSObjectionInjector __unused *context) {
    return [[LTRandom alloc] init];
  } toClass:[LTRandom class]];
}

@end
