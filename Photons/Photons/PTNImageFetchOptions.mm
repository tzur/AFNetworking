// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageFetchOptions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNImageFetchOptions

- (instancetype)init {
  return [self initWithDeliveryMode:PTNImageDeliveryModeHighQuality
                         resizeMode:PTNImageResizeModeExact includeMetadata:NO];
}

- (instancetype)initWithDeliveryMode:(PTNImageDeliveryMode)deliveryMode
                          resizeMode:(PTNImageResizeMode)resizeMode
                     includeMetadata:(BOOL)includeMetadata {
  if (self = [super init]) {
    _deliveryMode = deliveryMode;
    _resizeMode = resizeMode;
    _includeMetadata = includeMetadata;
  }
  return self;
}

+ (instancetype)options {
  return [[PTNImageFetchOptions alloc] init];
}

+ (instancetype)optionsWithDeliveryMode:(PTNImageDeliveryMode)deliveryMode
                             resizeMode:(PTNImageResizeMode)resizeMode
                        includeMetadata:(BOOL)includeMetadata {
  return [[PTNImageFetchOptions alloc] initWithDeliveryMode:deliveryMode resizeMode:resizeMode
                                            includeMetadata:includeMetadata];
}

@end

NS_ASSUME_NONNULL_END
