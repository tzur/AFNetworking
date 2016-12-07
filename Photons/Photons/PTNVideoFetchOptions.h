// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Types of available video delivery modes.
typedef NS_ENUM(NSInteger, PTNVideoDeliveryMode) {
  /// Automatically determines which quality of video data to provide based on the request and
  /// current conditions.
  PTNVideoDeliveryModeAutomatic = 0,
  /// provide only the highest quality video available.
  PTNVideoDeliveryModeHighQualityFormat = 1,
  /// Provide a video of moderate quality unless a higher quality version is available.
  PTNVideoDeliveryModeMediumQualityFormat = 2,
  /// Provide whatever quality of video can be most quickly deilvered.
  PTNVideoDeliveryModeFastFormat = 3
};

/// Value class containing options used while fetching videos. Refer to a specific Photons source
/// documentation for information about which of these options are available for each specific
/// source. Unsupported options will be ignored.
@interface PTNVideoFetchOptions : LTValueObject

/// Creates a new \c PTNVideoFetchOptions with the given \c deliveryMode.
+ (instancetype)optionsWithDeliveryMode:(PTNVideoDeliveryMode)deliveryMode;

/// Deilvery mode specifying the requested video quality and delivery priority.
@property (readonly, nonatomic) PTNVideoDeliveryMode deliveryMode;

@end

NS_ASSUME_NONNULL_END
