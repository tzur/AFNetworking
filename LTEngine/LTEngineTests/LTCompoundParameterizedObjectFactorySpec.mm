// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCompoundParameterizedObjectFactory.h"

#import "LTCompoundParameterizedObject.h"
#import "LTInterpolatableObject.h"
#import "LTPrimitiveParameterizedObject.h"
#import "LTPrimitiveParameterizedObjectFactory.h"

@interface LTTestInterpolatableObject : NSObject <LTInterpolatableObject>
@end

@implementation LTTestInterpolatableObject

- (instancetype)initWithInterpolatedProperties:(NSDictionary __unused *)properties {
  return nil;
}

- (NSSet<NSString *> *)propertiesToInterpolate {
  return nil;
}

@end

@interface LTTestPrimitiveFactory : NSObject <LTPrimitiveParameterizedObjectFactory>
@end

@implementation LTTestPrimitiveFactory

- (id<LTPrimitiveParameterizedObject>)primitiveParameterizedObjectsFromValues:
    (__unused CGFloats)values {
  return nil;
}

+ (NSUInteger)numberOfRequiredValues {
  return 1;
}

+ (NSRange)intrinsicParametricRange {
  return NSMakeRange(0, 1);
}

@end

SpecBegin(LTCompoundParameterizedObjectFactory)

__block LTCompoundParameterizedObjectFactory<LTTestInterpolatableObject *> *factory;
__block id<LTPrimitiveParameterizedObjectFactory> primitiveFactory;
__block id primitiveFactoryMock;

beforeEach(^{
  primitiveFactory = [[LTTestPrimitiveFactory alloc] init];
  primitiveFactoryMock = OCMPartialMock(primitiveFactory);
  factory =
      [[LTCompoundParameterizedObjectFactory<LTTestInterpolatableObject *> alloc]
       initWithPrimitiveFactory:primitiveFactoryMock];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(factory.numberOfRequiredInterpolatableObjects)
        .to.equal([[primitiveFactory class] numberOfRequiredValues]);
    expect(factory.intrinsicParametricRange.location)
        .to.equal([[primitiveFactory class] intrinsicParametricRange].location);
    expect(factory.intrinsicParametricRange.length)
        .to.equal([[primitiveFactory class] intrinsicParametricRange].length);
  });
});

