// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

NS_ASSUME_NONNULL_BEGIN

namespace cv {
  class Mat;
}

@class LTTexture, UIImage;

/// Category for conveniently creating \c UIImage objects from buffers such as \c cv::Mat and
/// textures.
@interface UIImage (Factory)

/// Returns \c UIImage representation of the given \c texture.
///
/// @note This is a memory intensive operation, as it requires creation of a new \c UIImage with the
/// contents of the given \c texture.
+ (UIImage *)lt_imageWithTexture:(LTTexture *)texture;

/// Returns \c UIImage representation of the given \c mat.
///
/// @note This is a memory intensive operation, as it requires creation of a new UIImage with the
/// contents of the given \c mat.
+ (UIImage *)lt_imageWithMat:(const cv::Mat &)mat;

@end

NS_ASSUME_NONNULL_END
