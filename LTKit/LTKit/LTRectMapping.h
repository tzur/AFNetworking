// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

@class LTRotatedRect;

#pragma mark -
#pragma mark Rects
#pragma mark -

/// Returns a 3x3 matrix which maps the canonical [0,1] x [0,1] rect to a normalized rect.
/// The normalized rect will always be inside the canonical rect, and is defined by placing the
/// given \c rect inside the rect [0,textureSize.width] x [0,textureSize.height] and normalizing to
/// [0,1] x [0,1].
GLKMatrix3 LTTextureMatrix3ForRect(CGRect rect, CGSize textureSize);

/// Returns a 3x3 matrix which maps the canonical [0,1] x [0,1] rect to the given \c rect.
GLKMatrix3 LTMatrix3ForRect(CGRect rect);

/// Returns a 4x4 matrix which maps the canonical [0,1] x [0,1] rect to the given \c rect. The z
/// coordinate is kept as is.
GLKMatrix4 LTMatrix4ForRect(CGRect rect);

#pragma mark -
#pragma mark Rotated rects
#pragma mark -

/// Returns a 3x3 matrix which maps the canonical [0,1] x [0,1] rect to a rotated normalized rect.
/// The normalized rect will always be inside the canonical rect, and is defined by placing the
/// given \c rotatedRect inside the rect [0,textureSize.width] x [0,textureSize.height] and
/// normalizing to [0,1] x [0,1].
GLKMatrix3 LTTextureMatrix3ForRotatedRect(LTRotatedRect *rotatedRect, CGSize textureSize);

/// Returns a 3x3 matrix which maps the canonical [0,1] x [0,1] rotated rect to the given \c
/// rotatedRect.
GLKMatrix3 LTMatrix3ForRotatedRect(LTRotatedRect *rotatedRect);

/// Returns a 4x4 matrix which maps the canonical [0,1] x [0,1] rotated rect to the given \c
/// rotatedRect. The z coordinate is kept as is.
GLKMatrix4 LTMatrix4ForRotatedRect(LTRotatedRect *rotatedRect);
