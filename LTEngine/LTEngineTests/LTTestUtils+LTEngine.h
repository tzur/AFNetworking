// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <LTEngine/LTBlendMode.h>
#import <LTEngine/LTOpenCVHalfFloat.h>
#import <numeric>

NS_ASSUME_NONNULL_BEGIN

/// Returns \c YES if the two given matrices are equal. Matrices are equal if their \c size,
/// \c depth, \c channels and actual data are all equal.
BOOL LTCompareMat(const cv::Mat &expected, const cv::Mat &actual,
                  std::vector<int> *firstMismatch = nullptr);

/// Returns \c YES if the two given matrices are equal, up to the given \c range, which is set
/// across all channels. Matrices are equal if their \c size, \c depth, \c channels and actual data
/// are all equal.
BOOL LTFuzzyCompareMat(const cv::Mat &expected, const cv::Mat &actual, double range = 1,
                       std::vector<int> *firstMismatch = nullptr);

/// Returns \c YES if the given \c actual matrix cells are all equal to the given \c expected
/// scalar.
BOOL LTCompareMatWithValue(const cv::Scalar &expected, const cv::Mat &actual,
                           std::vector<int> *firstMismatch = nullptr);

/// Returns \c YES if the given \c actual matrix cells are all equal, up to the given \c range, to
/// the given \c expected scalar.
BOOL LTFuzzyCompareMatWithValue(const cv::Scalar &expected, const cv::Mat &actual,
                                double range = 1, std::vector<int> *firstMismatch = nullptr);

/// Returns, 2 dimensional, matrix of the following type <tt>{CV_8UC1, CV_8UC4, CV_16UC1,
/// CV_16UC4}</tt>, by converting the given, 2 dimensional, \c mat as follows:
/// * \c depth \c CV_16U and \c CV_8U is preserved, otherwise \c mat.depth() will be converted
///   to \c CV_8U (using \c LTConvertMat).
/// * Single channel matrix will preserve its number of channels, otherwise the number of channels
///   will be extended to \c 4. When adding channels, the 4th (alpha) channel will hold \c UCHAR_MAX
///   or \c USHRT_MAX depending on \c mat.depth(). Other non-alpha channels are added with zeros.
///
/// @important raises in case of signed \c mat.depth() or <tt>mat.dims != 2</tt>.
cv::Mat LTUIImageCompatibleMatWithMat(const cv::Mat &mat);

/// Returns \c UIImage from the given 2 dimensional compatible \c mat, whose \c type is
/// <tt>{CV_8UC1, CV_8UC4, CV_16UC1, CV_16UC4}</tt>, or \c nil if \c type doesn't match. Returned
/// image created from single-channel matrix will have device-dependent grayscale color space,
/// multi-channel matrix will produce device-dependent RGB color space image.
UIImage * _Nullable LTUIImageWithCompatibleMat(const cv::Mat &mat);

/// Attaches the given \c attachments name-value pairs to the results of the current test case.
/// In Xcode's report navigator, each attached \c UIImage named with corresponding \c NSString.
/// All attachments are grouped by \c activityName`.
void LTAttachImagesToCurrentTest(NSString *activityName,
                                 const std::vector<std::pair<NSString *, UIImage *>> &attachments);

/// Writes the given, 2 dimensional, \c mat in a PNG fromat to the given \c path. \c mat is
/// converted using the following table before it's written:
/// * \c depth \c CV_16U and \c CV_8U is preserved, otherwise \c mat.depth() will be converted
///   to \c CV_8U (using \c LTConvertMat).
/// * Single channel matrix will preserve its number of channels, otherwise the number of channels
///   will be extended to \c 4 (except for \c CV_8UC3 \c mat which is written as is). When adding
///   channels, the 4th (alpha) channel will hold \c UCHAR_MAX or \c USHRT_MAX depending on
///   \c mat.depth(). Other non-alpha channels are added with zeros.
///
/// @important raises in case of signed \c mat.depth() or <tt>mat.dims != 2</tt> or \c path
/// extension isn't \c png.
void LTWriteMatAsPNG(const cv::Mat &mat, NSString *path);

/// Returns a string representation of indicies vector \c indices of length \c length.
NSString *LTIndicesVectorAsString(const std::vector<int> &indices);

/// Returns a string representation of the \c mat cell value at the given \c position.
NSString *LTMatValueAsString(const cv::Mat &mat, const std::vector<int> &position);

/// Returns a string representation of the \c scalar value.
NSString *LTScalarAsString(const cv::Scalar &scalar);

/// Blends the given colors according to the given \c LTBlendMode. The \c premultiplied flag
/// indicates whether the input is given with premultipled alpha or not, and the output will match.
cv::Vec4b LTBlend(const cv::Vec4b &oldColor, const cv::Vec4b &newColor, bool premultiplied = YES,
                  LTBlendMode mode = LTBlendModeNormal);

/// Converts a \c CGRect to OpenCV's \c cv::Rect.
cv::Rect LTCVRectWithCGRect(CGRect rect);

/// Converts a \c LTVector4 to \c cv::Vec4b.
cv::Vec4b LTLTVector4ToVec4b(LTVector4 value);

/// Converts a \c LTVector4 to \c cv::Vec4f.
cv::Vec4f LTLTVector4ToVec4f(LTVector4 value);

/// Returns a \c cv::Vec4hf with all four values equal to \c scalar.
cv::Vec4hf LTCVVec4hfFromScalar(float scalar);

/// Returns a \c cv::Vec4hf with the given values.
cv::Vec4hf LTCVVec4hf(float r, float g, float b, float a);

/// Rotates (clockwise) the given mat by the given angle (in radians) around its center.
/// Uses nearest neighbor interpolation.
cv::Mat LTRotateMat(const cv::Mat input, CGFloat angle);

/// Returns a matrix of the given \c size containing delta at \c position.
cv::Mat4b LTCreateDeltaMat(CGSize size, CGPoint position);

/// Returns a matrix of the given \c size containing delta at the middle.
cv::Mat4b LTCreateDeltaMat(CGSize size);

/// Returns a new UIImage with the given size.
UIImage *LTCreateUIImage(CGSize size);

/// Loads an image to \c cv::Mat. The name of the image can differ between simulator and device.
/// Loads from the bundle that contains the given class. Throws exception if the image cannot be
/// found or loaded.
cv::Mat LTLoadDeviceDependentMat(Class classInBundle, NSString *simulatorName,
                                 NSString *deviceName);

/// Returns a matrix of size \c matSize which is devided into cells of uniform size \c cellSize with
/// random RGB colors. \c matSize and \c cellSize must be integral. The grid that is obtained from
/// the cells will be of size <tt>matSize / cellSize</tt>. This size must also be integral.
cv::Mat4b LTGenerateCellsMat(CGSize matSize, CGSize cellSize);

/// Returns the content of \c texture at \c mipmapLevel, copied into a \c cv::Mat.
cv::Mat LTCVMatByCopyingFromMTLTexture(id<MTLTexture> texture, NSUInteger mipmapLevel = 0);

/// Returns the mean value of all elements in the given container.
template <typename Container>
double LTMean(const Container &container) {
  return container.size() > 0 ?
      std::accumulate(container.begin(), container.end(), 0.0) / (double)container.size() : 0.0;
}

/// Returns the variance of all elements in the given container.
template <typename Container>
double LTVariance(const Container &container) {
  double mean = LTMean(container);
  double squareSum = std::inner_product(container.begin(), container.end(), container.begin(), 0.0);
  return squareSum / container.size() - mean * mean;
}

NS_ASSUME_NONNULL_END
