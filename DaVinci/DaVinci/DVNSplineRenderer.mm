// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSplineRenderer.h"

#import <LTEngine/LTBasicParameterizedObjectFactory.h>
#import <LTEngine/LTControlPointModel.h>
#import <LTEngine/LTParameterizedObjectConstructor.h>
#import <LTEngine/LTParameterizedObjectType.h>

#import "DVNPipeline.h"
#import "DVNPipelineConfiguration.h"
#import "DVNSplineRenderModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVNSplineRenderer () <DVNPipelineDelegate>

/// Delegate informed about render events.
@property (weak, readonly, nonatomic) id<DVNSplineRenderingDelegate> delegate;

/// Pipeline performing the rendering based on the spline provided by the \c splineConstructor.
@property (readonly, nonatomic) DVNPipeline *pipeline;

/// Object used to construct the parameterized object used by the render pipeline.
@property (readonly, nonatomic) LTParameterizedObjectConstructor *splineConstructor;

/// Parameterized object type of the \c splineConstructor.
@property (readonly, nonatomic) LTParameterizedObjectType *type;

/// Configuration of the \c pipeline at the beginning of the current processing sequence. Is updated
/// in every call to the \c reset method.
@property (strong, nonatomic) DVNPipelineConfiguration *sequenceStartConfiguration;

/// Last interval used in most recent render sequence. Is reset to the empty <tt>(0, 0)</tt>
/// interval in every call to the \c reset method. Initial value is the empty <tt>(0, 0)</tt>
/// interval.
@property (nonatomic) lt::Interval<CGFloat> lastIntervalUsedInLastSequence;

/// Indication whether this instance has not yet processed a new control point sequence.
@property (nonatomic) BOOL firstRenderCallOfSequence;

@end

@implementation DVNSplineRenderer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithType:(LTParameterizedObjectType *)type
               configuration:(DVNPipelineConfiguration *)configuration
                    delegate:(nullable id<DVNSplineRenderingDelegate>)delegate {
  LTParameterAssert(type);
  LTParameterAssert(configuration);

  if (self = [super init]) {
    _delegate = delegate;
    _pipeline = [[DVNPipeline alloc] initWithConfiguration:configuration];
    _type = type;
    _splineConstructor = [[LTParameterizedObjectConstructor alloc] initWithType:type];
    self.pipeline.delegate = self;
    [self reset];
  }
  return self;
}

