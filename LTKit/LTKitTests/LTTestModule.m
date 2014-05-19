// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestModule.h"

#import "LTDevice.h"

@implementation LTTestModule

- (id)init {
  if (self = [super init]) {
    self.uiScreen = [OCMockObject partialMockForObject:[UIScreen mainScreen]];
    self.uiDevice = [OCMockObject partialMockForObject:[UIDevice currentDevice]];
    self.ltDevice = [OCMockObject partialMockForObject:[LTDevice currentDevice]];
    self.uiApplication = [OCMockObject partialMockForObject:[UIApplication sharedApplication]];
  }
  return self;
}

- (void)configure {
  [self bind:self.uiScreen toClass:[UIScreen class]];
  [self bind:self.uiDevice toClass:[UIDevice class]];
  [self bind:self.ltDevice toClass:[LTDevice class]];
  [self bind:self.uiApplication toClass:[UIApplication class]];
}

@end
