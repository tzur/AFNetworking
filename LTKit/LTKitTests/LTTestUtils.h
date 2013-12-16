// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

// This file contains various testing utilities for \c LTKit.

/// Returns \c YES if the two given matrices are equal. Matrices are equal if their \c size,
/// \c depth, \c channels and actual data are all equal.
BOOL LTCompareMat(const cv::Mat &a, const cv::Mat &b);

/// Converts a \c CGRect to OpenCV's \c cv::Rect.
cv::Rect LTCVRectWithCGRect(CGRect rect);

/// Converts a \c cv::Vec4b to \c GLKVector4.
GLKVector4 LTCVVec4bToGLKVector4(cv::Vec4b value);

/// Converts a \c GLKVector4 to \c cv::Vec4b.
cv::Vec4b LTGLKVector4ToVec4b(GLKVector4 value);

/// Comparator for \c GLKVector4.
inline BOOL operator==(const GLKVector4& lhs, const GLKVector4& rhs) {
  return !memcmp(lhs.v, rhs.v, sizeof(lhs.v));
}
