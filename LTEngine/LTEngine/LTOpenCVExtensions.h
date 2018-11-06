// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTOpenCVCore.h"
#import "LTOpenCVHalfFloat.h"
#import "LTVector.h"

NS_ASSUME_NONNULL_BEGIN

namespace cv {
  /// \c CGFloat specializations of the \c Vec type.
  typedef Vec<CGFloat, 2> Vec2g;
  typedef Vec<CGFloat, 3> Vec3g;
  typedef Vec<CGFloat, 4> Vec4g;

  /// Matrix of \c std::vector<CGFloat>.
  ///
  /// @note Since \c CGFloat is \c float or \c double depending on the target architecture, this
  /// type definition is \c cv::Mat1f if \c CGFloat is \c float, and \c cv::Mat1g otherwise.
  typedef Mat_<CGFloat> Mat1g;
  typedef Mat_<Vec2g> Mat2g;
  typedef Mat_<Vec3g> Mat3g;
  typedef Mat_<Vec4g> Mat4g;
}

/// Converts the given \c input mat to a \c mat with the given \c type, and writes the result to
/// \c output. The \c output matrix will be created with the corresponding type.
///
/// The following considerations are made while converting:
/// - Number of channels: if the number of channels of \c input is larger than of \c type, the first
///   channels will be used, and the rest will be removed. If the number of channels of \c input is
///   smaller than of \type, zero channels will be appended.
/// - Depth: depth will be converted using \c cv::Mat::convertTo method. When converting between
///   float precision and unsigned integral values, an appropriate scale factor will be used to map
///   the values correctly onto the desire region. Other depth conversions may result in clamped
///   values.
///
/// If \c type is equal to \c input.type(), the data will be copied directly to the output.
void LTConvertMat(const cv::Mat &input, cv::Mat *output, int type);

/// Updates the values of the given \c output matrix to be the values of the given \c input matrix,
/// converted to half-float precision. \c input and \c output must have the same size and number of
/// channels. \c input depth must be \c CV_8U or \c CV_32F. \c output depth must be \c CV_16F. If
/// \c input depth is \c CV_8U, the values will be divided by 255.
void LTConvertToHalfFloat(const cv::Mat &input, cv::Mat *output);

/// Updates the values of the given \c output matrix to be the values of the given \c input matrix,
/// converted from half-float precision to \c CV_8U or \c CV_32F. \c input and \c output must have
/// the same size and number of channels. \c input depth must be \c CV_16F. \c output depth must be
/// \c CV_8U or \c CV_32F. If \c output depth is \c CV_8U, the values will be multiplied by 255.
void LTConvertFromHalfFloat(const cv::Mat &input, cv::Mat *output);

/// Shifts the given \c mat, such that the zero-frequency component is moved to the center of the
/// matrix. This is done by swapping the first quadrand with the third and the second with the
/// fourth.
void LTInPlaceFFTShift(cv::Mat *mat);

/// Converts an image with premultiplied alpha into one with non-premultiplied alpha. \c input and
/// \c output must be of equal size and type, type must be CV_8UC4 or CV_32FC4. If \c input equals
/// \c output, performs the operation in-place.
void LTUnpremultiplyMat(const cv::Mat &input, cv::Mat *output);

/// Converts an image with non-premultiplied alpha into one with premultiplied alpha. \c input and
/// \c output must be of equal size and type, type must be CV_8UC4 or CV_32FC4. If \c input equals
/// \c output, performs the operation in-place.
void LTPremultiplyMat(const cv::Mat &input, cv::Mat *output);

/// Loads an image with the given \c name from the bundle that contains the given class. Throws
/// exception if the image cannot be found or loaded.
UIImage *LTLoadImage(Class classInBundle, NSString *name);

/// Loads an image to \c cv::Mat with the given \c name from the bundle that contains the given
/// class. If \c unpremultiply is \c YES, the mat will be divided to undo the alpha
/// premultiplication. Throws exception if the image cannot be found or loaded, or if trying to
/// unpremultiply a non byte RGBA image.
cv::Mat LTLoadMat(Class classInBundle, NSString *name, BOOL unpremultiply = NO);

