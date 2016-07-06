// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContinuousSampler.h"
#import "LTInterval.h"

NS_ASSUME_NONNULL_BEGIN

@class LTFloatSetSampler;

@protocol LTFloatSet;

/// Immutable value class representing the model used to create the corresponding
/// \c id<LTFloatSetSampler> object.
@interface LTFloatSetSamplerModel : NSObject <LTContinuousSamplerModel>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c floatSet and \c interval. The intersection of the given
/// \c floatSet and the given \c interval indicates the subset of real values which are eligible as
/// parametric values.
- (instancetype)initWithFloatSet:(id<LTFloatSet>)floatSet
                        interval:(const lt::Interval<CGFloat> &)interval NS_DESIGNATED_INITIALIZER;

/// Set of real values determining, in intersection with the \c interval of this object, the subset
/// of real values that should be used as parametric values at which a given parameterized object is
/// to be sampled.
@property (readonly, nonatomic) id<LTFloatSet> floatSet;

/// Interval determining, in intersection with the \c floatSet of this object, the subset of real
/// values that should be used as parametric values at which a given parameterized object is to be
/// sampled.
@property (readonly, nonatomic) lt::Interval<CGFloat> interval;

/// Creates a new sampler from this model.
- (LTFloatSetSampler *)sampler;

@end

/// Object consecutively sampling a given parameterized object at parametric values retrieved from
/// provided intervals of a float set. The interval for which parametric values can be retrieved
/// equals the \c interval of the current model of this instance. Any time the
/// \c nextSamplesFromParameterizedObject:constrainedToInterval: method is called with an interval
/// \c I, the \c interval of the model of this instance is updated to be the complement of \c I with
/// respect to \c interval. For instance, if currently \c interval is <tt>[0, 1)</tt> and \c I is
/// <tt>[-1, 0.5]</tt>, then the new \c interval is <tt>(0.5, 1)</tt>. In case that aforementioned
/// complement is disjoint, the interval containing the greater values is chosen. For instance,
/// if currently \c interval is <tt>[0, 1)</tt> and \c I is <tt>[0.25, 0.5]</tt>, then the new
/// \c interval is <tt>(0.5, 1)</tt> (rather than <tt>[0, 0.25)</tt>).
@interface LTFloatSetSampler : NSObject <LTContinuousSampler>

- (instancetype)init NS_UNAVAILABLE;

/// Returns the next samples of the given \c object, constrained to parametric values retrieved from
/// the float set of this instance, in the interval constituted by the intersection of the given
/// \c interval with the \c interval of the current model of this instance.
- (id<LTSampleValues>)nextSamplesFromParameterizedObject:(id<LTParameterizedObject>)object
                                   constrainedToInterval:(const lt::Interval<CGFloat> &)interval;

/// Returns the current state of this object.
- (LTFloatSetSamplerModel *)currentModel;

@end

NS_ASSUME_NONNULL_END
