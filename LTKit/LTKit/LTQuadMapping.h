// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

@class LTQuad;

/// Returns a 3x3 matrix which maps the canonical [0,1] x [0,1] rect to a rect in 3D space
/// corresponding to a normalized version of the given \c quad. The normalized quad is defined by
/// placing the given \c quad inside the rect [0,textureSize.width] x [0,textureSize.height] and
/// normalizing to [0,1] x [0,1]. Note that projection to the XY plane requires division by the z
/// coordinate.
GLKMatrix3 LTTextureMatrix3ForQuad(LTQuad *quad, CGSize textureSize);

/// Returns a 3x3 matrix which maps the canonical [0,1] x [0,1] rect to a rect in 3D space
/// corresponding to the given \c quad. Note that projection to the XY plane requires division by
/// the z coordinate.
GLKMatrix3 LTMatrix3ForQuad(LTQuad *quad);

/// Returns a 3x3 matrix which maps the given \c quad to the rect [\c 0, \c textureSize.width] x
/// [\c 0, \c textureSize.height]. Returns the zero matrix if \c LTMatrix3ForQuad(quad) is not
/// invertible.  Note that projection to the XY plane requires division by the z coordinate.
GLKMatrix3 LTInvertedTextureMatrix3ForQuad(LTQuad *quad, CGSize textureSize);

/// Returns a 4x4 matrix which maps the canonical [0,1] x [0,1] rect to the given \c quad. The z
/// coordinate is kept as is. Is used, e.g., for the \c modelview matrix in vertex shaders. Note
/// that projection to the XY plane requires division by the w coordinate.
GLKMatrix4 LTMatrix4ForQuad(LTQuad *quad);
