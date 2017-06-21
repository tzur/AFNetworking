// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Types of available AVAsset delivery modes.
typedef NS_ENUM(NSInteger, PTNAVAssetDeliveryMode) {
  /// Automatically determines which quality of \c AVAsset data to provide based on the request and
  /// current conditions.
  PTNAVAssetDeliveryModeAutomatic = 0,
  /// provide only the highest quality \c AVAsset available.
  PTNAVAssetDeliveryModeHighQualityFormat = 1,
  /// Provide an \c AVAsset of moderate quality unless a higher quality version is available.
  PTNAVAssetDeliveryModeMediumQualityFormat = 2,
  /// Provide whatever quality of \c AVAsset can be most quickly deilvered.
  PTNAVAssetDeliveryModeFastFormat = 3
};

/// Value class containing options used while fetching \c AVAssets. Refer to a specific Photons
/// source documentation for information about which of these options are available for each
/// specific source. Unsupported options will be ignored.
@interface PTNAVAssetFetchOptions : LTValueObject

/// Creates a new \c PTNAVAssetFetchOptions with the given \c deliveryMode.
+ (instancetype)optionsWithDeliveryMode:(PTNAVAssetDeliveryMode)deliveryMode;

/// Deilvery mode specifying the requested \c AVAsset quality and delivery priority.
@property (readonly, nonatomic) PTNAVAssetDeliveryMode deliveryMode;

@end

NS_ASSUME_NONNULL_END
