// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

NS_ASSUME_NONNULL_BEGIN

@class LTParameterizationKeyToValues;

/// Protocol which should be implemented by value classes providing values sampled from a
/// parameterized object.
@protocol LTSampleValues <NSObject>

/// Parametric values at which the parameterized object has been sampled. Is empty if no values were
/// sampled. The number of parametric values equals the number of values for each key of the
/// \c mappingOfSampledValues.
@property (readonly, nonatomic) CGFloats sampledParametricValues;

/// Mapping from \c parameterizationKeys of the sampled parameterized object to sampled values.
/// \c nil if no values were sampled. The number of values for each key equals the number of
/// \c sampledParametricValues.
@property (readonly, nonatomic, nullable) LTParameterizationKeyToValues *mappingOfSampledValues;

@end

/// Value class providing values sampled from a parameterized object.
@interface LTSampleValues : NSObject <LTSampleValues>

- (instancetype)init NS_UNAVAILABLE;

/// Initializes with the given \c sampledParametricValues and \c mapping. The number of given
/// \c sampledParametricValues must equal the number of values for each key of the given
/// \c mappingOfSampledValues and must not exceed \c INT_MAX.
- (instancetype)initWithSampledParametricValues:(const CGFloats &)sampledParametricValues
                                        mapping:(nullable LTParameterizationKeyToValues *)mapping
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
