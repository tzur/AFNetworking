// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

namespace cv {
  class Mat;
}

/// Supported \c LTImage formats defining pixel's components memory layout and pixel's values.
typedef NS_ENUM(NSUInteger, LTImageFormat) {
  /// RGBA 8 bit unsigned char image format.
  LTImageFormatRGBA8U,
  /// RGBA 16 bit half float image format.
  LTImageFormatRGBA16F
};

/// Represents a CPU-based image. This class makes it easier to load an image to an accessible
/// bitmap, and export them back to disk or to parallel \c UIKit objects.
///
/// All images are represented in premultiplied alpha, if an alpha channel exists.
///
/// Loaded image is backed by \c cv::Mat. During the loading process, image can be converted to the
/// desired \c cv::Mat::type. Additionally at initialization it is possible to either use the input
/// image's color space or to convert it to a desired color space.
@interface LTImage : NSObject

/// Initializes with a given \c image. If \c image has an orientation different than
/// \c UIImageOrientationPortrait, \c image will be rotated to portrait orientation. \c colorSpace
/// property will be deduced from \c image's color space model and set as follows:
/// @code
/// | image color space model      | colorSpace property            |
/// |------------------------------+--------------------------------|
/// | kCGColorSpaceModelMonochrome | CGColorSpaceCreateDeviceGray() |
/// | kCGColorSpaceModelRGB        | CGColorSpaceCreateDeviceRGB()  |
/// | kCGColorSpaceModelIndexed    | CGColorSpaceCreateDeviceRGB()  |
/// | anything else                | Assertion failure              |
/// @endcode
- (instancetype)initWithImage:(UIImage *)image;

/// Initializes with the given \c image, \c imageFormat and \c colorSpace. The \c colorSpace will
/// be retained by this instance.
- (instancetype)initWithImage:(UIImage *)image imageFormat:(LTImageFormat)imageFormat
                   colorSpace:(CGColorSpaceRef)colorSpace;

/// Initializes with the given \c image. This instance will be loaded to \c images's color space if
/// \c loadColorSpace is \c YES. Otherwise this instance's color space will be deduced as described
/// in \c initWithImage: method.
- (instancetype)initWithImage:(UIImage *)image loadColorSpace:(BOOL)loadColorSpace;

/// Initializes with the given \c image and \c colorSpace as target color space the image will be
/// loaded to, which will be retained by this instance.
- (instancetype)initWithImage:(UIImage *)image targetColorSpace:(CGColorSpaceRef)colorSpace;

/// Initializes with a given \c cv::Mat. If \c copy is \c YES, \c mat will be cloned.
/// \c colorSpace property will be set to \c NULL.
- (instancetype)initWithMat:(const cv::Mat &)mat copy:(BOOL)copy;

/// Initializes with the given \c mat with color data in the given \c colorspace. If \c copy is
/// \c YES, the \c mat will be cloned. For unknown color space set \c colorSpace to \c NULL.
- (instancetype)initWithMat:(const cv::Mat &)mat copy:(BOOL)copy
                 colorSpace:(nullable CGColorSpaceRef)colorSpace;

- (instancetype)init NS_UNAVAILABLE;

/// Returns a \c UIImage representation of the current image with a scale of 1 pixel per point.
///
/// @note This is a memory intensive operation, as it requires creation of a new UIImage with the
/// contents of the current image.
- (UIImage *)UIImage;

/// Returns a \c UIImage representation of the current image with the given scale factor.
///
/// @param scale the scale factor to create the image with.
/// @param copyData if \c YES, the underlying image data will be duplicated. Otherwise, the image
/// will be backed by this \c LTImage data, and will become invalid when this instance will be
/// destroyed.
///
/// @note This is a memory intensive operation, as it requires creation of a new UIImage with the
/// contents of the current image.
- (UIImage *)UIImageWithScale:(CGFloat)scale copyData:(BOOL)copyData;

/// Writes the image to the given path. Returns \c YES if succeeded and sets error to \c nil,
/// otherwise error is populated with an error object.
- (BOOL)writeToPath:(NSString *)path error:(NSError **)error;

/// Returns the color space of the image. \c NULL means the color space is unknown.
- (nullable CGColorSpaceRef)colorSpace NS_RETURNS_INNER_POINTER CF_RETURNS_NOT_RETAINED;

/// Size of the image.
@property (readonly, nonatomic) CGSize size;

/// Image contents.
@property (readonly, nonatomic) const cv::Mat &mat;

/// Color space of the image. \c NULL means the color space is unknown.
@property (readonly, nonatomic, nullable) CGColorSpaceRef colorSpace;

@end

NS_ASSUME_NONNULL_END
