// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageFetchOptions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PTNImageFetchOptions

+ (instancetype)optionsWithDeliveryMode:(PTNImageDeliveryMode)deliveryMode
                             resizeMode:(PTNImageResizeMode)resizeMode {
  PTNImageFetchOptions *options = [[PTNImageFetchOptions alloc] init];
  options->_deliveryMode = deliveryMode;
  options->_resizeMode = resizeMode;
  return options;
}

- (BOOL)isEqual:(PTNImageFetchOptions *)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:self.class]) {
    return NO;
  }

  return self.deliveryMode == object.deliveryMode && self.resizeMode == object.resizeMode;
}

- (NSUInteger)hash {
  return self.deliveryMode ^ self.resizeMode;
}

@end

NS_ASSUME_NONNULL_END
