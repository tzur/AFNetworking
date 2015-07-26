// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNProgress.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNProgress

- (instancetype)initWithProgress:(NSNumber *)progress {
  if (self = [super init]) {
    // TODO:(yaron) check range of \c progress.
    _progress = progress;
  }
  return self;
}

- (instancetype)initWithResult:(id<NSObject>)result {
  if (self = [super init]) {
    _result = result;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNProgress *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return (self.progress || [self.progress isEqual:object.progress]) &&
      (self.result || [self.result isEqual:object.result]);
}

- (NSUInteger)hash {
  return self.progress.hash ^ self.result.hash;
}

- (NSString *)description {
  NSString *value = self.progress ? self.progress.stringValue : [self.result description];
  return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, value];
}

@end

NS_ASSUME_NONNULL_END
