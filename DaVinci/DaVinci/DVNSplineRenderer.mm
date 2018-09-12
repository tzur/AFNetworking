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

  NSUInteger numberOfControlPointsToPopIfNecessary = controlPoints.count;

  if (!self.parameterizedObject) {
    if (!end) {
      // If the spline could not be constructed yet and the current state does not represent the end
      // of a control point sequence, bail out since there is nothing to render yet.
      if (preserveState) {
        [self.splineConstructor popControlPoints:numberOfControlPointsToPopIfNecessary];
      }
      return;
    }

    LTControlPointModel *controlPointModel = [self.splineConstructor reset];

    if (!controlPointModel.controlPoints.count) {
      DVNPipelineConfiguration *pipelineConfiguration = [self.pipeline currentConfiguration];
      LTAssert([pipelineConfiguration isEqual:self.sequenceStartConfiguration],
               @"Configuration %@ of pipeline should not be different than configuration at "
               "start of control point sequence", pipelineConfiguration);
      LTAssert(self.lastIntervalUsedInLastSequence == lt::Interval<CGFloat>(),
               @"Last interval %@ used in most recent control point sequence must equal "
               "the empty (0, 0) interval", self.lastIntervalUsedInLastSequence.description());
      return;
    }

    // If the number of control points received in the current sequence is insufficient to
    // construct a spline but is greater than zero and the current state represents the end of a
    // control point sequence, a single point should be rendered.
    numberOfControlPointsToPopIfNecessary =
        [self setupForRenderingOfSinglePoint:controlPointModel.controlPoints.firstObject
                 withParameterizedObjectType:controlPointModel.type];
  }

  if (self.firstRenderCallOfSequence) {
    [self.delegate renderingOfSplineRendererWillStart:self];
    self.firstRenderCallOfSequence = NO;
  }

  [self processUnprocessedPartOfSpline:end preserveState:preserveState];

  if (preserveState) {
    [self.splineConstructor popControlPoints:numberOfControlPointsToPopIfNecessary];
  } else if (end) {
    [self handleEnd];
  }
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
    self.parameterizedObject.maxParametricValue
  }, self.lastIntervalUsedInLastSequence == lt::Interval<CGFloat>() ? kClosed : kOpen, kClosed);

  DVNPipelineConfiguration * _Nullable configuration =
      preserveState ? self.pipeline.currentConfiguration : nil;
  [self.pipeline processParameterizedObject:self.parameterizedObject
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

- (NSUInteger)setupForRenderingOfSinglePoint:(LTSplineControlPoint *)point
                 withParameterizedObjectType:(LTParameterizedObjectType *)type {
  id<LTBasicParameterizedObjectFactory> factory = [type factory];
  NSUInteger numberOfControlPoints = [[factory class] numberOfRequiredValues];
  NSMutableArray<LTSplineControlPoint *> *mutableControlPoints =
      [NSMutableArray arrayWithCapacity:numberOfControlPoints];

  for (NSUInteger i = 0; i < numberOfControlPoints; ++i) {
    [mutableControlPoints addObject:point];
  }

  [self.splineConstructor pushControlPoints:mutableControlPoints];
  return numberOfControlPoints;
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

- (id<LTParameterizedObject>)parameterizedObject {
  return self.splineConstructor.parameterizedObject;
}

@end

NS_ASSUME_NONNULL_END
