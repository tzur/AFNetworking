// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSplineRenderer.h"

#import <LTEngine/LTBasicParameterizedObjectFactory.h>
#import <LTEngine/LTControlPointModel.h>
#import <LTEngine/LTParameterizedObjectConstructor.h>
#import <LTEngine/LTParameterizedObjectType.h>

#import "DVNPipeline.h"
#import "DVNSplineRenderModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVNSplineRenderer () <DVNPipelineDelegate>

/// Delegate informed about render events.
@property (weak, readonly, nonatomic) id<DVNSplineRendererDelegate> delegate;

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

@end

@implementation DVNSplineRenderer

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithType:(LTParameterizedObjectType *)type
               configuration:(DVNPipelineConfiguration *)configuration
                    delegate:(nullable id<DVNSplineRendererDelegate>)delegate {
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
}

#pragma mark -
#pragma mark Public Interface
#pragma mark -

- (void)processControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints end:(BOOL)end {
  LTParameterAssert(controlPoints.count, @"At least one control point must be provided");
  [self.splineConstructor pushControlPoints:controlPoints];

  if (!self.splineConstructor.parameterizedObject) {
    if (!end) {
      // If the spline could not be constructed yet and the current state does not represent the end
      // of a control point sequence, bail out since there is nothing to render yet.
      return;
    } else {
      // If the spline could not be constructed yet and the current state represents the end of a
      // control point sequence, the number of control points received in the current sequence
      // insufficient to construct a spline, so a single point should be rendered.
      [self setupForSinglePointRendering];
    }
  }

  if (self.firstRenderCallOfSequence) {
    [self.delegate renderingOfSplineRendererWillStart:self];
  }

  [self processUnprocessedPartOfSpline:end];

  if (end) {
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

- (BOOL)firstRenderCallOfSequence {
  return self.lastIntervalUsedInLastSequence == lt::Interval<CGFloat>();
}

/// Value indicating an open interval endpoint.
static const lt::Interval<CGFloat>::EndpointInclusion kOpen =
    lt::Interval<CGFloat>::EndpointInclusion::Open;

/// Value indicating a closed interval endpoint.
static const lt::Interval<CGFloat>::EndpointInclusion kClosed =
    lt::Interval<CGFloat>::EndpointInclusion::Closed;

- (void)processUnprocessedPartOfSpline:(BOOL)end {
  lt::Interval<CGFloat> interval({self.lastIntervalUsedInLastSequence.max(),
                                  self.splineConstructor.parameterizedObject.maxParametricValue},
                                  self.firstRenderCallOfSequence ? kClosed : kOpen, kClosed);

  [self.pipeline processParameterizedObject:self.splineConstructor.parameterizedObject
                                 inInterval:interval end:end];

  self.lastIntervalUsedInLastSequence = interval;
  LTAssert(self.lastIntervalUsedInLastSequence != lt::Interval<CGFloat>(),
           @"Internal inconsistency: intervals used for rendering are supposed to contain at least "
           "one value");
}

- (void)setupForSinglePointRendering {
  LTControlPointModel *controlPointModel = [self.splineConstructor reset];
  LTAssert(controlPointModel.controlPoints.count, @"Internal inconsistency: at least one control "
           "point is supposed to exist at this point");

  id<LTBasicParameterizedObjectFactory> factory = [controlPointModel.type factory];
  NSUInteger numberOfControlPoints = [[factory class] numberOfRequiredValues];
  NSMutableArray<LTSplineControlPoint *> *mutableControlPoints =
      [NSMutableArray arrayWithCapacity:numberOfControlPoints];

  for (NSUInteger i = 0; i < numberOfControlPoints; ++i) {
    [mutableControlPoints addObject:controlPointModel.controlPoints.firstObject];
  }

  [self.splineConstructor pushControlPoints:mutableControlPoints];
}

- (void)cancel {
  [self handleEnd];
}

+ (void)processModel:(DVNSplineRenderModel *)model {
  DVNPipeline *pipeline = [[DVNPipeline alloc] initWithConfiguration:model.configuration];

  id<LTParameterizedObject> parameterizedObject =
      [LTParameterizedObjectConstructor parameterizedObjectFromModel:model.controlPointModel];

  lt::Interval<CGFloat> interval({0, model.endInterval.min()}, kClosed,
                                 model.endInterval.minEndpointIncluded() ? kOpen : kClosed);

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

@end

NS_ASSUME_NONNULL_END
