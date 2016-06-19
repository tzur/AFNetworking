// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "PTNImageFetchOptions+PhotoKit.h"

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PTNImageFetchOptions ()

/// Delivery mode translated to PhotoKit values.
@property (readonly, nonatomic) PHImageRequestOptionsDeliveryMode photoKitDeliveryMode;

/// Resize mode translated to PhotoKit values.
@property (readonly, nonatomic) PHImageRequestOptionsResizeMode photoKitResizeMode;

@end

@implementation PTNImageFetchOptions (PhotoKit)

- (PHImageRequestOptions *)photoKitOptions {
  PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];

  options.deliveryMode = self.photoKitDeliveryMode;
  options.resizeMode = self.photoKitResizeMode;
  options.networkAccessAllowed = YES;

  return options;
}

- (PHImageRequestOptionsDeliveryMode)photoKitDeliveryMode {
  switch (self.deliveryMode) {
    case PTNImageDeliveryModeHighQuality:
      return PHImageRequestOptionsDeliveryModeHighQualityFormat;
    case PTNImageDeliveryModeFast:
      return PHImageRequestOptionsDeliveryModeFastFormat;
    case PTNImageDeliveryModeOpportunistic:
      return PHImageRequestOptionsDeliveryModeOpportunistic;
  }
}

- (PHImageRequestOptionsResizeMode)photoKitResizeMode {
  switch (self.resizeMode) {
    case PTNImageResizeModeExact:
      return PHImageRequestOptionsResizeModeExact;
    case PTNImageResizeModeFast:
      // According to the PhotoKit development team, as discovered in WWDC2016, the best results in
      // terms of performance are achieved with \c PHImageRequestOptionsResizeModeNone.
      return PHImageRequestOptionsResizeModeNone;
  }
}

@end

NS_ASSUME_NONNULL_END
