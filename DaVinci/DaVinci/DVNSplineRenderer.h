// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "DVNSplineRendering.h"

NS_ASSUME_NONNULL_BEGIN

@class DVNPipelineConfiguration, LTParameterizedObjectType;

/// Object constructing a continuous parameterized object from an iteratively given sequence of
/// control points and consecutively rendering quadrilateral geometry created from discrete samples
/// of the spline. Refer to the \c DVNSplineRendering protocol for more details.
/// The object executes a \c DVNPipeline object to perform the actual rendering.
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
/// The renderer does not assume any specific render target. It is the responsibility of the user to
/// ensure the usage of an appropriate render target.
@interface DVNSplineRenderer : NSObject <DVNSplineRendering>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c type, \c configuration and \c delegate. The given \c type
/// determines the parameterized object constructed from incoming control points. The given
/// \c configuration is used by the \c DVNPipeline object executed by the returned instance. The
/// given \c delegate is held weakly. The \c delegate is provided upon initialization in order to
/// avoid the possibility of partial updates to a delegate which could arise if it was possible to
/// replace the delegate in the middle of a process sequence.
- (instancetype)initWithType:(LTParameterizedObjectType *)type
               configuration:(DVNPipelineConfiguration *)configuration
                    delegate:(nullable id<DVNSplineRenderingDelegate>)delegate;

/// Processes the given \c controlPoints belonging to an ongoing control point sequence by a)
/// creating a spline, in the form of a continuous \c id<LTParameterizedObject>, from the
/// \c controlPoints or extending the already existing spline with them, b) rendering geometry
/// created according to the spline, and, if \c preserveState is \c YES, c) resetting the state of
/// the internally used objects, including the internally used \c DVNPipeline, except for the
/// content of the render target, to the state prior to the method call.
///
/// In order to indicate the end of a process sequence, the \c end indication must be \c YES. If
/// \c end is \c YES and \c preserveState is \c NO, this instance transitions into its initial state
/// in which the next provided control points are considered to belong to a new control point
/// sequence. If both \c end and \c preserveState are \c YES, the instance only performs the
/// rendering as if the control point sequence has ended without transitioning into its initial
/// state, preserving its state prior to rendering, as described above.
///
/// @important The \c renderingOfSplineRenderer:endedWithModel: method of the delegate provided upon
/// initialization is not called when \c preserveState is \c YES. This allows for consecutive
/// renderings of the final brush stroke part on the render target without informing the delegate
/// more than once.
- (void)processControlPoints:(NSArray<LTSplineControlPoint *> *)controlPoints
               preserveState:(BOOL)preserveState end:(BOOL)end;

/// Processes the given \c model. The effect of this method is identical to creating a
/// \c DVNSplineRenderer and performing a process sequence with the information provided by the
/// given \c model. It is the responsibility of the user to ensure the usage of an appropriate
/// render target.
+ (void)processModel:(DVNSplineRenderModel *)model;

@end

NS_ASSUME_NONNULL_END
