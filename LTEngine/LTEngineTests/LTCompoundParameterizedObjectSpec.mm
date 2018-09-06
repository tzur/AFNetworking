// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCompoundParameterizedObject.h"

#import "LTBasicParameterizedObject.h"
#import "LTParameterizationKeyToValues.h"

SpecBegin(LTCompoundParameterizedObject)

__block LTCompoundParameterizedObject *object;
__block LTKeyToBaseParameterizedObject *mapping;
__block id basicMock;
__block id anotherBasicMock;

beforeEach(^{
  basicMock = OCMProtocolMock(@protocol(LTBasicParameterizedObject));
  anotherBasicMock = OCMProtocolMock(@protocol(LTBasicParameterizedObject));
  OCMStub([basicMock minParametricValue]).andReturn(0);
  OCMStub([basicMock maxParametricValue]).andReturn(1);
  OCMStub([anotherBasicMock minParametricValue]).andReturn(0);
  OCMStub([anotherBasicMock maxParametricValue]).andReturn(1);
  mapping = @[
    [LTKeyBasicParameterizedObjectPair pairWithKey:@"x" basicParameterizedObject:basicMock],
    [LTKeyBasicParameterizedObjectPair pairWithKey:@"y" basicParameterizedObject:anotherBasicMock]
  ];
  object = [[LTCompoundParameterizedObject alloc] initWithMapping:mapping];
});

afterEach(^{
  basicMock = nil;
  anotherBasicMock = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(object.mapping).to.equal(mapping);
  });

  it(@"should initialize with a given mutable mapping", ^{
    LTKeyToBaseParameterizedObject *mutableMapping = [mapping mutableCopy];
    object = [[LTCompoundParameterizedObject alloc] initWithMapping:mutableMapping];
    expect(object.mapping).to.beIdenticalTo(mutableMapping);
  });

  it(@"should raise when attempting to initialize with mapping without keys", ^{
    expect(^{
      object = [[LTCompoundParameterizedObject alloc] initWithMapping:@[]];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when attempting to initialize with invalid basic parameterized objects", ^{
    id anotherBasicMockWithDifferentParametricRange =
        OCMProtocolMock(@protocol(LTBasicParameterizedObject));
    OCMStub([anotherBasicMockWithDifferentParametricRange minParametricValue]).andReturn(0.5);
    OCMStub([anotherBasicMockWithDifferentParametricRange maxParametricValue]).andReturn(1);
    mapping = @[
      [LTKeyBasicParameterizedObjectPair pairWithKey:@"x"
                            basicParameterizedObject:basicMock],
      [LTKeyBasicParameterizedObjectPair pairWithKey:@"y"
                            basicParameterizedObject:anotherBasicMockWithDifferentParametricRange]
    ];
    expect(^{
      object = [[LTCompoundParameterizedObject alloc] initWithMapping:mapping];
    }).to.raise(NSInvalidArgumentException);
  });
});

context(@"NSObject protocol", ^{
  context(@"comparison with isEqual:", ^{
    it(@"should return YES when comparing to itself", ^{
      expect([object isEqual:object]).to.beTruthy();
    });

    it(@"should return YES when comparing to an object with the same properties", ^{
      LTCompoundParameterizedObject *anotherObject =
          [[LTCompoundParameterizedObject alloc] initWithMapping:[mapping copy]];
      expect([object isEqual:anotherObject]).to.beTruthy();
    });

    it(@"should return NO when comparing to nil", ^{
      LTCompoundParameterizedObject *anotherObject = nil;
      expect([object isEqual:anotherObject]).to.beFalsy();
    });

    it(@"should return NO when comparing to an object of a different class", ^{
      expect([object isEqual:[[NSObject alloc] init]]).to.beFalsy();
    });

    it(@"should return NO when comparing to an object with different properties", ^{
      id baseParameterizedObjectMock = OCMProtocolMock(@protocol(LTBasicParameterizedObject));
      LTKeyToBaseParameterizedObject *mapping = @[
        [LTKeyBasicParameterizedObjectPair pairWithKey:@"test"
                              basicParameterizedObject:baseParameterizedObjectMock]
      ];
      LTCompoundParameterizedObject *anotherObject =
          [[LTCompoundParameterizedObject alloc] initWithMapping:mapping];
      expect([object isEqual:anotherObject]).to.beFalsy();
    });
  });

  context(@"hash", ^{
    it(@"should return the same hash value for equal objects", ^{
      LTCompoundParameterizedObject *anotherObject =
          [[LTCompoundParameterizedObject alloc] initWithMapping:[mapping copy]];
      expect([object hash]).to.equal([anotherObject hash]);
    });
  });
});

