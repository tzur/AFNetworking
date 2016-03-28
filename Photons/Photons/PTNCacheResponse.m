// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import "PTNCacheResponse.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNCacheResponse

- (instancetype)initWithData:(nullable id<NSObject>)data info:(nullable id<NSObject>)info {
  if (self = [super init]) {
    _data = data;
    _info = info;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(PTNCacheResponse *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return [self compare:self.data with:object.data] && [self compare:self.info with:object.info];
}

- (BOOL)compare:(nullable id)first with:(nullable id)second {
  return first == second || [first isEqual:second];
}

- (NSUInteger)hash {
  return self.data.hash ^ self.info.hash;
}

@end

NS_ASSUME_NONNULL_END
