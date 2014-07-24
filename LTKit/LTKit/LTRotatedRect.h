// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Represents rotated (i.e. not up-right) rectangles on a plane. Each rectangle is described by a
/// CGRect, and the angle in radians which the rectangle is rotated (clockwise, around its center).
@interface LTRotatedRect : NSObject <NSCopying>

/// Returns an unrotated rect (angle is \c 0).
+ (instancetype)rect:(CGRect)rect;

/// Returns a rotated rect with the given angle (in radians).
+ (instancetype)rect:(CGRect)rect withAngle:(CGFloat)angle;

/// Returns a rotated rect with the given center, size (unrotated) and angle (in radians).
+ (instancetype)rectWithCenter:(CGPoint)center size:(CGSize)size angle:(CGFloat)angle;

/// Returns a rotated rect with the given size, translation, scaling around the center and rotation.
+ (instancetype)rectWithSize:(CGSize)size translation:(CGPoint)translation scaling:(CGFloat)scaling
                 andRotation:(CGFloat)rotation;

/// Returns a rotated square with the given center, edge length and angle (in radians).
+ (instancetype)squareWithCenter:(CGPoint)center length:(CGFloat)length angle:(CGFloat)angle;

/// Designated initializer: the rotated rect with the given rect and angle (in radians).
- (instancetype)initWithRect:(CGRect)rect angle:(CGFloat)angle;

/// Initialzes the rotated rect with the given center, size (unrotated) and angle (in
/// radians).
- (instancetype)initWithCenter:(CGPoint)center size:(CGSize)size angle:(CGFloat)angle;

/// Unrotated rect.
@property (readonly, nonatomic) CGRect rect;
/// Rotation angle (clockwise), in radians.
@property (readonly, nonatomic) CGFloat angle;
/// Center of the rotated rect.
@property (readonly, nonatomic) CGPoint center;

/// First vertex of the rotated rect, in clockwise order.
@property (readonly, nonatomic) CGPoint v0;
/// Second vertex of the rotated rect, in clockwise order.
@property (readonly, nonatomic) CGPoint v1;
/// Third vertex of the rotated rect, in clockwise order.
@property (readonly, nonatomic) CGPoint v2;
/// Fourth vertex of the rotated rect, in clockwise order.
@property (readonly, nonatomic) CGPoint v3;

/// Affine transform used to rotate the rect around its center.
@property (readonly, nonatomic) CGAffineTransform transform;

@end
