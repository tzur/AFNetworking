// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import "INTTransformerBlockExamples.h"

#import "INTEventTransformationExecutor.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kINTTransformerBlockExamples = @"TransformerBlockExamples";
NSString * const kINTTransformerBlockExamplesTransformerBlock =
    @"TransformerBlockExamplesTransformerBlock";
NSString * const kINTTransformerBlockExamplesArgumentsSequence =
    @"TransformerBlockExamplesArgumentsSequence";
NSString * const kINTTransformerBlockExamplesExpectedEvents =
    @"TransformerBlockExamplesExpectedEvents";

SharedExampleGroupsBegin(kINTTransformerBlockExamples)

sharedExamplesFor(kINTTransformerBlockExamples, ^(NSDictionary *data) {
  __block INTEventTransformationExecutor *executor;
  __block INTTransformerBlock transformerBlock;
  __block NSArray<INTEventTransformerArguments *> *eventSequence;

  beforeEach(^{
    transformerBlock = data[kINTTransformerBlockExamplesTransformerBlock];
    executor = [[INTEventTransformationExecutor alloc] initWithTransformerBlock:transformerBlock];
    eventSequence = data[kINTTransformerBlockExamplesArgumentsSequence];
  });

  it(@"should produce expected events", ^{
    auto providers = [executor transformEventSequence:eventSequence];

    expect(providers).to.equal(data[kINTTransformerBlockExamplesExpectedEvents]);
  });
});

SharedExampleGroupsEnd

NS_ASSUME_NONNULL_END
