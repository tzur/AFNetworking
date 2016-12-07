// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNVideoFetchOptions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNVideoFetchOptions

+ (instancetype)optionsWithDeliveryMode:(PTNVideoDeliveryMode)deliveryMode {
  PTNVideoFetchOptions *options = [[PTNVideoFetchOptions alloc] init];
  options->_deliveryMode = deliveryMode;
  return options;
}

@end

NS_ASSUME_NONNULL_END
