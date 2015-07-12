// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTCommonDrawableShape.h"
#import "LTDrawableShape.h"

@class LTRotatedRect;

/// A class used for drawing (and filling) anti-aliased elliptic shapes.
@interface LTShapeDrawerEllipticShape : LTCommonDrawableShape <LTDrawableShape>

/// Initializes an ellipse fitting the given rotated rect. The generated ellipse is centered at the
/// origin, and aligned to the axes. The \c translation and \c rotationAngle properties are set
/// according to the rotated rect's angle and center.
- (instancetype)initWithRotatedRect:(LTRotatedRect *)rotatedRect filled:(BOOL)filled
                             params:(LTShapeDrawerParams *)params;

/// \c YES iff the generated shape is a filled ellipse.
@property (readonly, nonatomic) BOOL filled;

/// Size of the unrotated ellipse.
@property (readonly, nonatomic) CGSize size;

@end
