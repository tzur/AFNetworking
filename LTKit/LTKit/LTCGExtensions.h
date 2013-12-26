// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// The "empty" point. This is the point returned when, for example, we intersect parallel lines.
///
/// @note the null point is not the same as the zero point, and that the null point will never be
/// equal to another point (even another null point).
///
/// @note arithemtic operations on the null point are not defined.
CG_EXTERN const CGPoint CGPointNull;

/// The "empty" size. This is the size returned when a size value is not set, for example, when a
/// runtime property that should be set in the interface builder is not set.
///
/// @note the null size is not the same as the zero size, and that the null size will never be equal
/// to another size (even another null size).
///
/// @note arithemtic operations on the null size are not defined.
CG_EXTERN const CGSize CGSizeNull;

/// Returns whether the given point is the null point.
CG_INLINE BOOL CGPointIsNull(CGPoint point) {
  return isnan(point.x) && isnan(point.y);
}

/// Returns whether the given size is the null size.
CG_INLINE BOOL CGSizeIsNull(CGSize size) {
  return isnan(size.width) && isnan(size.height);
}

#ifdef __cplusplus

#pragma mark -
#pragma mark CGPoint Operations
#pragma mark -

/// Returns whether two points are equal.
CG_INLINE BOOL operator==(const CGPoint &lhs, const CGPoint &rhs) {
  return CGPointEqualToPoint(lhs, rhs);
}

/// Returns whether two points are not equal.
CG_INLINE BOOL operator!=(const CGPoint &lhs, const CGPoint &rhs) {
  return !(lhs == rhs);
}

/// Returns the point resulting by adding the right size to the left point.
CG_INLINE CGPoint operator+(const CGPoint &lhs, const CGSize &rhs) {
  return CGPointMake(lhs.x + rhs.width, lhs.y + rhs.height);
}

/// Returns the point resulting by subtracting the right size from the left point.
CG_INLINE CGPoint operator-(const CGPoint &lhs, const CGSize &rhs) {
  return CGPointMake(lhs.x - rhs.width, lhs.y - rhs.height);
}

/// Returns the size resulting from subtracting the right point from the left one.
CG_INLINE CGSize operator-(const CGPoint &lhs, const CGPoint &rhs) {
  return CGSizeMake(lhs.x - rhs.x, lhs.y - rhs.y);
}

/// Multiply a CGPoint by a scalar value.
CG_INLINE CGPoint operator*(const CGPoint &lhs, const CGFloat &rhs) {
  return CGPointMake(lhs.x * rhs, lhs.y * rhs);
}

/// Multiply a CGPoint by a scalar value.
CG_INLINE CGPoint operator*(const CGFloat &lhs, const CGPoint &rhs) {
  return CGPointMake(rhs.x * lhs, rhs.y * lhs);
}

/// Divide a CGPoint by a scalar value.
CG_INLINE CGPoint operator/(const CGPoint &lhs, const CGFloat &rhs) {
  return CGPointMake(lhs.x / rhs, lhs.y / rhs);
}

#pragma mark -
#pragma mark CGSize Operations
#pragma mark -

/// Returns whether two sizes are equal.
CG_INLINE BOOL operator==(const CGSize &lhs, const CGSize &rhs) {
  return CGSizeEqualToSize(lhs, rhs);
}

/// Returns whether two sizes are not equal.
CG_INLINE BOOL operator!=(const CGSize &lhs, const CGSize &rhs) {
  return !(lhs == rhs);
}

/// Returns the size resulting from adding the given sizes.
CG_INLINE CGSize operator+(const CGSize &lhs, const CGSize &rhs) {
  return CGSizeMake(lhs.width + rhs.width, lhs.height + rhs.height);
}

/// Returns the size resulting from subtracting the right size from the left one.
CG_INLINE CGSize operator-(const CGSize &lhs, const CGSize &rhs) {
  return CGSizeMake(lhs.width - rhs.width, lhs.height - rhs.height);
}

/// Multiply a CGSize by a scalar value.
CG_INLINE CGSize operator*(const CGSize &lhs, const CGFloat &rhs) {
  return CGSizeMake(lhs.width * rhs, lhs.height * rhs);
}

/// Multiply a CGSize by a scalar value.
CG_INLINE CGSize operator*(const CGFloat &lhs, const CGSize &rhs) {
  return CGSizeMake(rhs.width * lhs, rhs.height * lhs);
}

/// Divide a CGSize by a scalar value.
CG_INLINE CGSize operator/(const CGSize &lhs, const CGFloat &rhs) {
  return CGSizeMake(lhs.width / rhs, lhs.height / rhs);
}

