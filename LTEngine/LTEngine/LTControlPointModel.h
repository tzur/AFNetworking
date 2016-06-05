// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTEuclideanSplineControlPoint, LTParameterizedObjectType;

/// Value class holding control points of a Euclidean spline and the type of a factory which can be
/// used to construct a corresponding Euclidean spline from the control points.
@interface LTControlPointModel : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c type. The \c controlPoints collection of the returned object is
/// empty.
- (instancetype)initWithType:(LTParameterizedObjectType *)type;

/// Initializes with the given \c type and a copy of the given \c controlPoints.
- (instancetype)initWithType:(LTParameterizedObjectType *)type
               controlPoints:(NSArray<LTEuclideanSplineControlPoint *> *)controlPoints
    NS_DESIGNATED_INITIALIZER;

/// Type of factory used to construct segments of a Euclidean spline.
@property (readonly, nonatomic) LTParameterizedObjectType *type;

/// Control points of a Euclidean spline.
@property (readonly, nonatomic) NSArray<LTEuclideanSplineControlPoint *> *controlPoints;

@end

NS_ASSUME_NONNULL_END
