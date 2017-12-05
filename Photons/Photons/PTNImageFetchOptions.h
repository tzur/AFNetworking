// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

/// Types of available image delivery modes.
typedef NS_ENUM(NSInteger, PTNImageDeliveryMode) {
  /// Provide the image at the given size and highest quality available, but may take a long time to
  /// load.
  PTNImageDeliveryModeHighQuality,
  /// Provide an image quickly, which can be of low-quality.
  PTNImageDeliveryModeFast,
  /// Provide one or more results in order to balance image quality and responsiveness. In this
  /// option a low-quality image(s) may be provided prior to providing a high-quality one.
  PTNImageDeliveryModeOpportunistic
};

/// Type of available methods to resize an image if the requested image size is not equal to the
/// size of the original image.
typedef NS_ENUM(NSInteger, PTNImageResizeMode) {
  /// Image is resized exactly to the requested size or to the original image size. (The smaller of
  /// the two).
  PTNImageResizeModeExact,
  /// Image is efficiently resized, producing an image which is similar to or slightly larger than
  /// the requested size.
  PTNImageResizeModeFast
};

/// Value class containing options used while fetching images. Refer to a specific Photons source
/// documentation for information about which of these options are available for each specific
/// source. Unsupported options will be ignored.
@interface PTNImageFetchOptions : LTValueObject

/// Initializes with \c PTNImageDeliveryModeHighQuality for \c deliveryMode,
/// \c PTNImageResizeModeExact for \c resizeMode and \c NO for \c includeMetadata.
- (instancetype)init;

/// Creates a new \c PTNImageFetchOptions with \c PTNImageDeliveryModeHighQuality for
/// \c deliveryMode, \c PTNImageResizeModeExact for \c resizeMode and \c NO for \c includeMetadata.
+ (instancetype)options;

/// Creates a new \c PTNImageFetchOptions with the given \c deliveryMode, \c resizeMode and
/// \c includeMetadata.
+ (instancetype)optionsWithDeliveryMode:(PTNImageDeliveryMode)deliveryMode
                             resizeMode:(PTNImageResizeMode)resizeMode
                        includeMetadata:(BOOL)includeMetadata;

/// Type of image delivery mode.
@property (readonly, nonatomic) PTNImageDeliveryMode deliveryMode;

/// Type of image resize mode.
@property (readonly, nonatomic) PTNImageResizeMode resizeMode;

/// Whether metadata should be fetched along with the image. When this option is \c YES, other
/// options may be ignored since in some cases this requires fetching the original, full-sized
/// image.
@property (readonly, nonatomic) BOOL includeMetadata;

@end

NS_ASSUME_NONNULL_END
