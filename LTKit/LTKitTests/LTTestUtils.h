// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <numeric>

// This file contains various testing utilities for \c LTKit.

/// Executes the given test if running on the simulator.
void sit(NSString *name, id block);

/// Executes the given test if running on the device.
void dit(NSString *name, id block);

/// Returns \c YES if currently running application tests (and not logic tests).
BOOL LTRunningApplicationTests();

/// Returns \c YES if the two given matrices are equal. Matrices are equal if their \c size,
/// \c depth, \c channels and actual data are all equal.
BOOL LTCompareMat(const cv::Mat &expected, const cv::Mat &actual,
                  cv::Point *firstMismatch = nullptr);

/// Returns \c YES if the two given matrices are equal, up to the given \c range, which is set
/// across all channels. Matrices are equal if their \c size, \c depth, \c channels and actual data
/// are all equal.
BOOL LTFuzzyCompareMat(const cv::Mat &expected, const cv::Mat &actual, double range = 1,
                       cv::Point *firstMismatch = nullptr);

/// Returns \c YES if the given \c actual matrix cells are all equal to the given \c expected
/// scalar.
BOOL LTCompareMatWithValue(const cv::Scalar &expected, const cv::Mat &actual,
                           cv::Point *firstMismatch = nullptr);

/// Returns \c YES if the given \c actual matrix cells are all equal, up to the given \c range, to
/// the given \c expected scalar.
BOOL LTFuzzyCompareMatWithValue(const cv::Scalar &expected, const cv::Mat &actual,
                                double range = 1, cv::Point *firstMismatch = nullptr);

/// Returns a string representation of the \c mat cell value at the given \c position.
NSString *LTMatValueAsString(const cv::Mat &mat, cv::Point position);

/// Returns a string representation of the \c scalar value.
NSString *LTScalarAsString(const cv::Scalar &scalar);

/// Blending should match photoshop's "normal" blend mode:
/// C_out = C_new + (1-A_new)*C_old;
/// A_out = A_old + (1-A_old)*A_new;
cv::Vec4b LTBlend(const cv::Vec4b &oldColor, const cv::Vec4b &newColor, bool premultiplied = YES);

/// Converts a \c CGRect to OpenCV's \c cv::Rect.
cv::Rect LTCVRectWithCGRect(CGRect rect);

/// Converts a \c cv::Vec4b to \c LTVector4.
LTVector4 LTCVVec4bToLTVector4(cv::Vec4b value);

/// Converts a \c cv::Vec4hf to \c LTVector4.
LTVector4 LTCVVec4hfToLTVector4(cv::Vec4hf value);

/// Converts a \c LTVector4 to \c cv::Vec4b.
cv::Vec4b LTLTVector4ToVec4b(LTVector4 value);

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