- (void)reset {
  LTAssert(self.pipeline);
  self.sequenceStartConfiguration = [self.pipeline currentConfiguration];
  self.lastIntervalUsedInLastSequence = lt::Interval<CGFloat>();
  self.firstRenderCallOfSequence = YES;
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (void)processControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints end:(BOOL)end {
  [self processControlPoints:controlPoints preserveState:NO end:end];
}

- (void)processControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints
               preserveState:(BOOL)preserveState end:(BOOL)end {
  [self.splineConstructor pushControlPoints:controlPoints];

  if (!self.splineConstructor.parameterizedObject && !preserveState && !end) {
    // Didn't collect enough points for valid parameterizedObject and the rendering isn't required.
    return;
  }

  // Pad the parameterized object till it's valid, when there's an end indication.
  NSUInteger numberOfPaddedPoints = 0;
  if (!self.splineConstructor.parameterizedObject && end) {
    numberOfPaddedPoints = [self padParameterizedObjectUntilItIsValid];
  }

  // Render the parameterized object, only if it's valid.
  if (self.splineConstructor.parameterizedObject) {
    if (self.firstRenderCallOfSequence) {
      [self.delegate renderingOfSplineRendererWillStart:self];
      self.firstRenderCallOfSequence = NO;
    }
    [self processUnprocessedPartOfSpline:end preserveState:preserveState];
  }

  // Remove added points to restore the original state, when should preserve state.
  if (preserveState) {
    [self.splineConstructor popControlPoints:controlPoints.count + numberOfPaddedPoints];
  }

  // Handle end indication, only if state preservation isn't required.
  if (end && !preserveState) {
    [self handleEnd];
  }
}

- (NSUInteger)padParameterizedObjectUntilItIsValid {
  LTParameterAssert(!self.splineConstructor.parameterizedObject);

  if (!self.numberOfControlPoints) {
    return 0;
  }

  NSUInteger numberOfRequiredPoints = [self.type.factory.class numberOfRequiredValues];
  NSUInteger addedPointsCount = numberOfRequiredPoints - self.numberOfControlPoints;
  auto addedPoints = [NSMutableArray<LTSplineControlPoint *> arrayWithCapacity:addedPointsCount];
  LTSplineControlPoint *paddingPoint = self.splineConstructor.controlPoints.lastObject;
  for (NSUInteger i = 0; i < addedPointsCount; ++i) {
    [addedPoints addObject:paddingPoint];
  }
  [self.splineConstructor pushControlPoints:addedPoints];
  return addedPointsCount;
}

- (void)handleEnd {
  LTControlPointModel *controlPointModel = [self.splineConstructor reset];

  if (!self.firstRenderCallOfSequence) {
    DVNSplineRenderModel *model =
        [[DVNSplineRenderModel alloc]
         initWithControlPointModel:controlPointModel configuration:self.sequenceStartConfiguration
         endInterval:self.lastIntervalUsedInLastSequence];
    [self.delegate renderingOfSplineRenderer:self endedWithModel:model];
  }

  [self reset];
}

/// Value indicating an open interval endpoint.
static const lt::Interval<CGFloat>::EndpointInclusion kOpen =
    lt::Interval<CGFloat>::EndpointInclusion::Open;

/// Value indicating a closed interval endpoint.
static const lt::Interval<CGFloat>::EndpointInclusion kClosed =
    lt::Interval<CGFloat>::EndpointInclusion::Closed;

- (void)processUnprocessedPartOfSpline:(BOOL)end preserveState:(BOOL)preserveState {
  lt::Interval<CGFloat> interval({
    self.lastIntervalUsedInLastSequence.sup(),
    self.splineConstructor.parameterizedObject.maxParametricValue
  }, self.lastIntervalUsedInLastSequence == lt::Interval<CGFloat>() ? kClosed : kOpen, kClosed);

  DVNPipelineConfiguration * _Nullable configuration =
      preserveState ? self.pipeline.currentConfiguration : nil;
  [self.pipeline processParameterizedObject:self.splineConstructor.parameterizedObject
                                 inInterval:interval end:end];
  if (preserveState) {
    [self.pipeline setConfiguration:configuration];
  } else {
    self.lastIntervalUsedInLastSequence = interval;
  }
  LTAssert(interval != lt::Interval<CGFloat>(),
           @"Internal inconsistency: intervals used for rendering are supposed to contain at least "
           "one value");
}

- (void)cancel {
  [self handleEnd];
}

+ (void)processModel:(DVNSplineRenderModel *)model {
  DVNPipeline *pipeline = [[DVNPipeline alloc] initWithConfiguration:model.configuration];

  id<LTParameterizedObject> parameterizedObject =
      [LTParameterizedObjectConstructor parameterizedObjectFromModel:model.controlPointModel];

  lt::Interval<CGFloat> interval({0, model.endInterval.inf()}, kClosed,
                                 model.endInterval.infIncluded() ? kOpen : kClosed);

  [pipeline processParameterizedObject:parameterizedObject inInterval:interval end:NO];
  [pipeline processParameterizedObject:parameterizedObject inInterval:model.endInterval end:YES];
}

#pragma mark -
#pragma mark DVNPipelineDelegate
#pragma mark -

- (void)pipeline:(DVNPipeline *)pipeline renderedQuads:(const std::vector<lt::Quad> &)quads {
  LTAssert(pipeline == self.pipeline, @"Received invalid pipeline: %@", pipeline);
  [self.delegate renderingOfSplineRenderer:self continuedWithQuads:quads];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (NSUInteger)numberOfControlPoints {
  return self.splineConstructor.numberOfControlPoints;
}

- (NSArray<LTSplineControlPoint *> *)controlPoints {
  return self.splineConstructor.controlPoints;
}

@end

NS_ASSUME_NONNULL_END
