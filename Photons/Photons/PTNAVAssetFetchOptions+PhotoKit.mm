// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "PTNAVAssetFetchOptions+PhotoKit.h"

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@implementation PTNAVAssetFetchOptions (PhotoKit)

- (PHVideoRequestOptions *)photoKitOptions {
  PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];

  options.deliveryMode = (PHVideoRequestOptionsDeliveryMode)self.deliveryMode;
  options.networkAccessAllowed = YES;

  return options;
}

@end

NS_ASSUME_NONNULL_END
