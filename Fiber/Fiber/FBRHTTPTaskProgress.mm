// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPTaskProgress.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBRHTTPTaskProgress

- (instancetype)init {
  return [self initWithProgress:0];
}

- (instancetype)initWithProgress:(double)progress {
  LTParameterAssert(progress >= 0 && progress <= 1, @"Progress must be in range [0, 1], got %g",
                    progress);
  if (self = [super init]) {
    _progress = progress;
  }
  return self;
}

- (instancetype)initWithResponseData:(nullable NSData *)responseData {
  if (self = [super init]) {
    _progress = 1;
    _responseData = responseData;
  }
  return self;
}

- (BOOL)hasStarted {
  return self.progress > 0;
}

- (BOOL)hasCompleted {
  return self.progress == 1;
}

@end

NS_ASSUME_NONNULL_END
