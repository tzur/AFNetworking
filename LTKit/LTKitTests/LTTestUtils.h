// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

// This file contains various testing utilities for \c LTKit.

/// Executes the given test if running on the simulator.
void sit(NSString *name, id block);

/// Executes the given test if running on the device.
void dit(NSString *name, id block);

/// Returns \c YES if currently running application tests (and not logic tests).
BOOL LTRunningApplicationTests();

/// Returns \c YES if the two given matrices are equal. Matrices are equal if their \c size,
/// \c depth, \c channels and actual data are all equal.
BOOL LTCompareMat(const cv::Mat &expected, const cv::Mat &actual);

/// Returns \c YES if the two given matrices are equal, up to the given \c range, which is set
/// across all channels. Matrices are equal if their \c size, \c depth, \c channels and actual data
/// are all equal.
BOOL LTFuzzyCompareMat(const cv::Mat &expected, const cv::Mat &actual, double range = 1);

/// Returns \c YES if the given \c actual matrix cells are all equal to the given \c expected
/// scalar.
BOOL LTCompareMatWithValue(const cv::Scalar &expected, const cv::Mat &actual);

/// Returns \c YES if the given \c actual matrix cells are all equal, up to the given \c range, to
/// the given \c expected scalar.
BOOL LTFuzzyCompareMatWithValue(const cv::Scalar &expected, const cv::Mat &actual,
                                double range = 1);

/// Converts a \c CGRect to OpenCV's \c cv::Rect.
cv::Rect LTCVRectWithCGRect(CGRect rect);

/// Converts a \c cv::Vec4b to \c GLKVector4.
GLKVector4 LTCVVec4bToGLKVector4(cv::Vec4b value);

/// Converts a \c GLKVector4 to \c cv::Vec4b.
cv::Vec4b LTGLKVector4ToVec4b(GLKVector4 value);

/// Loads an image with the given \c name from the bundle that contains the given class. Throws
/// exception if the image cannot be found or loaded.
UIImage *LTLoadImageWithName(Class classInBundle, NSString *name);

/// Loads an image to \c cv::Mat with the given \c name from the bundle that contains the given
/// class. Throws exception if the image cannot be found or loaded.
cv::Mat LTLoadMatWithName(Class classInBundle, NSString *name);

/// Returns the path for a resource in the bundle defined by the given \c classInBundle which it
/// contains. Raises an exception if the image cannot be loaded.
NSString *LTPathForResource(Class classInBundle, NSString *name);

/// Comparator for \c GLKVector4.
inline BOOL operator==(const GLKVector4& lhs, const GLKVector4& rhs) {
  return !memcmp(lhs.v, rhs.v, sizeof(lhs.v));
}
