// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCGExtensions.h"

/// Represents a \c CGRect, while providing easy access to its edges, corners and center.
struct LTRect {
  /// Initializes the null rectangle.
  LTRect() : origin(CGRectNull.origin), size(CGRectNull.size) {}
  
  /// Initializes a new \c LTRect from the given CGRect.
  LTRect(const CGRect &rect) : origin(rect.origin), size(rect.size) {}

  /// Initializes a new \c LTRect from the given origin and size.
  LTRect(const CGPoint &origin, const CGSize &size) : origin(origin), size(size) {}
  
  /// Initializes a new \c LTRect from the given corners.
  LTRect(const CGPoint &topLeft, const CGPoint &bottomRight) :
    origin(topLeft), size(CGSizeFromPoint(bottomRight - topLeft)) {}
  
  /// Initializes a new \c LTRect with the given (x, y) as origin and (width, height) as size.
  LTRect(CGFloat x, CGFloat y, CGFloat width, CGFloat height) :
    origin(CGPointMake(x, y)), size(CGSizeMake(width, height)) {}
  
  /// Cast operator to \c CGRect.
  inline operator CGRect() const {
    return rect();
  }
  
  inline CGRect rect() const {
    return CGRectFromOriginAndSize(origin, size);
  }
  
  /// Returns the smallest value for the y-coordinate of the rectangle.
  inline CGFloat top() const {
    return CGRectGetMinY(rect());
  }
  
  /// Returns the smallest value for the x-coordinate of the rectangle.
  inline CGFloat left() const {
    return CGRectGetMinX(rect());
  }
  
  /// Returns the largest value of the x-coordinate for the rectangle.
  inline CGFloat right() const {
    return CGRectGetMaxX(rect());
  }
  
  /// Returns the largest value of the y-coordinate for the rectangle.
  inline CGFloat bottom() const {
    return CGRectGetMaxY(rect());
  }
  
  /// Returns the top left corner of the rectangle.
  inline CGPoint topLeft() const {
    return origin;
  }
  
  /// Returns the top right corner of the rectangle.
  inline CGPoint topRight() const {
    return CGPointMake(origin.x + size.width, origin.y);
  }
  
  /// Returns the bottom left corner of the rectangle.
  inline CGPoint bottomLeft() const {
    return CGPointMake(origin.x, origin.y + size.height);
  }
  
  /// Returns the bottom right corner of the rectangle.
  inline CGPoint bottomRight() const {
    return origin + size;
  }
  
  /// Returns the center of the rectangle.
  inline CGPoint center() const {
    return origin + 0.5 * size;
  }
  
  /// Returns the aspect ratio (width / height) of the rectangle.
  inline CGFloat aspectRatio() const {
    return size.width / size.height;
  }
  
  CGPoint origin;
  CGSize size;
};
