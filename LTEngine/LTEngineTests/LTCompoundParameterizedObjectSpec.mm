// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCompoundParameterizedObject.h"

#import "LTPrimitiveParameterizedObject.h"

SpecBegin(LTCompoundParameterizedObject)

__block LTCompoundParameterizedObject *object;
__block LTKeyToPrimitiveParameterizedObject *mapping;
__block id primitiveMock;
__block id anotherPrimitiveMock;

beforeEach(^{
  primitiveMock = OCMProtocolMock(@protocol(LTPrimitiveParameterizedObject));
  anotherPrimitiveMock = OCMProtocolMock(@protocol(LTPrimitiveParameterizedObject));
  OCMStub([primitiveMock minParametricValue]).andReturn(0);
  OCMStub([primitiveMock maxParametricValue]).andReturn(1);
  OCMStub([anotherPrimitiveMock minParametricValue]).andReturn(0);
  OCMStub([anotherPrimitiveMock maxParametricValue]).andReturn(1);
  mapping = @{
    @"x": primitiveMock,
    @"y": anotherPrimitiveMock
  };
  object = [[LTCompoundParameterizedObject alloc] initWithMapping:mapping];
});

afterEach(^{
  primitiveMock = nil;
  anotherPrimitiveMock = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(object.mapping).to.equal(mapping);
  });

  it(@"should initialize with a copy of the provided mapping", ^{
    LTKeyToPrimitiveParameterizedObject *mutableMapping = [mapping mutableCopy];
    object = [[LTCompoundParameterizedObject alloc] initWithMapping:mutableMapping];
    expect(object.mapping).to.equal(mutableMapping);
    expect(object.mapping).toNot.beIdenticalTo(mutableMapping);
  });

  it(@"should raise when attempting to initialize with mapping without keys", ^{
    expect(^{
      object = [[LTCompoundParameterizedObject alloc] initWithMapping:@{}];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when attempting to initialize with invalid primitive parameterized objects", ^{
    id anotherPrimitiveMockWithDifferentParametricRange =
        OCMProtocolMock(@protocol(LTPrimitiveParameterizedObject));
    OCMStub([anotherPrimitiveMockWithDifferentParametricRange minParametricValue]).andReturn(0.5);
    OCMStub([anotherPrimitiveMockWithDifferentParametricRange maxParametricValue]).andReturn(1);
    mapping = @{
      @"x": primitiveMock,
      @"y": anotherPrimitiveMockWithDifferentParametricRange
    };
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
      id primitiveParameterizedObjectMock =
          OCMProtocolMock(@protocol(LTPrimitiveParameterizedObject));
      LTKeyToPrimitiveParameterizedObject *mapping = @{@"test": primitiveParameterizedObjectMock};
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
  __block LTCompoundParameterizedObject *copyOfObject;

  beforeEach(^{
    copyOfObject = [object copy];
  });

  it(@"should return a copy", ^{
    expect(copyOfObject).to.beMemberOf([object class]);
  });

  it(@"should return a copy that is not identical to itself", ^{
    expect(copyOfObject).toNot.beIdenticalTo(object);
  });

  it(@"should return a copy with correct parameterization keys", ^{
    expect(copyOfObject.parameterizationKeys).to.equal(object.parameterizationKeys);
  });

  it(@"should return a copy with correct minimum parametric value", ^{
    expect(copyOfObject.minParametricValue).to.equal(object.minParametricValue);
  });

  it(@"should return a copy with correct maximum parametric value", ^{
    expect(copyOfObject.maxParametricValue).to.equal(object.maxParametricValue);
  });
});

context(@"LTParameterizedObject protocol", ^{
  __block NSSet *expectedKeys;

  beforeEach(^{
    expectedKeys = [NSSet setWithArray:@[@"x", @"y"]];
  });

  it(@"should return the correct mapping for a given parametric value", ^{
    OCMExpect([primitiveMock floatForParametricValue:0]).andReturn(9);
    OCMExpect([anotherPrimitiveMock floatForParametricValue:0]).andReturn(10);

    LTParameterizationKeyToValue *result = [object mappingForParametricValue:0];

    expect([NSSet setWithArray:[result allKeys]]).to.equal(expectedKeys);
    expect(result[@"x"]).to.equal(@9);
    expect(result[@"y"]).to.equal(@10);
    OCMVerifyAll(primitiveMock);
    OCMVerifyAll(anotherPrimitiveMock);
  });

  it(@"should return the correct mappings for given parametric values", ^{
    OCMExpect([primitiveMock floatForParametricValue:0]).andReturn(9);
    OCMExpect([anotherPrimitiveMock floatForParametricValue:0]).andReturn(10);
    OCMExpect([primitiveMock floatForParametricValue:0.5]).andReturn(11);
    OCMExpect([anotherPrimitiveMock floatForParametricValue:0.5]).andReturn(12);

    LTParameterizationKeyToValues *result = [object mappingForParametricValues:{0, 0.5}];

    expect([NSSet setWithArray:[result allKeys]]).to.equal(expectedKeys);
    expect(result[@"x"]).to.equal(@[@9, @11]);
    expect(result[@"y"]).to.equal(@[@10, @12]);
    OCMVerifyAll(primitiveMock);
    OCMVerifyAll(anotherPrimitiveMock);
  });

  it(@"should return the correct float value for a given parametric value and key", ^{
    OCMExpect([primitiveMock floatForParametricValue:0]).andReturn(9);

    CGFloat value = [object floatForParametricValue:0 key:@"x"];

    expect(value).to.equal(9);
    OCMVerifyAll(primitiveMock);
  });

  it(@"should return the correct float values for given parametric values and key", ^{
    OCMExpect([primitiveMock floatForParametricValue:0]).andReturn(9);
    OCMExpect([primitiveMock floatForParametricValue:0.5]).andReturn(10);

    CGFloats values = [object floatsForParametricValues:{0, 0.5} key:@"x"];

    expect(values.size()).to.equal(2);
    expect(values.front()).to.equal(9);
    expect(values.back()).to.equal(10);
    OCMVerifyAll(primitiveMock);
  });

  it(@"should return the correct parameterization keys", ^{
    expect(object.parameterizationKeys).to.equal(expectedKeys);
  });

  it(@"should use the intrinsic parametric range of the primitive parameterized objects", ^{
    primitiveMock = OCMProtocolMock(@protocol(LTPrimitiveParameterizedObject));
    OCMStub([primitiveMock minParametricValue]).andReturn(5.5);
    OCMStub([primitiveMock maxParametricValue]).andReturn(7);

    object = [[LTCompoundParameterizedObject alloc] initWithMapping:@{@"x": primitiveMock}];

    expect(object.minParametricValue).to.equal(5.5);
    expect(object.maxParametricValue).to.equal(7);
  });
});

SpecEnd
