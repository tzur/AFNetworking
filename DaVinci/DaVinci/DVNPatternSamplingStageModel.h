// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNPipelineStagesMutableModels.h"
#import "DVNPropertyMacros.h"

NS_ASSUME_NONNULL_BEGIN

/// Mutable pipeline sampling stage model that provides pattern based continuous samplers. All
/// samplers constructible from the models returned by this class start sampling at \c 0 and do not
/// have an upper bound on the \c maxParametricValue of the sampled parameterized object.
@interface DVNPatternSamplingStageModel : MTLModel <DVNSamplingStageModel>

/// Distance between successive samples inside any sequence. Must be in <tt>[0.01, CGFLOAT_MAX]</tt>
/// range. Default value is \c 1.
DVNPropertyDeclare(CGFloat, spacing, Spacing);

/// Number of samples inside any sequence. Must be in <tt>[1, NSUIntegerMax]</tt> range. Default
/// value is \c 1.
DVNPropertyDeclare(NSUInteger, numberOfSamplesPerSequence, NumberOfSamplesPerSequence);

/// Length of the gap between two consecutive sequences. In other words, distance between the last
/// sample of a sequence and the first sample of the next sequence. Must be in
/// <tt>[0.01, CGFLOAT_MAX]</tt> range. Default value is \c 1.
DVNPropertyDeclare(CGFloat, sequenceDistance, SequenceDistance);

@end

NS_ASSUME_NONNULL_END
