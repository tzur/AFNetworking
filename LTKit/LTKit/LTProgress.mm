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

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTProgress *)object {
  if (object == self) {
    return YES;
  } else if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  return self.progress == object.progress &&
      (self.result == object.result || [self.result isEqual:object.result]);
}

- (NSUInteger)hash {
  return @(self.progress).hash ^ self.result.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, progress: %g, result: %@>", [self class], self,
          self.progress, self.result];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
