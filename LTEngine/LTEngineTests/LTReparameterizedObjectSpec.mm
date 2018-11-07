// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTReparameterizedObject.h"

#import "LTParameterizationKeyToValues.h"
#import "LTReparameterization.h"

@interface LTReparameterizedObjectTestObject : NSObject <LTParameterizedValueObject>
@property (nonatomic) std::vector<CGFloat> receivedValues;
@property (nonatomic) NSString *receivedKey;
@property (strong, nonatomic) LTParameterizationKeyToValue *returnedKeyToValue;
@property (strong, nonatomic) LTParameterizationKeyToValues *returnedKeyToValues;
@end

@implementation LTReparameterizedObjectTestObject

- (BOOL)isEqual:(id)object {
  return [object isKindOfClass:[self class]];
}

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

- (LTParameterizationKeyToValue *)mappingForParametricValue:(CGFloat)value {
  self.receivedValues = {value};
  return self.returnedKeyToValue;
}

- (LTParameterizationKeyToValues *)mappingForParametricValues:(const std::vector<CGFloat> &)values {
  self.receivedValues = values;
  return self.returnedKeyToValues;
}

- (CGFloat)floatForParametricValue:(CGFloat)value key:(NSString *)key {
  self.receivedValues = {value};
  self.receivedKey = key;
  return 7;
}

- (std::vector<CGFloat>)floatsForParametricValues:(const std::vector<CGFloat> &)values
                                              key:(NSString *)key {
  self.receivedValues = values;
  self.receivedKey = key;
  return {7, 8};
}

- (NSOrderedSet<NSString *> *)parameterizationKeys {
  return [NSOrderedSet orderedSetWithArray:@[@"key", @"anotherKey"]];
}

- (CGFloat)minParametricValue {
  return 1;
}

- (CGFloat)maxParametricValue {
  return 2;
}

@end

SpecBegin(LTReparameterizedObject)

__block LTReparameterizedObject<LTReparameterizedObjectTestObject *> *reparameterizedObject;
__block LTReparameterizedObjectTestObject *parameterizedObject;
__block id reparameterizationMock;

beforeEach(^{
  parameterizedObject = [[LTReparameterizedObjectTestObject alloc] init];
  reparameterizationMock = OCMClassMock([LTReparameterization class]);
  OCMStub([reparameterizationMock minParametricValue]).andReturn(3);
  OCMStub([reparameterizationMock maxParametricValue]).andReturn(4);
  reparameterizedObject =
      [[LTReparameterizedObject alloc] initWithParameterizedObject:parameterizedObject
                                                reparameterization:reparameterizationMock];
});

afterEach(^{
  parameterizedObject = nil;
});

context(@"initialization", ^{
  it(@"should initialize correctly", ^{
    expect(reparameterizedObject).toNot.beNil();
    expect(reparameterizedObject.parameterizedObject).to.beIdenticalTo(parameterizedObject);
    expect(reparameterizedObject.reparameterization).to.beIdenticalTo(reparameterizationMock);
  });
});

context(@"NSObject protocol", ^{
  context(@"comparison with isEqual:", ^{
    it(@"should return YES when comparing to itself", ^{
      expect([reparameterizedObject isEqual:reparameterizedObject]).to.beTruthy();
    });

    it(@"should return YES when comparing to an object with the same properties", ^{
      LTReparameterizedObject *anotherReparameterizedObject =
          [[LTReparameterizedObject alloc] initWithParameterizedObject:parameterizedObject
                                                    reparameterization:reparameterizationMock];
      expect([reparameterizedObject isEqual:anotherReparameterizedObject]).to.beTruthy();
    });

    it(@"should return NO when comparing to nil", ^{
      LTReparameterizedObject *anotherReparameterizedObject = nil;
      expect([reparameterizedObject isEqual:anotherReparameterizedObject]).to.beFalsy();
    });

    it(@"should return NO when comparing to an object of a different class", ^{
      expect([reparameterizedObject isEqual:[[NSObject alloc] init]]).to.beFalsy();
    });

    it(@"should return NO when comparing to an object with different properties", ^{
      id anotherReparameterizationMock = OCMClassMock([LTReparameterization class]);
      OCMStub([anotherReparameterizationMock isEqual:reparameterizationMock]).andReturn(NO);

      LTReparameterizedObject *anotherReparameterizedObject =
          [[LTReparameterizedObject alloc]
           initWithParameterizedObject:parameterizedObject
           reparameterization:anotherReparameterizationMock];

      expect([reparameterizedObject isEqual:anotherReparameterizedObject]).to.beFalsy();
    });
  });

  context(@"hash", ^{
    it(@"should return the same hash value for equal objects", ^{
      LTReparameterizedObject *anotherReparameterizedObject =
          [[LTReparameterizedObject alloc] initWithParameterizedObject:parameterizedObject
                                                    reparameterization:reparameterizationMock];
      expect([reparameterizedObject hash]).to.equal([anotherReparameterizedObject hash]);
    });
  });
});