#pragma mark -
#pragma mark CGRect Operations
#pragma mark -

/// Returns whether two rectangles are equal in size and position.
CG_INLINE BOOL operator==(const CGRect &lhs, const CGRect &rhs) {
  return CGRectEqualToRect(lhs, rhs);
}

/// Returns whether two rectangles are not equal in size or position.
CG_INLINE BOOL operator!=(const CGRect &lhs, const CGRect &rhs) {
  return !(lhs == rhs);
}

/// Returns a CGRect with the given origin and size.
CG_INLINE CGRect CGRectFromOriginAndSize(const CGPoint &origin, const CGSize &size) {
  return {.origin = origin, .size = size};
}

/// Returns a CGRect with the given corners.
CG_INLINE CGRect CGRectFromPoints(const CGPoint &topLeft, const CGPoint &bottomRight) {
  return CGRectFromOriginAndSize(topLeft, bottomRight - topLeft);
}

/// Returns a CGRect with the given edge coordiantes.
CG_INLINE CGRect CGRectFromEdges(CGFloat left, CGFloat top, CGFloat right, CGFloat bottom) {
  return CGRectFromPoints(CGPointMake(left, top), CGPointMake(right, bottom));
}

/// Returns a rectangle defined by its center and size.
CG_INLINE CGRect CGRectCenteredAt(const CGPoint &center, const CGSize &size) {
  return CGRectFromOriginAndSize(center -(0.5 * size), size);
}

/// Returns the center of the given rect.
CG_INLINE CGPoint CGRectCenter(const CGRect &rect) {
  return rect.origin + 0.5 * rect.size;
}

#pragma mark -
#pragma mark Distance
#pragma mark -

/// Returns the squared euclidean distance between two points.
CG_INLINE CGFloat CGPointDistanceSquared(const CGPoint &a, const CGPoint &b) {
  CGSize d = a - b;
  return d.width * d.width + d.height * d.height;
}

/// Returns the euclidean distance between two points.
CG_INLINE CGFloat CGPointDistance(const CGPoint &a, const CGPoint &b) {
  return std::sqrt(CGPointDistanceSquared(a, b));
}

#pragma mark -
#pragma mark Rounding CGStructs
#pragma mark -

/// Floors the given CGPoint, coordinate-wise.
CG_INLINE CGPoint CGFloorPoint(const CGPoint &point) {
  return CGPointMake(std::floor(point.x), std::floor(point.y));
}

/// Ceils the given CGPoint, coordinate-wise.
CG_INLINE CGPoint CGCeilPoint(const CGPoint &point) {
  return CGPointMake(std::ceil(point.x), std::ceil(point.y));
}

/// Rounds the given CGPoint, coordinate-wise.
CG_INLINE CGPoint CGRoundPoint(const CGPoint &point) {
  return CGPointMake(std::round(point.x), std::round(point.y));
}

/// Floors the given CGSize, coordinate-wise.
CG_INLINE CGSize CGFloorSize(const CGSize &size) {
  return CGSizeMake(std::floor(size.width), std::floor(size.height));
}

/// Ceils the given CGSize, coordinate-wise.
CG_INLINE CGSize CGCeilSize(const CGSize &size) {
  return CGSizeMake(std::ceil(size.width), std::ceil(size.height));
}

/// Rounds the given CGSize, coordinate-wise.
CG_INLINE CGSize CGRoundSize(const CGSize &size) {
  return CGSizeMake(std::round(size.width), std::round(size.height));
}

/// Rounds the given CGRect, such that its corner coordinates are rounded to the nearest integer
/// values (meaning that its size is rounded to an integer, but not necessarily the nearest one).
CG_INLINE CGRect CGRoundRect(const CGRect &rect) {
  return CGRectFromPoints(CGRoundPoint(rect.origin), CGRoundPoint(rect.origin + rect.size));
}

/// Rounds the given CGRect, such that its corner coordinates are rounded to integer values while
/// keeping the result rect inside the original one.
///
/// @note assumes non-negative origin and size.
CG_INLINE CGRect CGRoundRectInside(const CGRect &rect) {
  return CGRectFromPoints(CGCeilPoint(rect.origin), CGFloorPoint(rect.origin + rect.size));
}

/// Rounds the given CGRect, such that its corner coordinates are rounded to integer values while
/// the result rect contains the original one.
///
/// @note assumes non-negative origin and size.
CG_INLINE CGRect CGRoundRectOutside(const CGRect &rect) {
  return CGRectFromPoints(CGFloorPoint(rect.origin), CGCeilPoint(rect.origin + rect.size));
}

#endif
