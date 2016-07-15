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
@property (readonly, nonatomic) LTParameterizedObjectType *type;

/// Factory of primitive parameterized objects used as spline segments of the spline.
@property (readonly, nonatomic) id<LTBasicParameterizedObjectFactory> factory;

/// Spline constructed by this instance.
@property (strong, nonatomic, nullable) LTMutableEuclideanSpline *spline;

/// Ordered collection used for temporarily buffering control points before construction of spline
/// becomes feasible. Is set to \c nil upon construction of the spline.
@property (strong, nonatomic, nullable) NSMutableArray<LTSplineControlPoint *> *buffer;

@end

@implementation LTParameterizedObjectConstructor

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithType:(LTParameterizedObjectType *)type {
  LTParameterAssert(type);

  if (self = [super init]) {
    _type = type;
    _factory = [type factory];
    [self reset];
  }
  return self;
}

- (LTControlPointModel *)reset {
  LTControlPointModel *model;
  if (self.spline) {
    model = [[LTParameterizedObjectConstructorControlPointModel alloc] initWithType:self.type
                                                                             spline:self.spline];
  } else if (self.buffer.count) {
    model = [[LTControlPointModel alloc] initWithType:self.type controlPoints:[self.buffer copy]];
  } else {
    model = [[LTControlPointModel alloc] initWithType:self.type];
  }
  self.spline = nil;
  self.buffer = [NSMutableArray arrayWithCapacity:[[self.factory class] numberOfRequiredValues]];
  return model;
}

#pragma mark -
#pragma mark Public API
#pragma mark -

+ (nullable id<LTParameterizedObject>)parameterizedObjectFromModel:(LTControlPointModel *)model {
  if ([model isKindOfClass:[LTParameterizedObjectConstructorControlPointModel class]]) {
    return ((LTParameterizedObjectConstructorControlPointModel *)model).spline;
  }

  LTParameterizedObjectConstructor *constructor =
      [[LTParameterizedObjectConstructor alloc] initWithType:model.type];
  [constructor pushControlPoints:model.controlPoints];
  return constructor.parameterizedObject;
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

- (nullable id<LTParameterizedObject>)parameterizedObject {
  return self.spline;
}

@end

NS_ASSUME_NONNULL_END
