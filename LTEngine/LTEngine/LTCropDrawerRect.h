// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTVector.h"

/// Struct representing a rectangle used by the crop drawer.
struct LTCropDrawerRect {
  /// Initializes a new \c LTCropDrawerRect with (0,0) for every corner.
  LTCropDrawerRect();
  
  /// Initializes a new \c LTCropDrawerRect with the given corners.
  LTCropDrawerRect(const LTVector2 &topLeft, const LTVector2 &topRight,
                   const LTVector2 &bottomLeft, const LTVector2 &bottomRight);
  
  /// Initiailizes a new \c LTCropDrawerRect corresponding to the given rect.
  LTCropDrawerRect(CGRect rect);
  
  /// Cast operator to a standard (positive size) \c CGRect.
  operator CGRect();
  
  /// Multiplies the given vector element wise with this vector.
  LTCropDrawerRect &operator*=(const LTVector2 &rhs);
  
  /// Divides the given vector element wise with this vector.
  LTCropDrawerRect &operator/=(const LTVector2 &rhs);
  
  union {
    struct { LTVector2 topLeft, topRight, bottomLeft, bottomRight; };
    LTVector2 corners[4];
  };
};

