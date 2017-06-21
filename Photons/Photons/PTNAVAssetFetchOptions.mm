// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNAVAssetFetchOptions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNAVAssetFetchOptions

+ (instancetype)optionsWithDeliveryMode:(PTNAVAssetDeliveryMode)deliveryMode {
  PTNAVAssetFetchOptions *options = [[PTNAVAssetFetchOptions alloc] init];
  options->_deliveryMode = deliveryMode;
  return options;
}

@end

NS_ASSUME_NONNULL_END
