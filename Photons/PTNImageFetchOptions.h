// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Types of available image delivery modes.
typedef NS_ENUM(NSInteger, PTNImageDeliveryMode) {
  /// Provide the image at the given size and highest quality available, but may take a long time to
  /// load. This is the default mode.
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
  /// Image is resized exactly to the requested size.
  PTNImageResizeModeExact,
  /// Image is efficiently resized, producing an image which is similar to or slightly larger than
  /// the requested size.
  PTNImageResizeModeFast
};

/// Value class containing options used while fetching images. Refer to a specific Photons source
/// documentation for information about which of these options are available for each specific
/// source. Unsupported options will be ignored.
@interface PTNImageFetchOptions : NSObject

/// Creates a new \c PTNImageFetchOptions with the given \c deliveryMode and \c resizeMode.
+ (instancetype)optionsWithDeliveryMode:(PTNImageDeliveryMode)deliveryMode
                             resizeMode:(PTNImageResizeMode)resizeMode;

/// Type of image delivery mode.
@property (readonly, nonatomic) PTNImageDeliveryMode deliveryMode;

/// Type of image resize mode.
@property (readonly, nonatomic) PTNImageResizeMode resizeMode;

@end

NS_ASSUME_NONNULL_END
