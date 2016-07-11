// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSplineControlPoint.h"

#import <LTEngine/LTContentTouchEvent.h>

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting the \c LTSplineControlPoint class with the ability to construct
/// \c LTSplineControlPoint objects from \c id<LTContentTouchEvent> objects.
@interface LTSplineControlPoint (ContentTouchEvent)

/// Returns an ordered collection of \c LTSplineControlPoint objects, each constructed from the
/// corresponding \c LTContentTouchEvent of the given \c events. Each of the returned control points
/// possesses following \c attributes:
///
/// - the \c majorContentRadius value of the corresponding \c LTContentTouchEvent, accessible via
/// key <tt>[LTSplineControlPoint keyForRadius]</tt>,
///
/// - optionally, the \c force value of the corresponding \c LTContentTouchEvent, accessible via key
/// <tt>[LTSplineControlPoint keyForForce]</tt>. The \c force value is added to the control point if
/// the corresponding content touch event provides such a value.
+ (NSArray<LTSplineControlPoint *> *)pointsFromTouchEvents:(LTContentTouchEvents *)events;

@end

NS_ASSUME_NONNULL_END