context(@"NSCopying protocol", ^{
  it(@"should return itself as copy, due to immutability", ^{
    expect([object copy]).to.beIdenticalTo(object);
  });
});

context(@"LTParameterizedObject protocol", ^{
  __block NSSet<NSString *> *expectedKeys;

  beforeEach(^{
    expectedKeys = [NSSet setWithArray:@[@"x", @"y"]];
  });

  it(@"should return the correct mapping for a given parametric value", ^{
    OCMExpect([basicMock floatForParametricValue:0]).andReturn(9);
    OCMExpect([anotherBasicMock floatForParametricValue:0]).andReturn(10);

    LTParameterizationKeyToValue *result = [object mappingForParametricValue:0];

    expect([NSSet setWithArray:[result allKeys]]).to.equal(expectedKeys);
    expect(result[@"x"]).to.equal(@9);
    expect(result[@"y"]).to.equal(@10);
    OCMVerifyAll(basicMock);
    OCMVerifyAll(anotherBasicMock);
  });

  it(@"should return the correct mappings for given parametric values", ^{
    OCMExpect([basicMock floatForParametricValue:0]).andReturn(9);
    OCMExpect([anotherBasicMock floatForParametricValue:0]).andReturn(10);
    OCMExpect([basicMock floatForParametricValue:0.5]).andReturn(11);
    OCMExpect([anotherBasicMock floatForParametricValue:0.5]).andReturn(12);

    LTParameterizationKeyToValues *result = [object mappingForParametricValues:{0, 0.5}];

    CGFloats xValues = [result valuesForKey:@"x"];
    CGFloats yValues = [result valuesForKey:@"y"];

    expect([result.keys set]).to.equal(expectedKeys);
    expect(xValues.size()).to.equal(2);
    expect(xValues[0]).to.equal(9);
    expect(xValues[1]).to.equal(11);
    expect(yValues.size()).to.equal(2);
    expect(yValues[0]).to.equal(10);
    expect(yValues[1]).to.equal(12);
    OCMVerifyAll(basicMock);
    OCMVerifyAll(anotherBasicMock);
  });

  it(@"should return the correct float value for a given parametric value and key", ^{
    OCMExpect([basicMock floatForParametricValue:0]).andReturn(9);

    CGFloat value = [object floatForParametricValue:0 key:@"x"];

    expect(value).to.equal(9);
    OCMVerifyAll(basicMock);
  });

  it(@"should return the correct float values for given parametric values and key", ^{
    OCMExpect([basicMock floatForParametricValue:0]).andReturn(9);
    OCMExpect([basicMock floatForParametricValue:0.5]).andReturn(10);

    CGFloats values = [object floatsForParametricValues:{0, 0.5} key:@"x"];

    expect(values.size()).to.equal(2);
    expect(values.front()).to.equal(9);
    expect(values.back()).to.equal(10);
    OCMVerifyAll(basicMock);
  });

  it(@"should return the correct parameterization keys", ^{
    expect(object.parameterizationKeys).to.equal([NSOrderedSet orderedSetWithSet:expectedKeys]);
  });

  it(@"should use the intrinsic parametric range of the basic parameterized objects", ^{
    basicMock = OCMProtocolMock(@protocol(LTBasicParameterizedObject));
    OCMStub([basicMock minParametricValue]).andReturn(5.5);
    OCMStub([basicMock maxParametricValue]).andReturn(7);

    object = [[LTCompoundParameterizedObject alloc]
              initWithMapping:@[[LTKeyBasicParameterizedObjectPair pairWithKey:@"x"
                                                      basicParameterizedObject:basicMock]]];

    expect(object.minParametricValue).to.equal(5.5);
    expect(object.maxParametricValue).to.equal(7);
  });
});

SpecEnd
