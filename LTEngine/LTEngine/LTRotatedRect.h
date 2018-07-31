// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

NS_ASSUME_NONNULL_BEGIN

/// Represents rotated (i.e. not up-right) rectangles on a plane. Each rectangle is described by a
/// CGRect, and the angle in radians which the rectangle is rotated (clockwise, around its center).
@interface LTRotatedRect : NSObject <NSCopying>

/// Returns an unrotated rect (angle is \c 0).
+ (instancetype)rect:(CGRect)rect;

/// Returns a rotated rect with the given \c rect, rotated around its center in \c angle radians.
+ (instancetype)rect:(CGRect)rect withAngle:(CGFloat)angle;

/// Returns a rotated rect with the given \c center, unrotated \c size and rotation of \c angle
/// radians around \c center.
+ (instancetype)rectWithCenter:(CGPoint)center size:(CGSize)size angle:(CGFloat)angle;

/// Returns a rotated rect with the given \c size, \c translation from origin, \c scaling around the
/// center and \c rotation radians around the center of the rect.
+ (instancetype)rectWithSize:(CGSize)size translation:(CGPoint)translation scaling:(CGFloat)scaling
                 andRotation:(CGFloat)rotation;

/// Returns a rotated square with the given \c center, edge \c length and rotation of \c angle
/// radians around center.
+ (instancetype)squareWithCenter:(CGPoint)center length:(CGFloat)length angle:(CGFloat)angle;

/// Initializes with \c rect of \c CGRectZero and no rotation.
- (instancetype)init;

/// Initialzes a rotated rect with the given \c center, \c size and rotation of \c angle radians
/// around \c center.
- (instancetype)initWithCenter:(CGPoint)center size:(CGSize)size angle:(CGFloat)angle;

/// Initializes a rotated rect with the given \c rect and \c angle radians around the center of
/// \c rect.
- (instancetype)initWithRect:(CGRect)rect angle:(CGFloat)angle NS_DESIGNATED_INITIALIZER;

/// Returns \c YES if the given \c point lies inside the rect. A point is considered inside the
/// rectangle if its coordinates lie inside the rectangle or on the minimum X or minimum Y edge.
- (BOOL)containsPoint:(CGPoint)point;

/// Unrotated rect.
@property (readonly, nonatomic) CGRect rect;

/// Rotation angle (clockwise), in radians, in the range <tt>[0, 2π]</tt>
@property (readonly, nonatomic) CGFloat angle;

/// Center of the rotated rect.
@property (readonly, nonatomic) CGPoint center;

/// First vertex of the rotated rect, in clockwise order. Matches the top-left corner of \c rect
/// prior to the rotation.
@property (readonly, nonatomic) CGPoint v0;

/// Second vertex of the rotated rect, in clockwise order. Matches the top-right corner of \c rect
/// prior to the rotation.
@property (readonly, nonatomic) CGPoint v1;

/// Third vertex of the rotated rect, in clockwise order. Matches the bottom-right corner of \c rect
/// prior to the rotation.
@property (readonly, nonatomic) CGPoint v2;

/// Fourth vertex of the rotated rect, in clockwise order. Matches the bottom-left corner of \c rect
/// prior to the rotation.
@property (readonly, nonatomic) CGPoint v3;

/// Affine transform used to rotate the rect around its center.
@property (readonly, nonatomic) CGAffineTransform transform;

/// Rect that bounds the rotated rect. For non-rotated rects, \c rect will be returned.
@property (readonly, nonatomic) CGRect boundingRect;

@end

NS_ASSUME_NONNULL_END