/// Loads an image from the main bundle to \c cv::Mat with the given \c name.
/// If \c unpremultiply is \c YES, the mat will be divided to undo the alpha premultiplication.
/// Throws exception if the image cannot be found or loaded, or if trying to unpremultiply a non
/// byte RGBA image.
cv::Mat LTLoadMatFromMainBundle(NSString *name, BOOL unpremultiply = NO);

/// Loads an image from the main bundle to \c cv::Mat with the given \c name.
/// If \c unpremultiply is \c YES, the mat will be divided to undo the alpha premultiplication.
/// Throws exception if the image cannot be found or loaded, or if trying to unpremultiply a non
/// byte RGBA image.
cv::Mat LTLoadMatFromBundle(NSBundle *bundle, NSString *name, BOOL unpremultiply = NO);

/// Generates a single-channel half-float matrix with the given size, containing a gaussian with
/// the given sigma. If \c normalized is \c YES, the gaussian will be normalized such that its
/// maximal value is 1.0 (in odd sizes the center element will be 1.0 even without normalizing).
cv::Mat1hf LTCreateGaussianMat(CGSize size, double sigma, BOOL normalized = NO);

/// Returns a \c 3x3 float matrix with the entries of the provided GLKMatrix3.
cv::Mat1f LTMatFromGLKMatrix3(GLKMatrix3 matrix);

/// Returns the value of the given pixel in the given image.
LTVector4 LTPixelValueFromImage(const cv::Mat &image, cv::Point2i location);

/// Returns a checkerboard with the given \c size. The tiles are colored alternately white
/// (<tt>255, 255, 255, 255</tt>) and gray (<tt>193, 193, 193, 255</tt>). The size of each tile
/// equals the given \c tileSize. The tile containing \c mat(0, 0) is grey.
cv::Mat4b LTWhiteGrayCheckerboardPattern(CGSize size, uint tileSize);

/// Returns a checkerboard with the given \c size. The tiles are colored alternately
/// \c firstColor and \c secondColor. The size of each tile equals the given \c tileSize. The tile
/// containing \c mat(0, 0) is \c firstColor.
cv::Mat4b LTCheckerboardPattern(CGSize size, uint tileSize, cv::Vec4b firstColor,
                                cv::Vec4b secondColor);

/// Returns new matrix containing a subset of the rows of the given \c mat defined by \c indices, in
/// the order they are specified in the \c indices vector. Every value in \c indices must be in the
/// range <tt>[0, mat.rows - 1]</tt>. An invalid index will raise an \c NSInvalidArgumentException
/// exception.
cv::Mat LTRowSubset(const cv::Mat &mat, const std::vector<int> &indices);

/// Rotates the given mat by 90 degrees around its center, \c rotations times and flips horizontally
/// if \c mirrorHorizontal is \c YES. Positive values of \c rotations rotate clockwise and negative
/// values counter clockwise. \c intermediate can be set to a preallocated Mat in the correct size
/// after rotation to avoid this allocation within the function.
cv::Mat LTRotateHalfPiClockwise(const cv::Mat &input, NSInteger rotations,
                                BOOL mirrorHorizontal = NO,
                                cv::Mat * _Nullable intermediateMat = NULL);

/// Rotates the given mat by 90 degrees around its center, \c rotations times and flips horizontally
/// if \c mirrorHorizontal is \c YES. Positive values of \c rotations rotate clockwise and negative
/// values counter clockwise. \c output and \c intermediate can be set to a preallocated Mat in the
/// correct size after rotation to avoid this allocation within the function.
void LTRotateHalfPiClockwise(const cv::Mat &input, cv::Mat *output,
                             NSInteger rotations, BOOL mirrorHorizontal,
                             cv::Mat * _Nullable intermediate = NULL);

NS_ASSUME_NONNULL_END
