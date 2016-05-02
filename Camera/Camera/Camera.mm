// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "Camera.h"

#import <LTKit/LTCGExtensions.h>

@implementation Camera

- (void)hello {
  NSLog(@"%@", self.helloString);
  CGRoundRect(CGRectMake(0, 0, 1, 2));

  RACSignal *signal = [RACSignal return:@"signal"];
  [[signal logAll] subscribeCompleted:^{}];
}

- (NSString *)helloString {
  return @"Hello World!";
}

@end
