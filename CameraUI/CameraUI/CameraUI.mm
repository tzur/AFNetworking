// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import "CameraUI.h"

#import <Camera/Camera.h>
#import <LTKit/LTCGExtensions.h>

@implementation CameraUI

- (void)hello {
  NSLog(@"%@", self.helloString);
  CGRoundRect(CGRectMake(0, 0, 1, 2));

  RACSignal *signal = [RACSignal return:@"signal"];
  [[signal logAll] subscribeCompleted:^{}];

  Camera *camera = [[Camera alloc] init];
  NSLog(@"%@", camera.helloString);
}

- (NSString *)helloString {
  return @"Hello World!";
}

@end
