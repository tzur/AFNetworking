// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "LTGLKitExtensions.h"
#import "LTGeometry.h"

#ifdef __cplusplus

namespace lt {
  
/// Struct that represents an ellipse in 2D space.
struct Ellipse {
  /// Returns an empty ellipse.
  constexpr Ellipse() : center(CGPointZero), angle(0), majorAxisLength(0), minorAxisLength(0) {}
  
  /// Initializes with the given \c center, \c angle, \c majorAxisLength and \c minorAxisLength.
  /// The given \c angle represents the angle, in radians, between the x-axis and the major axis
  /// of the ellipse, in counter-clockwise direction in bottom-left coordinate system.
  constexpr Ellipse(CGPoint center, CGFloat angle, CGFloat majorAxisLength,
                    CGFloat minorAxisLength) : center(center), angle(angle),
                    majorAxisLength(majorAxisLength), minorAxisLength(minorAxisLength) {}
  
  /// Returns \c YES if the given \c point is contained by this ellipse.
  BOOL containsPoint(CGPoint point) const {
    return (LTVector2(LTRotatePoint(point - center, -angle)) /
            (LTVector2(majorAxisLength, minorAxisLength) / 2)).length() <= 1;
  }
  
  /// Returns a new ellipse obtained by translating this instance by the given \c translation.
  Ellipse translatedBy(CGPoint translation) const {
    return Ellipse(center + translation, angle, majorAxisLength, minorAxisLength);
  }
  
  /// Returns a new ellipse obtained by scaling the major axis of this instance by the given
  /// \c majorAxisScaleFactor and the minor axis by the given \c minorAxisScaleFactor.
  Ellipse scaledBy(CGFloat majorAxisScaleFactor, CGFloat minorAxisScaleFactor) const {
    return Ellipse(center, angle, majorAxisLength * majorAxisScaleFactor,
                   minorAxisLength * minorAxisScaleFactor);
  }
  
  /// Returns a new ellipse obtained by rotating this instance by the given \c rotationAngle
  /// around the given \c anchorPoint. The given \c rotationAngle must be given in radians, in
  /// counter-clockwise direction in bottom-left coordinate system.
  Ellipse rotatedAroundPointBy(CGPoint anchorPoint, CGFloat rotationAngle) const {
    return Ellipse(LTRotatePoint(center, rotationAngle, anchorPoint), angle + rotationAngle,
                   majorAxisLength, minorAxisLength);
  }
  
  /// Returns a new ellipse obtained by rotating this instance by the given \c rotationAngle
  /// around \c center. The given \c rotationAngle must be given in radians, in counter-clockwise
  /// direction in bottom-left coordinate system.
  Ellipse rotatedBy(CGFloat rotationAngle) const {
    return Ellipse(LTRotatePoint(center, rotationAngle, center), angle + rotationAngle,
                   majorAxisLength, minorAxisLength);
  }
  
  /// Center of the ellipse.
  CGPoint center;
  
  /// Angle, in radians, between the x-axis and the major axis of the ellipse, in
  /// counter-clockwise direction in bottom-left coordinate system.
  CGFloat angle;
  
  /// Length of major axis of the ellipse.
  CGFloat majorAxisLength;
  
  /// Length of minor axis of the ellipse.
  CGFloat minorAxisLength;
};

constexpr bool operator==(const Ellipse &lhs, const Ellipse &rhs) {
  return lhs.center.x == rhs.center.x && lhs.center.y == rhs.center.y && lhs.angle == rhs.angle &&
      lhs.majorAxisLength == rhs.majorAxisLength && lhs.minorAxisLength == rhs.minorAxisLength;
}
  
constexpr bool operator!=(const Ellipse &lhs, const Ellipse &rhs) {
  return !(lhs == rhs);
}
  
} // namespace lt

#endif
