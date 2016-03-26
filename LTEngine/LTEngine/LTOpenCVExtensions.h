// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOpenCVCore.h"
#import "LTOpenCVHalfFloat.h"
#import "LTVector.h"

/// Converts the given \c input mat to a \c mat with the given \c type, and writes the result to
/// \c type. The \c output matrix will be created with the corresponding type.
///
/// The following considerations are made while converting:
/// - Number of channels: if the number of channels of \c input is larger than of \c type, the first
///   channels will be used, and the rest will be removed. If the number of channels of \c input is
///   smaller than of \type, zero channels will be appended.
/// - Depth: depth will be converted using \c cv::Mat \c convertTo method. When converting from \c
///   float values to \c ubyte, a scale factor of \c 255 will be used. The inverse scale factor will
///   be used if the inverse conversion direction is requested.
///
/// If \c type is equal to \c input.type(), the data will be copied directly to the output.
void LTConvertMat(const cv::Mat &input, cv::Mat *output, int type);

/// Converts the given \c input mat to an \c output mat with an optional \c alpha scaling. Either \c
/// input or \c output should be of half-float precision, and they cannot point to the same memory
/// address. The \c _From and \c _To template parameters define the source matrix type and the
/// target matrix type to convert to, accordingly.
template <typename _From, typename _To>
void LTConvertHalfFloat(const cv::Mat &input, cv::Mat *output, double alpha = 1);

/// Shifts the given \c mat, such that the zero-frequency component is moved to the center of the
/// matrix. This is done by swapping the first quadrand with the third and the second with the
/// fourth.
void LTInPlaceFFTShift(cv::Mat *mat);

/// Performs a pre-divide, to convert an image with premultiplied alpha into a non-premultiplied
/// one. Throws exception if the input format is not byte RGBA.
void LTPreDivideMat(cv::Mat *mat);

/// Loads an image with the given \c name from the bundle that contains the given class. Throws
/// exception if the image cannot be found or loaded.
UIImage *LTLoadImage(Class classInBundle, NSString *name);

/// Loads an image to \c cv::Mat with the given \c name from the bundle that contains the given
/// class. If \c preDivide is \c YES, the mat will be pre-divided to undo the alpha
/// premultiplication. Throws exception if the image cannot be found or loaded, or if trying to
/// preDivide a non byte RGBA image.
cv::Mat LTLoadMat(Class classInBundle, NSString *name, BOOL preDivide = NO);

/// Loads an image from the main bundle to \c cv::Mat with the given \c name.
/// If \c preDivide is \c YES, the mat will be pre-divided to undo the alpha premultiplication.
/// Throws exception if the image cannot be found or loaded, or if trying to preDivide a non byte
/// RGBA image.
cv::Mat LTLoadMatFromMainBundle(NSString *name, BOOL preDivide = NO);

/// Loads an image from the main bundle to \c cv::Mat with the given \c name.
/// If \c preDivide is \c YES, the mat will be pre-divided to undo the alpha premultiplication.
/// Throws exception if the image cannot be found or loaded, or if trying to preDivide a non byte
/// RGBA image.
cv::Mat LTLoadMatFromBundle(NSBundle *bundle, NSString *name, BOOL preDivide = NO);

/// Generates a single-channel half-float matrix with the given size, containing a gaussian with
/// the given sigma. If \c normalized is \c YES, the gaussian will be normalized such that its
/// maximal value is 1.0 (in odd sizes the center element will be 1.0 even without normalizing).
cv::Mat1hf LTCreateGaussianMat(CGSize size, double sigma, BOOL normalized = NO);

/// Returns a \c 3x3 float matrix with the entries of the provided GLKMatrix3.
cv::Mat1f LTMatFromGLKMatrix3(GLKMatrix3 matrix);

/// Returns the value of the given pixel in the given image.
///
/// @note Half-float images are not supported.
LTVector4 LTPixelValueFromImage(const cv::Mat &image, cv::Point2i location);

#pragma mark -
#pragma mark Details
#pragma mark -

template <typename _From, typename _To>
void LTConvertHalfFloat(const cv::Mat &input, cv::Mat *output, double alpha) {
  static_assert(cv::DataDepth<_From>::value == CV_16F ||
                cv::DataDepth<_To>::value == CV_16F, "_From or _To must be of a half-float type");

  LTParameterAssert(input.data != output->data, @"Input and output cannot point to the same data");

  output->create(input.size(), CV_MAKETYPE(cv::DataDepth<_To>::value, input.channels()));

  cv::Size size(input.size());
  if (input.isContinuous() && output->isContinuous()) {
    size.width *= size.height;
    size.height = 1;
  }
  size.width *= input.channels();

  // TODO:(yaron) performance can be increased by doing this in batch.
  for (int i = 0; i < size.height; ++i) {
    const _From *inputPtr = input.ptr<_From>(i);
    _To *outputPtr = output->ptr<_To>(i);

    for (int j = 0; j < size.width; ++j) {
      outputPtr[j] = cv::saturate_cast<_To>(half_float::half(inputPtr[j]) * alpha);
    }
  }
}
