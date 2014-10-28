// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

@class LTQuad;

/// Returns a 3x3 matrix which maps the canonical [0,1] x [0,1] rect to a normalized quad.
/// The normalized quad will always be inside the canonical rect, and is defined by placing the
/// given \c quad inside the rect [0,textureSize.width] x [0,textureSize.height] and
/// normalizing to [0,1] x [0,1].
GLKMatrix3 LTTextureMatrix3ForQuad(LTQuad *quad, CGSize textureSize);

/// Returns a 3x3 matrix which maps the canonical [0,1] x [0,1] rect to the given \c quad.
GLKMatrix3 LTMatrix3ForQuad(LTQuad *quad);

/// Returns a 4x4 matrix which maps the canonical [0,1] x [0,1] rect to the given \c quad. The z
/// coordinate is kept as is. Is used, e.g., for the \c modelview matrix in vertex shaders.
GLKMatrix4 LTMatrix4ForQuad(LTQuad *quad);
