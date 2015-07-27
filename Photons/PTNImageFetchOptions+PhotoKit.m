// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageFetchOptions+PhotoKit.h"

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@implementation PTNImageFetchOptions (PhotoKit)

- (PHImageRequestOptions *)photoKitOptions {
  PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];

  options.deliveryMode = (PHImageRequestOptionsDeliveryMode)self.deliveryMode;
  options.resizeMode = (PHImageRequestOptionsResizeMode)self.resizeMode;

  return options;
}

@end

NS_ASSUME_NONNULL_END
