// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBrushRandomState.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTBrushRandomState

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithStates:(NSDictionary *)states {
  LTParameterAssert(states);
  if (self = [super init]) {
    _states = [states copy];
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
