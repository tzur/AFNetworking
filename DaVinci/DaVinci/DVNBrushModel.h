// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNBrushModelVersion.h"

NS_ASSUME_NONNULL_BEGIN

/// Immutable model representing a brush. A brush is determined by a set of well-defined parameters
/// in form of a model which can be used to construct corresponding objects capable of rendering
/// geometry along a curve, yielding a so-called brush stroke. The aforementioned geometry resides
/// in a well-defined coordinate system called the "brush stroke geometry coordinate system".
/// Conceptually the coordinate system is divided by a grid of square, axis-aligned pixels
/// determining the units of the coordinate system, in floating-point precision.
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

/// Scale of the brush stroke. A value of \c 1 yields axis-aligned, square brush tips with size
/// <tt>(1, 1)</tt>, in floating-point units of the brush stroke geometry coordinate system, in case
/// of brush tip geometry. In case of vector stroke geometry, a value of \c 1 yields geometry for a
/// brush stroke with width \c 1, in floating-point units of the brush stroke geometry coordinate
/// system. When initializing with \c init method, this value is \c 1.
///
/// @important This value is the reference point for all additional manipulations applied to the
/// geometry, such as rotations, random scalings based on additional parameters, distorations, etc.
@property (readonly, nonatomic) CGFloat scale;

/// Minimum scale of the brush stroke. Refer to documentation of \c scale property for more details.
/// Value, when initializing with \c init method, is \c 0.
@property (readonly, nonatomic) CGFloat minScale;

/// Maximum scale of the brush stroke. Refer to documentation of \c scale property for more details.
/// Value, when initializing with \c init method, is \c CGFLOAT_MAX.
@property (readonly, nonatomic) CGFloat maxScale;

@end

NS_ASSUME_NONNULL_END
