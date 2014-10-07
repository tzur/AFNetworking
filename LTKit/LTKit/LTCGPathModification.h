// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

/// Augments every vertex of the provided \c path by a z coordinate of 1, multiplies the vertex with
/// the provided 3x3 \c transform matrix, projects the point back onto the z plane and returns the
/// resulting modified path.
CGMutablePathRef LTCGPathApplyTransform(CGPathRef path, GLKMatrix3 &transform);