context(@"parameterized object computation", ^{
  __block id interpolatableObjectMock;

  beforeEach(^{
    interpolatableObjectMock = OCMClassMock([LTTestInterpolatableObject class]);
  });

  afterEach(^{
    interpolatableObjectMock = nil;
  });

  context(@"invalid API calls", ^{
    it(@"should raise when quering a compound interpolant with keyframes of invalid count", ^{
      expect(^{
        __unused LTCompoundParameterizedObject *result =
            [factory parameterizedObjectFromInterpolatableObjects:@[]];
      }).to.raise(NSInvalidArgumentException);

      expect(^{
        __unused LTCompoundParameterizedObject *result =
            [factory parameterizedObjectFromInterpolatableObjects:@[interpolatableObjectMock,
                                                                    interpolatableObjectMock]];
      }).to.raise(NSInvalidArgumentException);
    });
  });

  context(@"valid API calls", ^{
    __block NSArray<id<LTInterpolatableObject>> *keyFrames;
    __block NSSet<NSString *> *keys;
    __block id primitiveObjectMockForX;
    __block id primitiveObjectMockForY;

    beforeEach(^{
      keys = [NSSet setWithArray:@[@"x", @"y"]];
      OCMStub([interpolatableObjectMock propertiesToInterpolate]).andReturn(keys);
      keyFrames = @[interpolatableObjectMock];
      primitiveObjectMockForX = OCMProtocolMock(@protocol(LTPrimitiveParameterizedObject));
      primitiveObjectMockForY = OCMProtocolMock(@protocol(LTPrimitiveParameterizedObject));
      OCMStub([primitiveObjectMockForX minParametricValue]).andReturn(7);
      OCMStub([primitiveObjectMockForX maxParametricValue]).andReturn(8.5);
      OCMStub([primitiveObjectMockForY minParametricValue]).andReturn(7);
      OCMStub([primitiveObjectMockForY maxParametricValue]).andReturn(8.5);
    });

    it(@"should construct a parameterized object from primitive parameterized objects", ^{
      OCMExpect([interpolatableObjectMock valueForKey:@"x"]).andReturn(@1);
      OCMExpect([interpolatableObjectMock valueForKey:@"y"]).andReturn(@2);
      OCMExpect([[primitiveFactoryMock ignoringNonObjectArgs]
                 primitiveParameterizedObjectsFromValues:{}]).andReturn(primitiveObjectMockForX);
      OCMExpect([[primitiveFactoryMock ignoringNonObjectArgs]
                 primitiveParameterizedObjectsFromValues:{}]).andReturn(primitiveObjectMockForY);

      LTCompoundParameterizedObject *result =
          [factory parameterizedObjectFromInterpolatableObjects:keyFrames];

      expect(result).toNot.beNil();
      OCMVerifyAll(interpolatableObjectMock);
      OCMVerifyAll(primitiveFactoryMock);
    });

    it(@"should return parameterized object computing correct key to value mappings", ^{
      OCMExpect([[primitiveFactoryMock ignoringNonObjectArgs]
                 primitiveParameterizedObjectsFromValues:{}]).andReturn(primitiveObjectMockForX);
      OCMExpect([[primitiveFactoryMock ignoringNonObjectArgs]
                 primitiveParameterizedObjectsFromValues:{}]).andReturn(primitiveObjectMockForY);
      LTCompoundParameterizedObject *result =
          [factory parameterizedObjectFromInterpolatableObjects:keyFrames];
      OCMVerifyAll(primitiveFactoryMock);

      OCMExpect([primitiveObjectMockForX floatForParametricValue:0]).andReturn(9);
      OCMExpect([primitiveObjectMockForY floatForParametricValue:0]).andReturn(10);
      LTParameterizationKeyToValue *mapping = [result mappingForParametricValue:0];
      expect(mapping).to.equal(@{@"x": @9, @"y": @10});
      OCMVerifyAll(primitiveObjectMockForX);
      OCMVerifyAll(primitiveObjectMockForY);
    });

    it(@"should return parameterized object computing correct key to values mappings", ^{
      OCMExpect([[primitiveFactoryMock ignoringNonObjectArgs]
                 primitiveParameterizedObjectsFromValues:{}]).andReturn(primitiveObjectMockForX);
      OCMExpect([[primitiveFactoryMock ignoringNonObjectArgs]
                 primitiveParameterizedObjectsFromValues:{}]).andReturn(primitiveObjectMockForY);
      LTCompoundParameterizedObject *result =
          [factory parameterizedObjectFromInterpolatableObjects:keyFrames];
      OCMVerifyAll(primitiveFactoryMock);

      OCMExpect([primitiveObjectMockForX floatForParametricValue:1]).andReturn(11);
      OCMExpect([primitiveObjectMockForY floatForParametricValue:1]).andReturn(12);
      OCMExpect([primitiveObjectMockForX floatForParametricValue:2]).andReturn(13);
      OCMExpect([primitiveObjectMockForY floatForParametricValue:2]).andReturn(14);
      LTParameterizationKeyToValues *mapping = [result mappingForParametricValues:{1, 2}];
      expect([NSSet setWithArray:[mapping allKeys]]).to.equal(keys);
      expect(mapping[@"x"]).to.equal(@[@11, @13]);
      expect(mapping[@"y"]).to.equal(@[@12, @14]);
      OCMVerifyAll(primitiveObjectMockForY);

      OCMExpect([primitiveObjectMockForX floatForParametricValue:3]).andReturn(15);
      CGFloat value = [result floatForParametricValue:3 key:@"x"];
      expect(value).to.equal(15);
      OCMVerifyAll(primitiveObjectMockForX);

      OCMExpect([primitiveObjectMockForY floatForParametricValue:4]).andReturn(16);
      OCMExpect([primitiveObjectMockForY floatForParametricValue:5]).andReturn(17);
      CGFloats values = [result floatsForParametricValues:{4, 5} key:@"y"];
      expect(values.size()).to.equal(2);
      expect(values[0]).to.equal(16);
      expect(values[1]).to.equal(17);
      OCMVerifyAll(primitiveObjectMockForY);

      expect(result.parameterizationKeys).to.equal(keys);
      expect(result.minParametricValue).to.equal(7);
      expect(result.maxParametricValue).to.equal(8.5);
    });
  });
});

SpecEnd
