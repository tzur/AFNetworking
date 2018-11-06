// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTContinuousParametricValueProvider.h"
#import "LTInterval.h"

NS_ASSUME_NONNULL_BEGIN

@class LTFloatSetParametricValueProvider;

@protocol LTFloatSet;

/// Immutable value class representing the model used to create an
/// \c LTFloatSetParametricValueProvider.
@interface LTFloatSetParametricValueProviderModel : NSObject
    <LTContinuousParametricValueProviderModel>

/// Initializes with the given \c floatSet and \c interval. The intersection of the given
/// \c floatSet and the given \c interval indicates the subset of real values which are eligible as
/// parametric values.
- (instancetype)initWithFloatSet:(id<LTFloatSet>)floatSet interval:(lt::Interval<CGFloat>)interval;

/// Set of real values determining, in intersection with the \c interval of this object, the subset
/// of real values that should be provided as parametric values.
@property (readonly, nonatomic) id<LTFloatSet> floatSet;

/// Interval determining, in intersection with the \c floatSet of this object, the subset of real
/// values that should be provided as parametric values.
@property (readonly, nonatomic) lt::Interval<CGFloat> interval;

/// Creates a new provider of parametric values with the state represented by this object.
- (LTFloatSetParametricValueProvider *)provider;

@end

/// Object returning parametric values in the longest possible interval for which no values have
/// been provided yet, for a given parameterized object.
@interface LTFloatSetParametricValueProvider : NSObject <LTContinuousParametricValueProvider>

/// Provides the next parametric values which should be used to sample the given \c object.
///
/// In particular, the interval represented by the parametric range of a given parameterized object
/// is intersected with the current interval \c I, yielding an interval \c J. The returned values
/// are the values representing the intersection between the interval \c J and the float set used by
/// this object. Initially, the interval \c I is the interval provided by the model used to create
/// this object. Upon every call to the \c nextParametricValuesForParameterizedObject: method, \c I
/// is updated to be the intersection of \c K and the initial interval, where \c K equals the
/// complement of \c J.
- (std::vector<CGFloat>)
    nextParametricValuesForParameterizedObject:(id<LTParameterizedObject>)object;

/// Returns the current state of this object.
- (LTFloatSetParametricValueProviderModel *)currentModel;

@end

NS_ASSUME_NONNULL_END
