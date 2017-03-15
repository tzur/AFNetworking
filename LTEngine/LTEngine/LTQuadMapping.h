// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTQuad.h"

#pragma mark -
#pragma mark Canonical Square to Normalized Convex Quad in Homogeneous 3D space
#pragma mark -

/// Returns a <tt>3x3</tt> matrix which maps the canonical <tt>[0, 1] x [0, 1]</tt> square to a rect
/// in 3D space whose orthographic projection onto the XY plane corresponds to a normalized version
/// of the given \c quad. The normalized quad is defined by scaling the given \c quad by vector
/// <tt>(1 / size.width, 1 / size.height)</tt> around \c CGPointZero.
///
/// @important The projection to the XY plane requires division by the \c z coordinate.
GLKMatrix3 LTMatrix3ForNormalizedQuad(const lt::Quad &quad, CGSize size);

/// Returns a <tt>3x3</tt> matrix which maps the canonical <tt>[0, 1] x [0, 1]</tt> square to a rect
/// in 3D space whose orthographic projection onto the XY plane corresponds to a normalized version
/// of the given \c quad. The normalized quad is defined by scaling the given \c quad by vector
/// <tt>(1 / size.width, 1 / size.height)</tt> around \c CGPointZero.
///
/// @important The projection to the XY plane requires division by the \c z coordinate.
static inline GLKMatrix3 LTTextureMatrix3ForQuad(LTQuad *quad, CGSize size) {
  return LTMatrix3ForNormalizedQuad(quad.quad, size);
}

#pragma mark -
#pragma mark Canonical Square to Convex Quad in Homogeneous 3D space
#pragma mark -

/// Returns a <tt>3x3</tt> matrix which maps the canonical <tt>[0, 1] x [0, 1]</tt> square to a rect
/// in 3D space whose orthographic projection onto the XY plane corresponds to the given \c quad.
///
/// @important The projection to the XY plane requires division by the \c z coordinate.
GLKMatrix3 LTMatrix3ForQuad(const lt::Quad &quad);

/// Returns a <tt>3x3</tt> matrix which maps the canonical <tt>[0, 1] x [0, 1]</tt> square to a rect
/// in 3D space whose orthographic projection onto the XY plane corresponds to the given \c quad.
///
/// @important The projection to the XY plane requires division by the \c z coordinate.
static inline GLKMatrix3 LTMatrix3ForQuad(LTQuad *quad) {
  return LTMatrix3ForQuad(quad.quad);
}

#pragma mark -
#pragma mark Convex Quad to Rect in Homogeneous 3D space
#pragma mark -

/// Returns a <tt>3x3</tt> matrix which maps the given \c quad to the rect
/// <tt>[0, size.width] x [0, size.height]. Returns the zero matrix if \c LTMatrix3ForQuad(quad) is
/// not invertible.
///
/// @important The projection to the XY plane requires division by the \c z coordinate.
GLKMatrix3 LTInvertedMatrix3ForQuad(const lt::Quad &quad, CGSize size);

/// Returns a <tt>3x3</tt> matrix which maps the given \c quad to the rect
/// <tt>[0, size.width] x [0, size.height]. Returns the zero matrix if \c LTMatrix3ForQuad(quad) is
/// not invertible.
///
/// @important The projection to the XY plane requires division by the \c z coordinate.
static inline GLKMatrix3 LTInvertedTextureMatrix3ForQuad(LTQuad *quad, CGSize size) {
  return LTInvertedMatrix3ForQuad(quad.quad, size);
}

#pragma mark -
#pragma mark Canonical Square to Quad in Homogeneous 4D space
#pragma mark -

/// Returns a <tt>4x4</tt> matrix which maps the canonical <tt>[0, 1] x [0, 1]</tt> square to the
/// given \c quad. The \c z coordinate is kept as is. Can be used, e.g., for the \c modelview matrix
/// in vertex shaders.
///
/// @important The projection to the XY plane requires division by the \c w coordinate.
GLKMatrix4 LTMatrix4ForQuad(const lt::Quad &quad);

/// Returns a <tt>4x4</tt> matrix which maps the canonical <tt>[0, 1] x [0, 1]</tt> square to the
/// given \c quad. The \c z coordinate is kept as is. Can be used, e.g., for the \c modelview matrix
/// in vertex shaders.
///
/// @important The projection to the XY plane requires division by the \c w coordinate.
static inline GLKMatrix4 LTMatrix4ForQuad(LTQuad *quad) {
  return LTMatrix4ForQuad(quad.quad);
}
