// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTInterval.h>
#import <LTEngine/LTQuad.h>

NS_ASSUME_NONNULL_BEGIN

@class DVNPipelineConfiguration, DVNSplineRenderModel, DVNSplineRenderer, LTParameterizedObjectType,
    LTSplineControlPoint;

/// Protocol to be implemented by objects serving as delegate of \c DVNSplineRenderer objects.
@protocol DVNSplineRendererDelegate

@optional

/// Called just before the given \c renderer will start rendering.
- (void)renderingOfSplineRendererWillStart:(DVNSplineRenderer *)renderer;

/// Called just after the given \c renderer has rendered the given \c quads.
- (void)renderingOfSplineRenderer:(DVNSplineRenderer *)renderer
               continuedWithQuads:(const std::vector<lt::Quad> &)quads;

/// Called just after the given \c renderer has finished rendering with the given \c model. The
/// given \c model contains information about a) the control points and type of the parameterized
/// object used by the \c renderer for rendering, b) the configuration of the render pipeline, and
/// c) the last interval in which the parameterized object was sampled.
- (void)renderingOfSplineRenderer:(DVNSplineRenderer *)renderer
                   endedWithModel:(DVNSplineRenderModel *)model;

@end

/// Object constructing a continuous parameterized object from an iteratively given sequence of
/// control points and consecutively rendering quadrilateral geometry created from discrete samples
/// of the spline.
/// The object executes a \c DVNPipeline object to perform the actual rendering.
///
/// The renderer does not assume any specific render target. It is the responsibility of the user to
/// ensure the usage of an appropriate render target.
@interface DVNSplineRenderer : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c type, \c configuration and \c delegate. The given \c type
/// determines the parameterized object constructed from incoming control points. The given
/// \c configuration is used by the \c DVNPipeline object executed by the returned instance. The
/// given \c delegate is held weakly. The \c delegate is provided upon initialization in order to
/// avoid the possibility of partial updates to a delegate which could arise if it was possible to
/// replace the delegate in the middle of a control point sequence currently being processed.
- (instancetype)initWithType:(LTParameterizedObjectType *)type
               configuration:(DVNPipelineConfiguration *)configuration
                    delegate:(nullable id<DVNSplineRendererDelegate>)delegate;

/// Processes the given \c controlPoints belonging to an ongoing control point sequence by a)
/// creating a spline, in the form of a continuous \c id<LTParameterizedObject>, from the
/// \c controlPoints or extending the already existing spline with them and b) rendering
/// quadrilateral geometry created from discrete samples of the spline, according to the
/// \c configuration provided upon intialization. The given \c controlPoints must contain at least
/// one control point.
///
/// In order to indicate the end of a control point sequence, the \c end indication is to be set to
/// \c YES. If at the end of a control point sequence, the number of control points provided as part
/// of the ending sequence is insufficient to construct a spline, the first control point of the
/// control points is used to construct a single-point spline.
///
/// After the end of a control point sequence, this instance transitions into a state in which a new
/// control point sequence can be received.
- (void)processControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints end:(BOOL)end;

/// Cancels the currently ongoing process sequence and transitions into a state in which it can
/// handle a new process sequence. If this instance started rendering as a result of the ongoing
/// process sequence, its delegate is informed about the end of the rendering. If this instance did
/// not start rendering, the delegate is not called.
- (void)cancel;

/// Processes the given \c model. It is the responsibility of the user to ensure the usage of an
/// appropriate render target.
+ (void)processModel:(DVNSplineRenderModel *)model;

@end

NS_ASSUME_NONNULL_END
