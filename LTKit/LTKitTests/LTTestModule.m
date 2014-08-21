// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestModule.h"

#import "LTDevice.h"
#import "LTRandom.h"

@implementation LTTestModule

static const NSUInteger kTestingSeed = 1234;

- (void)configure {
  [super configure];

  [self bind:[UIApplication sharedApplication] toClass:[UIApplication class]];
  [self bind:[UIScreen mainScreen] toClass:[UIScreen class]];
  [self bind:[LTDevice currentDevice] toClass:[LTDevice class]];
  [self bind:[[LTRandom alloc] initWithSeed:kTestingSeed] toClass:[LTRandom class]];
}

@end
