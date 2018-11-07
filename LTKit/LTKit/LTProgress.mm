// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "LTProgress.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTProgress

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

- (instancetype)initWithResult:(id<NSObject>)result {
  if (self = [super init]) {
    _progress = 1;
    _result = result;
  }
  return self;
}

+ (instancetype)progressWithProgress:(double)progress {
  return [[LTProgress alloc] initWithProgress:progress];
}

+ (instancetype)progressWithResult:(id<NSObject>)result {
  return [[LTProgress alloc] initWithResult:result];
}

- (LTProgress *)map:(NS_NOESCAPE id(^)(id<NSObject> _Nonnull object))block {
  if (!self.result) {
    return self;
  }

  return [LTProgress progressWithResult:block(nn(self.result))];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
