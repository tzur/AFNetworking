// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

namespace cv {
  class Mat;
}

/// Possible depth for \c LTImage.
typedef NS_ENUM(NSUInteger, LTImageDepth) {
  LTImageDepthGrayscale,
  LTImageDepthRGBA
};

/// @class LTImage
///
/// Represents a CPU-based image. This class makes it easier to load an image to an accessible
/// bitmap, and export them back to disk  or to parallel \c UIKit objects.
///
/// All images are represented in premultiplied alpha, if an alpha channel exists.
@interface LTImage : NSObject

/// Initializes the image with a given \c UIImage object. If the image has an orientation different
/// than \c UIImageOrientationPortrait, the image will be rotated to have this orientation. The
/// given \c image cannot be \c nil.
- (instancetype)initWithImage:(UIImage *)image;

/// Designated initializer: initializes with a given \c cv::Mat object. If \c copy is \c YES, the
/// \c mat will be duplicated.
- (instancetype)initWithMat:(const cv::Mat &)mat copy:(BOOL)copy;

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

/// Size of the image.
@property (readonly, nonatomic) CGSize size;

/// Image contents.
@property (readonly, nonatomic) const cv::Mat &mat;

/// Depth of the image.
@property (readonly, nonatomic) LTImageDepth depth;

@end
