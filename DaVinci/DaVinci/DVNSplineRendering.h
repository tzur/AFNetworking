// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import <LTEngine/LTQuad.h>

NS_ASSUME_NONNULL_BEGIN

@class DVNSplineRenderModel, LTSplineControlPoint;

@protocol DVNSplineRendering;

/// Protocol to be implemented by objects serving as delegate of \c id<DVNSplineRendering> objects.
@protocol DVNSplineRenderingDelegate <NSObject>

@optional

/// Called just before the given \c renderer will start rendering.
- (void)renderingOfSplineRendererWillStart:(id<DVNSplineRendering>)renderer;

/// Called just after the given \c renderer has rendered the given \c quads.
- (void)renderingOfSplineRenderer:(id<DVNSplineRendering>)renderer
               continuedWithQuads:(const std::vector<lt::Quad> &)quads;

/// Called just after the given \c renderer has finished rendering with the given \c model. The
/// given \c model contains information about a) the control points and type of the parameterized
/// object used by the \c renderer for rendering, b) the configuration of the render pipeline, and
/// c) the last interval in which the parameterized object was sampled.
- (void)renderingOfSplineRenderer:(id<DVNSplineRendering>)renderer
                   endedWithModel:(DVNSplineRenderModel *)model;

@end

/// Protocol to be implemented by objects constructing a continuous parameterized object from an
/// iteratively given sequence of control points and consecutively rendering quadrilateral geometry
/// created from discrete samples of the spline. Objects implementing this protocol execute a
/// \c DVNPipeline object to perform the actual rendering and maintain a delegate that is informed
/// about the rendering. The delegate is held weakly.
///
/// Terminology: Calls to the \c processControlPoints:end: method are called process calls.
/// A process call is called terminating if the \c end parameter is set to \c YES, and
/// non-terminating, otherwise. A sequence of consecutive process calls is called a process sequence
/// if all process calls except for the last are non-terminating.
///
/// During a process sequence the object continues constructing aforementioned parameterized object
/// and provides it to the \c DVNPipeline for rendering. After a process sequence, the object resets
/// to its initial state. However, the internally used \c DVNPipeline is not reset.
///
/// Three different scenarios can arise for a given process sequence:
///
/// Scenario 1: No control points are provided during the process sequence. In this case, there are
/// no side effects and no calls to the delegate.
///
/// Scenario 2: The number of control points provided during the process sequence is insufficient to
/// construct a spline. In this case, the first control point provided during the process sequence
/// is used to construct a single-point spline and provided to the \c DVNPipeline for rendering. The
/// delegate is informed.
///
/// Scenario 3: The number of control points provided during the process sequence is sufficient to
/// construct a spline. In this case, the spline is provided to the \c DVNPipeline for rendering and
/// the delegate is informed.
///
/// Objects implementing this protocol allow the cancellation of ongoing process sequences. If the
/// object receives a cancellation request after beginning a rendering (as a result of an ongoing
/// process sequence), its delegate is informed about the end of the rendering. If the object did
/// not start rendering, the delegate is not called.
@protocol DVNSplineRendering <NSObject>

/// Processes the given \c controlPoints belonging to an ongoing control point sequence by a)
/// creating a spline, in the form of a continuous \c id<LTParameterizedObject>, from the
/// \c controlPoints or extending the already existing spline with them and b) rendering geometry
/// created according to the spline.
///
/// In order to indicate the end of a process sequence, the \c end indication must be \c YES.
- (void)processControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints end:(BOOL)end;

/// Cancels the currently ongoing process sequence and transitions into a state in which it can
/// handle a new process sequence.
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
