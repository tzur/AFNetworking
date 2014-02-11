// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Represents rotated (i.e. not up-right) rectangles on a plane. Each rectangle is described by a
/// CGRect, and the angle, in radians, which the rectangle is rotated (around its center).
@interface LTRotatedRect : NSObject

/// Returns a rotated rect with the given angle (in radians).
+ (instancetype)rect:(CGRect)rect withAngle:(CGFloat)angle;

/// Returns a rotated rect with the given center, size (unrotated) and angle (in radians).
+ (instancetype)rectWithCenter:(CGPoint)center size:(CGSize)size angle:(CGFloat)angle;

/// Returns a rotated square with the given center, edge length and angle (in radians).
+ (instancetype)squareWithCenter:(CGPoint)center length:(CGFloat)length angle:(CGFloat)angle;

/// Initializes the rotated rect with the given rect and angle (in radians).
- (instancetype)initWithRect:(CGRect)rect angle:(CGFloat)angle;

/// Initialzes the rotated rect with the given center, size (unrotated) and angle (in
/// radians).
- (instancetype)initWithCenter:(CGPoint)center size:(CGSize)size angle:(CGFloat)angle;

/// Returns the unrotated rect.
@property (readonly, nonatomic) CGRect rect;
/// Returns the rotation angle, in radians.
@property (readonly, nonatomic) CGFloat angle;
/// Returns the center of the rotated rect.
@property (readonly, nonatomic) CGPoint center;

/// Returns the first vertex of the rotated rect, in clockwise order.
@property (readonly, nonatomic) CGPoint v0;
/// Returns the second vertex of the rotated rect, in clockwise order.
@property (readonly, nonatomic) CGPoint v1;
/// Returns the third vertex of the rotated rect, in clockwise order.
@property (readonly, nonatomic) CGPoint v2;
/// Returns the fourth vertex of the rotated rect, in clockwise order.
@property (readonly, nonatomic) CGPoint v3;

/// Returns the affine transform used to rotate the rect around its center.
@property (readonly, nonatomic) CGAffineTransform transform;

@end
