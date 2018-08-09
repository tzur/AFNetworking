// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#if defined(DEBUG) && DEBUG
  #define USE_BIPARTITE_GRAPH 1
#else
  #define USE_BIPARTITE_GRAPH 0
#endif

#if USE_BIPARTITE_GRAPH
  #define LT_POTENTIALLY_UNUSED
#else
  #define LT_POTENTIALLY_UNUSED __unused
#endif

#import "LTMutableEuclideanSpline.h"

#if USE_BIPARTITE_GRAPH
#import <LTKit/LTBipartiteGraph.h>
#endif

#import "LTCompoundParameterizedObject.h"
#import "LTCompoundParameterizedObjectFactory.h"
#import "LTParameterizedObjectStack.h"
#import "LTReparameterization+ArcLength.h"
#import "LTReparameterizedObject.h"
#import "LTSplineControlPoint.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTMutableEuclideanSpline ()

/// Factory used to extend this spline with additional spline segments.
@property (strong, nonatomic) LTCompoundParameterizedObjectFactory *factory;

/// Mutable ordered collection of control points of this instance.
@property (strong, nonatomic) NSMutableArray<LTSplineControlPoint *> *mutableControlPoints;

#if USE_BIPARTITE_GRAPH
/// Bipartite graph connecting control points and spline segments.
@property (strong, nonatomic) LTBipartiteGraph *mutableGraph;
#endif

/// Stack of parameterized objects each of which represents a spline segment of this instance.
@property (strong, nonatomic) LTParameterizedObjectStack *mutableStack;

/// Index of the control point constituting the end of the intrinsic parametric range of this
/// spline.
@property (nonatomic) NSUInteger indexOfControlPointAtEndOfIntrinsicParametricRange;

@end

@implementation LTMutableEuclideanSpline

/// Number of sample points used to approximate the arc-length of a spline segment.
static const NSUInteger kNumberOfSamplesForArcLengthApproximation = 50;

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithFactory:(LTCompoundParameterizedObjectFactory *)factory
           initialControlPoints:(NSArray<LTSplineControlPoint *> *)initialControlPoints {
  LTParameterAssert(initialControlPoints.count >= factory.numberOfRequiredInterpolatableObjects,
                    @"Number (%lu) of control points must not be smaller than number (%lu) of "
                    "required interpolatable objects", (unsigned long)initialControlPoints.count,
                    (unsigned long)factory.numberOfRequiredInterpolatableObjects);

  if (self = [super init]) {
    self.factory = factory;
    self.mutableControlPoints = [NSMutableArray arrayWithCapacity:initialControlPoints.count];
#if USE_BIPARTITE_GRAPH
    self.mutableGraph = [[LTBipartiteGraph alloc] init];
#endif
    [self pushControlPoints:initialControlPoints];
  }
  return self;
}

#pragma mark -
#pragma mark Pushing Control Points
#pragma mark -

- (void)pushControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints {
  if (!controlPoints.count) {
    return;
  }

  [self addControlPointsToDataStructures:controlPoints];

  NSUInteger index = [self startIndexOfInvolvedControlPoints];
  LTAssert(index < self.numberOfControlPoints,
           @"Computed index (%lu) must be smaller than the current number of control points (%lu)",
           (unsigned long)index, (unsigned long)self.numberOfControlPoints);

  if (self.numberOfControlPoints - index < self.numberOfRequiredInterpolatableObjects) {
    // No new spline segments have to be created since the number of control points which should be
    // used for the creation of the corresponding parameterized object is lower than the number of
    // interpolatable objects required by the factory.
    return;
  }

  [self extendSplineWithSegmentsUsingControlPointsStartingAtIndex:index];
}

- (void)addControlPointsToDataStructures:(NSArray<LTSplineControlPoint *> *)controlPoints {
  LTSplineControlPoint *previousControlPoint = self.mutableControlPoints.lastObject;
  for (LTSplineControlPoint *controlPoint in controlPoints) {
    if (previousControlPoint) {
      LTParameterAssert(previousControlPoint.timestamp <= controlPoint.timestamp,
                        @"Timestamp of control point (%@) must not be greater than timestamp of "
                        "control point (%@)", previousControlPoint, controlPoint);
    }
    previousControlPoint = controlPoint;
    [self.mutableControlPoints addObject:controlPoint];
#if USE_BIPARTITE_GRAPH
    [self.mutableGraph addVertex:controlPoint toPartition:LTBipartiteGraphPartitionA];
#endif
  }
}

- (NSUInteger)startIndexOfInvolvedControlPoints {
  if (!self.numberOfSegments) {
    return 0;
  }

  NSRange range = self.intrinsicParametricRange;
  LTAssert(self.indexOfControlPointAtEndOfIntrinsicParametricRange > range.location,
           @"Index (%lu) of the control point at the end of the intrinsic parametric range of the "
           "spline must be greater than or equal to the number (%lu) of control points required for"
           "construction of spline segments",
           (unsigned long)self.indexOfControlPointAtEndOfIntrinsicParametricRange,
           (unsigned long)range.location);
  return self.indexOfControlPointAtEndOfIntrinsicParametricRange - range.location;
}

