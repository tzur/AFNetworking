// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

@class LTSplineControlPoint;

/// Creates an array of \c LTSplineControlPoint objects with the given \c timestamps,
/// \c locations and \c attributes. The number of elements in the given \c timestamps, the number of
/// elements in the given \c locations and the number of elements in every array in \c values
/// must all be equal.
NSArray<LTSplineControlPoint *> * LTCreateSplinePoints(std::vector<CGFloat> timestamps,
                                                       std::vector<CGPoint> locations,
                                                       NSString *attributeKey,
                                                       NSArray<NSNumber *> *values);
