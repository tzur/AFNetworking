// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTSamplingOutput.h"

#import "LTSamplingScheme.h"

SpecBegin(LTSamplingOutput)

it(@"should initialize correctly", ^{
  id mappingMock = OCMClassMock([LTParameterizationKeyToValues class]);
  id schemeMock = OCMProtocolMock(@protocol(LTSamplingScheme));
  LTSamplingOutput *output = [[LTSamplingOutput alloc] initWithSampledParametricValues:{1, 1.5, 2}
                                                                               mapping:mappingMock
                                                                        samplingScheme:schemeMock];
  expect(output).toNot.beNil();
  expect(output.sampledParametricValues.size()).to.equal(3);
  expect(output.sampledParametricValues[0]).to.equal(1);
  expect(output.sampledParametricValues[1]).to.equal(1.5);
  expect(output.sampledParametricValues[2]).to.equal(2);
  expect(output.mappingOfSampledValues).to.beIdenticalTo(mappingMock);
  expect(output.samplingScheme).to.beIdenticalTo(schemeMock);
});

SpecEnd
