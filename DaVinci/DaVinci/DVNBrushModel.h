// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTInterval.h>

#import "DVNBrushModelVersion.h"

NS_ASSUME_NONNULL_BEGIN

@class LTTexture;

/// Immutable model representing a brush. A brush is determined by a set of well-defined parameters
/// in form of a model which can be used to construct corresponding objects capable of rendering
/// geometry along a curve, yielding a so-called brush stroke. The aforementioned geometry resides
/// in a well-defined two-dimensional orthonormal coordinate system called the "brush stroke
/// geometry coordinate system". The unit of both coordinate axes is inch, in order to ensure
/// device-independence.
///
/// There are two main ways for constructing aforementioned geometry:
/// a) "Brush tip geometry": the geometry is iteratively constructed as individual, possibly
/// overlapping "brush tips".
/// b) "Vector stroke geometry": the geometry is constructed as a consecutive set of non-overlapping
/// geometries.
///
/// Brush models have a unique version, the so-called brush model \c version, used to determine all
/// derived objects.
@interface DVNBrushModel : MTLModel <MTLJSONSerializing>

/// Returns a copy of the receiver with the exception of its spatial properties which are scaled by
/// the given \c scale.
///
/// @note Both the \c scale and the \c scaleRange values of the receiver are affected. For
/// construction of an identical copy with the exception of the value of the \c scale property, use
/// the \c copyWithScale: method.
- (instancetype)scaledBy:(CGFloat)scale;

/// Returns a copy of the receiver with the exception of the given \c scale, clamped to the
/// \c scaleRange of the receiver.
- (instancetype)copyWithScale:(CGFloat)scale;

/// Returns \c YES if the given \c textureMapping is valid for this model. In particular, checks
/// whether the keys of the given \c textureMapping are an appropriate subset of the
/// \c imageURLPropertyKeys of this class.
- (BOOL)isValidTextureMapping:(NSDictionary<NSString *, LTTexture *> *)textureMapping;

/// Returns the keys of the properties holding the URLs to the images required for rendering brush
/// strokes defined by the receiver.
+ (NSArray<NSString *> *)imageURLPropertyKeys;

/// Mapping between the enum values and the corresponding serialization strings used for
/// serialization of the \c version property of \c DVNBrushModel objects.
extern LTBidirectionalMap<DVNBrushModelVersion *, NSString *> * const kDVNBrushModelVersionMapping;

/// Version of this brush model. Value, when initializing with \c init method, is
/// \c DVNBrushModelVersionV1.
///
/// @note The mapping between the enum values and the corresponding serialization strings is
/// \c kDVNBrushModelVersionMapping.
@property (readonly, nonatomic) DVNBrushModelVersion *version;

/// Size, in inches, of the brush stroke. A value of \c 1 yields axis-aligned, square brush tips
/// with size <tt>(1, 1)</tt>, in floating-point units of the brush stroke geometry coordinate
/// system, in case of brush tip geometry. In case of vector stroke geometry, a value of \c 1 yields
/// geometry for a brush stroke with width \c 1 inch. When initializing with \c init method, this
/// value is \c 1.
///
/// @important This value is the reference point for all additional manipulations applied to the
/// geometry, such as rotations, random scalings based on additional parameters, distorations, etc.
@property (readonly, nonatomic) CGFloat scale;

/// Range of possible scales of the brush stroke. Refer to documentation of \c scale property for
/// more details. Value, when initializing with \c init method, is <tt>(0, CGFLOAT_MAX]</tt>.
@property (readonly, nonatomic) lt::Interval<CGFloat> scaleRange;

/// Allowed range of \c scaleRange.
@property (class, readonly, nonatomic) lt::Interval<CGFloat> allowedScaleRange;

@end

NS_ASSUME_NONNULL_END
