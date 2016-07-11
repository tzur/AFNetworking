// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTBrushGeometryProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Object providing geometry constructed from samples of a given parameterized object.
@interface LTDefaultBrushGeometryProvider : NSObject <LTBrushGeometryProvider,
    LTBrushGeometryProviderModel>

/// Initializes with the given \c edgeLength and the given \c edgeLengthPropertyKey. The width and
/// height of any rotated rect provided by this object equals the given \c edgeLength. The given
/// \c edgeLength must be greater than \c 0.
- (instancetype)initWithEdgeLength:(CGFloat)edgeLength;

/// Returns an ordered collection of rotated rects representing geometry constructed from samples,
/// at the given \c parametricValues, of the given parameterized \c object. Every returned rotated
/// rect has the \c edgeLength provided upon initialization and an \c angle of \c 0.
///
/// @important The \c parameterizationKeys of the given parameterized \c object must contain
/// <tt>@instanceKeypath(LTSplineControlPoint, xCoordinateOfLocation)</tt> and
/// <tt>@instanceKeypath(LTSplineControlPoint, yCoordinateOfLocation)</tt>.
- (NSArray<LTRotatedRect *> *)rotatedRectsFromParameterizedObject:(id<LTParameterizedObject>)object
                                               atParametricValues:(CGFloats)parametricValues;

/// Returns a single rotated rect representing geometry constructed from the given \c point. The
/// returned rotated rect has the \c edgeLength provided upon initialization and an \c angle of
/// \c 0.
- (LTRotatedRect *)rotatedRectFromControlPoint:(LTSplineControlPoint *)point;

/// Returns this object, due to immutability.
- (id<LTBrushGeometryProviderModel>)currentModel;

/// Returns this object, due to immutability.
- (LTDefaultBrushGeometryProvider *)provider;

/// Edge length of any rotated rect provided by this object.
@property (readonly, nonatomic) CGFloat edgeLength;

@end

NS_ASSUME_NONNULL_END
