// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@protocol LTContinuousParametricValueProviderModel, LTParameterizedObject;

/// Protocol which should be implemented by objects providing parametric values used to sample a
/// given parameterized object. The objects support value providing in an iterative way which causes
/// them to be intrinsically state-full. To ensure an immutable representation of the object state,
/// each object has an immutable model associated with it from which the object can be created or
/// which can be created from the current state of an object.
@protocol LTContinuousParametricValueProvider <NSObject>

/// The default initializer is disabled since providers should be created solely using their
/// associated models.
- (instancetype)init NS_UNAVAILABLE;

/// Returns the next parametric values which should be used to sample the given \c object. The
/// number of returned values depends on a) the frequency with which the \c object should be sampled
/// and b) the interval of the intrinsic parametric range of the \c object for which no values have
/// been returned yet. Returns \c {} if the next parametric values would be outside the intrinsic
/// parametric range of the \c object. The returned values are monotonically increasing.
- (std::vector<CGFloat>)
    nextParametricValuesForParameterizedObject:(id<LTParameterizedObject>)object;

/// Returns an immutable model representing the current state of this object.
- (id<LTContinuousParametricValueProviderModel>)currentModel;

@end

/// Protocol which should be implemented by immutable value classes representing the model from
/// which an associated \c id<LTContinuousParametricValueProvider> can be created.
@protocol LTContinuousParametricValueProviderModel <NSObject, NSCopying>

/// Creates a new provider of parametric values.
- (id<LTContinuousParametricValueProvider>)provider;

@end

NS_ASSUME_NONNULL_END
