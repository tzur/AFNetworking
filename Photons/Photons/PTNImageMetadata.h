// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Nir Bruner.

#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/// Image orientations. Values are identical in meaning as the \c UIImageOrientation with the
/// similar name.
typedef NS_ENUM(NSUInteger, PTNImageOrientation) {
  PTNImageOrientationUp,
  PTNImageOrientationDown,
  PTNImageOrientationLeft,
  PTNImageOrientationRight,
  PTNImageOrientationUpMirrored,
  PTNImageOrientationDownMirrored,
  PTNImageOrientationLeftMirrored,
  PTNImageOrientationRightMirrored
};

/// Object that holds, parses and manipulates image metadata.
/// This object is immutable. For a mutable version, see \c PTNMutableImageMetadata.
@interface PTNImageMetadata : NSObject <NSCopying, NSMutableCopying>

/// Initializes with empty metadata.
- (instancetype)init;

/// Initializes with the metadata of the image at the given \c url. If any error occurs, \c error
/// will be non \c nil, and this \c PTNImageMetadata will be empty.
///
/// @note Metadata that is not supported by \c PTNImageMetadata is not discarded, but instead
/// remains as-is, and will be returned as part of \c metadataDictionary.
- (instancetype)initWithImageURL:(NSURL *)url error:(NSError **)error;

/// Initializes with identical contents as the given \c metadata.
///
/// @note Metadata that is not supported by \c PTNImageMetadata is not discarded, but instead
/// remains as-is, and will be returned as part of \c metadataDictionary.
- (instancetype)initWithMetadata:(PTNImageMetadata *)metadata;

/// Initializes with identical contents as the given metadata dictionary.
///
/// @note Metadata that is not supported by \c PTNImageMetadata is not discarded, but instead
/// remains as-is, and will be returned as part of \c metadataDictionary.
- (instancetype)initWithMetadataDictionary:(NSDictionary *)dictionary;

/// Manufacturer of the camera.
@property (readonly, nonatomic, nullable) NSString *make;

/// Model name or number of the camera.
@property (readonly, nonatomic, nullable) NSString *model;

/// Name and version of the software used to generate the image.
@property (readonly, nonatomic, nullable) NSString *software;

/// Timestamp of image creation.
@property (readonly, nonatomic, nullable) NSDate *originalTime;

/// Timestamp when the image was stored as digital data.
@property (readonly, nonatomic, nullable) NSDate *digitizedTime;

/// Location where the image was captured.
@property (readonly, nonatomic, nullable) CLLocation *location;

/// Reference for interpreting the value of \c headingDirection. \c "T" means True heading, \c "M"
/// means Magnetic heading, and \c nil means unknown.
@property (readonly, nonatomic, nullable) NSString *headingReference;

/// Direction the camera was pointing when the image was captured.
@property (readonly, nonatomic) CLLocationDirection headingDirection;

/// Pixel size of the image. Returns \c CGSizeNull if not set.
///
/// @note this value depends on the value of \c orientation. Specifically, changing \c orientation
/// between portrait and landscape will cause \c size.width and \c size.height to switch.
@property (readonly, nonatomic) CGSize size;

/// Orientation of the image.
@property (readonly, nonatomic) PTNImageOrientation orientation;

/// Returns the metadata contents of this \c PTNImageMetadata in the form of a dictionary, that can
/// be used with methods of frameworks such as \c PhotoKit or \c AssetLibrary.
@property (readonly, nonatomic) NSDictionary *metadataDictionary;

@end

/// Mutable variant of \c PTNImageMetadata. In addition to being able to read values, new values can
/// be set for all properties. Setting a property to \c nil will remove its value entirely.
@interface PTNMutableImageMetadata : PTNImageMetadata

/// Manufacturer of the camera.
@property (readwrite, nonatomic, nullable) NSString *make;

/// Model name or number of the camera.
@property (readwrite, nonatomic, nullable) NSString *model;

/// Name and version of the software used to generate the image.
@property (readwrite, nonatomic, nullable) NSString *software;

/// Timestamp of image creation.
@property (readwrite, nonatomic, nullable) NSDate *originalTime;

/// Timestamp when the image was stored as digital data.
@property (readwrite, nonatomic, nullable) NSDate *digitizedTime;

/// Location where the image was captured.
@property (readwrite, nonatomic, nullable) CLLocation *location;

/// Sets \c headingReference and \c headingDirection from the given \c heading.
- (void)setHeading:(nullable CLHeading *)heading;

/// Pixel size of the image. Use \c CGSizeNull to clear this value.
///
/// @note this value depends on the value of \c orientation. Specifically, changing \c orientation
/// between portrait and landscape will cause \c size.width and \c size.height to switch.
@property (readwrite, nonatomic) CGSize size;

/// Orientation of the image.
@property (readwrite, nonatomic) PTNImageOrientation orientation;

@end

NS_ASSUME_NONNULL_END
