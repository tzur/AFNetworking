// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTInterval.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LTContinuousSamplerModel, LTParameterizedObject, LTSampleValues;

/// Protocol which should be implemented by objects consecutively sampling a given parameterized
/// object. Due to their consecutive character, the implementing objects may be stateful. To ensure
/// an immutable representation of the object state, each object has an immutable model associated
/// with it from which the object can be created or which can be created from the current state of
/// an object.
@protocol LTContinuousSampler <NSObject>

/// The default initializer is disabled since samplers should be created solely using their
/// associated models.
- (instancetype)init NS_UNAVAILABLE;

/// Provides the next samples of the given parameterized \c object in the given \c interval,
/// according to the current state of this sampler.
- (id<LTSampleValues>)nextSamplesFromParameterizedObject:(id<LTParameterizedObject>)object
                                   constrainedToInterval:(const lt::Interval<CGFloat> &)interval;

/// Returns an immutable model representing the current state of this sampler.
- (id<LTContinuousSamplerModel>)currentModel;

@end

/// Protocol which should be implemented by immutable value classes representing the model from
/// which an associated \c id<LTContinuousSampler> can be created.
@protocol LTContinuousSamplerModel <NSObject, NSCopying>

/// Creates a new sampler from this model.
- (id<LTContinuousSampler>)sampler;

@end

NS_ASSUME_NONNULL_END