context(@"NSCopying protocol", ^{
  it(@"should return itself as copy, due to immutability", ^{
    expect([reparameterizedObject copy]).to.beIdenticalTo(reparameterizedObject);
  });
});

context(@"LTParameterizedObject protocol", ^{
  it(@"should have the same intrinsic parametric range as the reparameterization", ^{
    expect(reparameterizedObject.minParametricValue).to.equal(3);
    expect(reparameterizedObject.maxParametricValue).to.equal(4);
  });

  it(@"should return correct mapping for correctly reparameterized parametric value", ^{
    id mappingMock = OCMClassMock([LTParameterizationKeyToValue class]);
    parameterizedObject.returnedKeyToValue = mappingMock;
    OCMExpect([reparameterizationMock floatForParametricValue:3]).andReturn(0);

    LTParameterizationKeyToValue *mapping = [reparameterizedObject mappingForParametricValue:3];

    expect(mapping).to.beIdenticalTo(mappingMock);
    expect(parameterizedObject.receivedValues.size()).to.equal(1);
    expect(parameterizedObject.receivedValues[0]).to.equal(1);
    OCMVerifyAll(reparameterizationMock);
  });

  it(@"should return correct mapping for correctly reparameterized parametric values", ^{
    id mappingMock = OCMClassMock([LTParameterizationKeyToValues class]);
    parameterizedObject.returnedKeyToValues = mappingMock;
    OCMExpect([reparameterizationMock floatForParametricValue:3]).andReturn(0);
    OCMExpect([reparameterizationMock floatForParametricValue:4]).andReturn(1);

    std::vector<CGFloat> parametricValues = {3, 4};
    LTParameterizationKeyToValues *mapping =
        [reparameterizedObject mappingForParametricValues:parametricValues];

    expect(mapping).to.beIdenticalTo(mappingMock);
    expect(parameterizedObject.receivedValues.size()).to.equal(2);
    expect(parameterizedObject.receivedValues[0]).to.equal(1);
    expect(parameterizedObject.receivedValues[1]).to.equal(2);
    OCMVerifyAll(reparameterizationMock);
  });

  context(@"parameterization keys", ^{
    __block NSString *key;

    beforeEach(^{
      key = @"TestProperty";
    });

    it(@"should return correct value for correctly reparameterized parametric value", ^{
      OCMExpect([reparameterizationMock floatForParametricValue:3]).andReturn(0);

      CGFloat value = [reparameterizedObject floatForParametricValue:3 key:key];

      expect(value).to.equal(7);
      expect(parameterizedObject.receivedValues.size()).to.equal(1);
      expect(parameterizedObject.receivedValues[0]).to.equal(1);
      expect(parameterizedObject.receivedKey).to.equal(key);
      OCMVerifyAll(reparameterizationMock);
    });

    it(@"should return correct values for correctly reparameterized parametric values", ^{
      OCMExpect([reparameterizationMock floatForParametricValue:3]).andReturn(0);
      OCMExpect([reparameterizationMock floatForParametricValue:4]).andReturn(1);

      std::vector<CGFloat> parametricValues = {3, 4};
      std::vector<CGFloat> result =
          [reparameterizedObject floatsForParametricValues:parametricValues key:key];

      expect(result.size()).to.equal(2);
      expect(result[0]).to.equal(7);
      expect(result[1]).to.equal(8);
      expect(parameterizedObject.receivedValues.size()).to.equal(2);
      expect(parameterizedObject.receivedValues[0]).to.equal(1);
      expect(parameterizedObject.receivedValues[1]).to.equal(2);
      expect(parameterizedObject.receivedKey).to.equal(key);
      OCMVerifyAll(reparameterizationMock);
    });

    it(@"should have the same parameterizationKeys as the wrapped parameterized object", ^{
      expect(reparameterizedObject.parameterizationKeys)
          .to.equal(parameterizedObject.parameterizationKeys);
    });
  });
});

SpecEnd
