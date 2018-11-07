// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTCompoundParameterizedObjectFactory.h"

#import "LTBasicParameterizedObject.h"
#import "LTBasicParameterizedObjectFactory.h"
#import "LTCompoundParameterizedObject.h"
#import "LTInterpolatableObject.h"
#import "LTParameterizationKeyToValues.h"

@interface LTTestInterpolatableObject : NSObject <LTInterpolatableObject>
@end

@implementation LTTestInterpolatableObject

- (NSSet<NSString *> *)propertiesToInterpolate {
  return nil;
}

@end

@interface LTBasicTestFactory : NSObject <LTBasicParameterizedObjectFactory>

/// Parameterized objects to return on each call to \c baseParameterizedObjectsFromValues:.
@property (nonatomic) NSArray<id<LTBasicParameterizedObject>> *parameterizedObjects;

/// Next parameterized object to return.
@property (nonatomic) NSUInteger nextParameterizedObjectIndex;

@end

@implementation LTBasicTestFactory

- (id<LTBasicParameterizedObject>)
    baseParameterizedObjectsFromValues:(__unused std::vector<CGFloat>)values {
  if (self.nextParameterizedObjectIndex < self.parameterizedObjects.count) {
    auto object = self.parameterizedObjects[self.nextParameterizedObjectIndex];
    ++self.nextParameterizedObjectIndex;
    return object;
  }

  return OCMProtocolMock(@protocol(LTBasicParameterizedObject));
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
__block LTBasicTestFactory *basicFactory;

beforeEach(^{
  basicFactory = [[LTBasicTestFactory alloc] init];
  factory =
      [[LTCompoundParameterizedObjectFactory<LTTestInterpolatableObject *> alloc]
       initWithBasicFactory:basicFactory];
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(factory.numberOfRequiredInterpolatableObjects)
        .to.equal([[basicFactory class] numberOfRequiredValues]);
    expect(factory.intrinsicParametricRange.location)
        .to.equal([[basicFactory class] intrinsicParametricRange].location);
    expect(factory.intrinsicParametricRange.length)
        .to.equal([[basicFactory class] intrinsicParametricRange].length);
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
    __block id basicObjectMockForX;
    __block id basicObjectMockForY;

    beforeEach(^{
      keys = [NSSet setWithArray:@[@"x", @"y"]];
      OCMStub([interpolatableObjectMock propertiesToInterpolate]).andReturn(keys);
      keyFrames = @[interpolatableObjectMock];
      basicObjectMockForX = OCMProtocolMock(@protocol(LTBasicParameterizedObject));
      basicObjectMockForY = OCMProtocolMock(@protocol(LTBasicParameterizedObject));
      OCMStub([basicObjectMockForX minParametricValue]).andReturn(7);
      OCMStub([basicObjectMockForX maxParametricValue]).andReturn(8.5);
      OCMStub([basicObjectMockForY minParametricValue]).andReturn(7);
      OCMStub([basicObjectMockForY maxParametricValue]).andReturn(8.5);

      basicFactory.parameterizedObjects = @[basicObjectMockForX, basicObjectMockForY];
    });

    it(@"should construct a parameterized object from basic parameterized objects", ^{
      OCMExpect([interpolatableObjectMock valueForKey:@"x"]).andReturn(@1);
      OCMExpect([interpolatableObjectMock valueForKey:@"y"]).andReturn(@2);

      LTCompoundParameterizedObject *result =
          [factory parameterizedObjectFromInterpolatableObjects:keyFrames];

      expect(result).toNot.beNil();
      OCMVerifyAll(interpolatableObjectMock);
      expect(basicFactory.nextParameterizedObjectIndex).to.equal(2);
    });

    it(@"should return parameterized object computing correct key to value mappings", ^{
      LTCompoundParameterizedObject *result =
          [factory parameterizedObjectFromInterpolatableObjects:keyFrames];
      expect(basicFactory.nextParameterizedObjectIndex).to.equal(2);

      OCMExpect([basicObjectMockForX floatForParametricValue:0]).andReturn(9);
      OCMExpect([basicObjectMockForY floatForParametricValue:0]).andReturn(10);
      LTParameterizationKeyToValue *mapping = [result mappingForParametricValue:0];
      expect(mapping).to.equal(@{@"x": @9, @"y": @10});
      OCMVerifyAll(basicObjectMockForX);
      OCMVerifyAll(basicObjectMockForY);
    });

    it(@"should return parameterized object computing correct key to values mappings", ^{
      LTCompoundParameterizedObject *result =
          [factory parameterizedObjectFromInterpolatableObjects:keyFrames];
      expect(basicFactory.nextParameterizedObjectIndex).to.equal(2);

      OCMExpect([basicObjectMockForX floatForParametricValue:1]).andReturn(11);
      OCMExpect([basicObjectMockForY floatForParametricValue:1]).andReturn(12);
      OCMExpect([basicObjectMockForX floatForParametricValue:2]).andReturn(13);
      OCMExpect([basicObjectMockForY floatForParametricValue:2]).andReturn(14);

      LTParameterizationKeyToValues *mapping = [result mappingForParametricValues:{1, 2}];

      std::vector<CGFloat> xValues = [mapping valuesForKey:@"x"];
      std::vector<CGFloat> yValues = [mapping valuesForKey:@"y"];

      expect([mapping.keys set]).to.equal(keys);
      expect(xValues.size()).to.equal(2);
      expect(xValues[0]).to.equal(11);
      expect(xValues[1]).to.equal(13);
      expect(yValues.size()).to.equal(2);
      expect(yValues[0]).to.equal(12);
      expect(yValues[1]).to.equal(14);
      OCMVerifyAll(basicObjectMockForY);

      OCMExpect([basicObjectMockForX floatForParametricValue:3]).andReturn(15);
      CGFloat value = [result floatForParametricValue:3 key:@"x"];
      expect(value).to.equal(15);
      OCMVerifyAll(basicObjectMockForX);

      OCMExpect([basicObjectMockForY floatForParametricValue:4]).andReturn(16);
      OCMExpect([basicObjectMockForY floatForParametricValue:5]).andReturn(17);
      std::vector<CGFloat> values = [result floatsForParametricValues:{4, 5} key:@"y"];
      expect(values.size()).to.equal(2);
      expect(values[0]).to.equal(16);
      expect(values[1]).to.equal(17);
      OCMVerifyAll(basicObjectMockForY);

      expect(result.parameterizationKeys).to.equal([NSOrderedSet orderedSetWithSet:keys]);
      expect(result.minParametricValue).to.equal(7);
      expect(result.maxParametricValue).to.equal(8.5);
    });
  });
});

SpecEnd
