// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "FBRHTTPTaskProgress.h"

#import "FBRCompare.h"
#import "FBRHTTPResponse.h"

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

- (instancetype)initWithResponse:(FBRHTTPResponse *)response {
  if (self = [super init]) {
    _progress = 1;
    _response = response;
  }
  return self;
}

- (BOOL)hasStarted {
  return self.progress > 0;
}

- (BOOL)hasCompleted {
  return self.progress == 1 && self.response;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(FBRHTTPTaskProgress *)object {
  if (object == self) {
    return YES;
  } else if (![object isKindOfClass:[self class]]) {
    return NO;
  }

  return self.progress == object.progress && FBRCompare(self.response, object.response);
}

- (NSUInteger)hash {
  return (NSUInteger)self.progress ^ self.response.hash;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, progress: %g, response: %@>", [self class], self,
          self.progress, self.response];
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (instancetype)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

@end

NS_ASSUME_NONNULL_END