- (void)extendSplineWithSegmentsUsingControlPointsStartingAtIndex:(NSUInteger)index {
  NSRange range = self.intrinsicParametricRange;
  LTAssert(range.length > 1, @"Provided factory (%@) with invalid length of range", self.factory);

  NSUInteger windowSize = self.numberOfRequiredInterpolatableObjects;
  NSUInteger stepSize = range.length - 1;

  if (index + windowSize - 1 >= self.numberOfControlPoints) {
    return;
  }

  for (NSUInteger i = index; i < self.numberOfControlPoints - windowSize + 1; i += stepSize) {
    [self extendSplineWithSingleSegmentUsingControlPointsStartingAtIndex:i windowSize:windowSize];
  }

  NSUInteger numberOfIterations =
      std::ceil((CGFloat)(self.numberOfControlPoints - windowSize + 1 - index) / stepSize);

  self.indexOfControlPointAtEndOfIntrinsicParametricRange =
      index + numberOfIterations * stepSize + range.location;
}

- (void)extendSplineWithSingleSegmentUsingControlPointsStartingAtIndex:(NSUInteger)index
                                                            windowSize:(NSUInteger)windowSize {
  NSArray<LTSplineControlPoint *> *controlPointsInWindow =
      [self.mutableControlPoints subarrayWithRange:NSMakeRange(index, windowSize)];
  LTCompoundParameterizedObject *segment =
      [self.factory parameterizedObjectFromInterpolatableObjects:controlPointsInWindow];
  id<LTParameterizedValueObject> reparameterizedSegment =
      [self segmentFromSegment:segment reparameterizedWithMinValue:self.maxParametricValue];

  [self addSegment:reparameterizedSegment forControlPoints:controlPointsInWindow];
}

- (id<LTParameterizedValueObject>)segmentFromSegment:(LTCompoundParameterizedObject *)segment
                         reparameterizedWithMinValue:(CGFloat)minParametricValue {
  LTReparameterization *reparameterization =
      [LTReparameterization
       arcLengthReparameterizationForObject:segment
       numberOfSamples:kNumberOfSamplesForArcLengthApproximation
       minParametricValue:minParametricValue
       parameterizationKeyForXCoordinate:@keypath(self.mutableControlPoints.firstObject,
                                                  xCoordinateOfLocation)
       parameterizationKeyForYCoordinate:@keypath(self.mutableControlPoints.firstObject,
                                                  yCoordinateOfLocation)];
  if (!reparameterization) {
    return segment;
  }
  return [[LTReparameterizedObject alloc] initWithParameterizedObject:segment
                                                   reparameterization:reparameterization];
}

- (void)addSegment:(LTReparameterizedObject *)segment
  forControlPoints:(NSArray<LTSplineControlPoint *> LT_POTENTIALLY_UNUSED *)controlPoints {
#if USE_BIPARTITE_GRAPH
  [self.mutableGraph addVertex:segment toPartition:LTBipartiteGraphPartitionB];
  [self.mutableGraph addEdgesBetweenVertex:segment andVertices:[NSSet setWithArray:controlPoints]];
#endif

  if (!self.mutableStack) {
    self.mutableStack = [[LTParameterizedObjectStack alloc] initWithParameterizedObject:segment];
  } else {
    [self.mutableStack pushParameterizedObject:segment];
  }
}

#pragma mark -
#pragma mark LTParameterizedObject
#pragma mark -

- (LTParameterizationKeyToValue *)mappingForParametricValue:(CGFloat)value {
  return [self.mutableStack mappingForParametricValue:value];
}

- (LTParameterizationKeyToValues *)mappingForParametricValues:(const CGFloats &)values {
  return [self.mutableStack mappingForParametricValues:values];
}

- (CGFloat)floatForParametricValue:(CGFloat)value key:(NSString *)key {
  return [self.mutableStack floatForParametricValue:value key:key];
}

- (CGFloats)floatsForParametricValues:(const CGFloats &)values key:(NSString *)key {
  return [self.mutableStack floatsForParametricValues:values key:key];
}

- (NSSet<NSString *> *)parameterizationKeys {
  return [self.mutableStack parameterizationKeys];
}

- (CGFloat)minParametricValue {
  return self.mutableStack.minParametricValue;
}

- (CGFloat)maxParametricValue {
  return self.mutableStack.maxParametricValue;
}

#pragma mark -
#pragma mark Public Properties
#pragma mark -

- (NSArray<LTSplineControlPoint *> *)controlPoints {
  return [self.mutableControlPoints copy];
}

- (NSUInteger)numberOfControlPoints {
  return self.mutableControlPoints.count;
}

- (NSArray<id<LTParameterizedObject>> *)segments {
  return [self.mutableStack.parameterizedObjects copy];
}

- (NSUInteger)numberOfSegments {
  return self.mutableStack.count;
}

#pragma mark -
#pragma mark Private Properties
#pragma mark -

- (NSUInteger)numberOfRequiredInterpolatableObjects {
  return self.factory.numberOfRequiredInterpolatableObjects;
}

- (NSRange)intrinsicParametricRange {
  return self.factory.intrinsicParametricRange;
}

@end

NS_ASSUME_NONNULL_END
