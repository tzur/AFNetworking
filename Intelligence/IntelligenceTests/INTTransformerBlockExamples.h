// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

NS_ASSUME_NONNULL_BEGIN

/// Name of the example group for \c INTTransformerBlock blocks.
extern NSString * const kINTTransformerBlockExamples;

/// Key pointing to the \c INTTransformerBlock object to be tested in the example group. Value for
/// this key is mandatory.
extern NSString * const kINTTransformerBlockExamplesTransformerBlock;

/// Key pointing to the <tt>NSArray<INTEventTransformerArguments *></tt> object, containing a
/// sequence of arguments to feed the tested transformer block with, by the order in the array.
/// Value for this key is mandatory.
extern NSString * const kINTTransformerBlockExamplesArgumentsSequence;

/// Key pointing to the \c NSArray object containing the expected events. Value for this key is
/// mandatory.
extern NSString * const kINTTransformerBlockExamplesExpectedEvents;

NS_ASSUME_NONNULL_END
