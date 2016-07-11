// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTParameterizedObjectConstructor.h"

#import "LTBasicParameterizedObjectFactories.h"
#import "LTCompoundParameterizedObjectFactory.h"
#import "LTControlPointModel.h"
#import "LTMutableEuclideanSpline.h"
#import "LTParameterizedObjectType.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark LTParameterizedObjectConstructorControlPointModel
#pragma mark -

/// Private subclass of the \c LTControlPointModel class for holding an \c LTMutableEuclideanSpline
/// constructed by an \c LTParameterizedObjectConstructor.
@interface LTParameterizedObjectConstructorControlPointModel : LTControlPointModel

/// Initializes with the given \c type and the given \c spline.
- (instancetype)initWithType:(LTParameterizedObjectType *)type
                      spline:(nullable LTMutableEuclideanSpline *)spline;

/// Spline constructed by an \c LTParameterizedObjectConstructor.
@property (readonly, nonatomic, nullable) LTMutableEuclideanSpline *spline;

@end

@implementation LTParameterizedObjectConstructorControlPointModel

- (instancetype)initWithType:(LTParameterizedObjectType *)type
                      spline:(nullable LTMutableEuclideanSpline *)spline {
  if (self = [super initWithType:type]) {
    _spline = spline;
  }
  return self;
}

- (NSArray<LTSplineControlPoint *> *)controlPoints {
  return self.spline ? self.spline.controlPoints : @[];
}

@end

#pragma mark -
#pragma mark LTParameterizedObjectConstructor
#pragma mark -

@interface LTParameterizedObjectConstructor ()

/// Type of the factory used for spline construction.
@property (strong, nonatomic) LTParameterizedObjectType *type;

/// Factory of primitive parameterized objects used as spline segments of the spline.
@property (strong, nonatomic) id<LTBasicParameterizedObjectFactory> factory;

/// Spline constructed by this instance.
@property (strong, nonatomic) LTMutableEuclideanSpline *spline;

/// Ordered collection used for temporarily buffering control points before construction of spline
/// becomes feasible. Is set to \c nil upon construction of the spline.
@property (strong, nonatomic, nullable) NSMutableArray<LTSplineControlPoint *> *buffer;

@end

@implementation LTParameterizedObjectConstructor

- (instancetype)initWithControlPointModel:(LTControlPointModel *)model {
  LTParameterAssert(model);

  if (self = [super init]) {
    if ([model isKindOfClass:[LTParameterizedObjectConstructorControlPointModel class]]) {
      LTParameterizedObjectConstructorControlPointModel *splineModel =
          (LTParameterizedObjectConstructorControlPointModel *)model;
      self.spline = splineModel.spline;
    }
    self.type = model.type;
    self.factory = [model.type factory];
    self.buffer = [NSMutableArray arrayWithCapacity:[[self.factory class] numberOfRequiredValues]];
    [self pushControlPoints:model.controlPoints];
  }
  return self;
}

- (void)pushControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints {
  if (self.spline) {
    [self.spline pushControlPoints:controlPoints];
    return;
  }

  [self.buffer addObjectsFromArray:controlPoints];

  if (self.buffer.count >= [[self.factory class] numberOfRequiredValues]) {
    LTCompoundParameterizedObjectFactory *factory =
        [[LTCompoundParameterizedObjectFactory alloc] initWithBasicFactory:self.factory];

    self.spline = [[LTMutableEuclideanSpline alloc] initWithFactory:factory
                                               initialControlPoints:self.buffer];
    self.buffer = nil;
    return;
  }
}

- (LTControlPointModel *)controlPointModel {
  return self.spline ?
      [[LTParameterizedObjectConstructorControlPointModel alloc] initWithType:self.type
                                                                       spline:self.spline] :
      [[LTControlPointModel alloc] initWithType:self.type controlPoints:[self.buffer copy]];
}

- (nullable id<LTParameterizedObject>)parameterizedObject {
  return self.spline;
}

@end

NS_ASSUME_NONNULL_END
