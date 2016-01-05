// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTReparameterization+ArcLength.h"

#import "LTEasyVectorBoxing.h"
#import "LTParameterizedValueObject.h"

@interface LTParameterizedTestObject : NSObject <LTParameterizedValueObject>
@property (nonatomic) CGFloats receivedValuesForXKey;
@property (nonatomic) CGFloats receivedValuesForYKey;
@property (nonatomic) CGFloats returnedValuesForXKey;
@property (nonatomic) CGFloats returnedValuesForYKey;
@end

@implementation LTParameterizedTestObject

- (id)copyWithZone:(NSZone __unused *)zone {
  LTMethodNotImplemented();
}

- (LTParameterizationKeyToValue *)mappingForParametricValue:(__unused CGFloat)value {
  LTMethodNotImplemented();
}

- (LTParameterizationKeyToValues *)mappingForParametricValues:(const CGFloats __unused &)values {
  LTMethodNotImplemented();
}

- (CGFloat)floatForParametricValue:(__unused CGFloat)value key:(NSString __unused *)key {
  LTMethodNotImplemented();
}

- (CGFloats)floatsForParametricValues:(const CGFloats &)values key:(NSString *)key {
  if ([key isEqualToString:@"xCoordinate"]) {
    self.receivedValuesForXKey = values;
    return self.returnedValuesForXKey;
  } else if ([key isEqualToString:@"yCoordinate"]) {
    self.receivedValuesForYKey = values;
    return self.returnedValuesForYKey;
  }
  return {};
}

- (NSSet<NSString *> *)parameterizationKeys {
  return [NSSet setWithArray:@[@"xCoordinate", @"yCoordinate"]];
}

- (CGFloat)minParametricValue {
  return 2;
}

- (CGFloat)maxParametricValue {
  return 6;
}

@end

SpecBegin(LTReparameterization_ArcLength)

static const CGFloat kEpsilon = 1e-6;

__block LTReparameterization *reparameterization;
__block LTParameterizedTestObject *parameterizedObject;

beforeEach(^{
  parameterizedObject = [[LTParameterizedTestObject alloc] init];
});

context(@"valid API calls", ^{
  __block NSUInteger numberOfSamples;
  __block CGPoint p0;
  __block CGPoint p1;
  __block CGFloat desiredMinParametricValue;

  context(@"line segment", ^{
    beforeEach(^{
      p0 = CGPointZero;
      p1 = CGPointMake(1, 1);
      parameterizedObject.returnedValuesForXKey = {p0.x, p1.x};
      parameterizedObject.returnedValuesForYKey = {p0.y, p1.y};

      numberOfSamples = 2;
      desiredMinParametricValue = 7;
      reparameterization =
          [LTReparameterization arcLengthReparameterizationForObject:parameterizedObject
                                                     numberOfSamples:numberOfSamples
                                                  minParametricValue:desiredMinParametricValue
                                   parameterizationKeyForXCoordinate:@"xCoordinate"
                                   parameterizationKeyForYCoordinate:@"yCoordinate"];
    });

    it(@"should return a reparameterization with the correct intrinsic parametric range", ^{
      expect(reparameterization.minParametricValue).to.equal(desiredMinParametricValue);
      expect(reparameterization.maxParametricValue)
          .to.beCloseToWithin(desiredMinParametricValue + CGPointDistance(p0, p1), kEpsilon);
    });

    it(@"should create reparameterization using correct values for x-coordinates", ^{
      expect(parameterizedObject.receivedValuesForXKey.size()).to.equal(numberOfSamples);

      LTVector2 receivedValuesForXKey(parameterizedObject.receivedValuesForXKey.front(),
                                      parameterizedObject.receivedValuesForXKey.back());
      LTVector2 expectedValues(parameterizedObject.minParametricValue,
                               parameterizedObject.maxParametricValue);

      expect(receivedValuesForXKey).to.equal(expectedValues);
    });

    it(@"should create reparameterization using correct values for y-coordinates", ^{
      expect(parameterizedObject.receivedValuesForYKey.size()).to.equal(numberOfSamples);

      LTVector2 receivedValuesForYKey(parameterizedObject.receivedValuesForYKey.front(),
                                      parameterizedObject.receivedValuesForYKey.back());
      LTVector2 expectedValues(parameterizedObject.minParametricValue,
                               parameterizedObject.maxParametricValue);

      expect(receivedValuesForYKey).to.equal(expectedValues);
    });
  });

  context(@"polyline", ^{
    __block CGPoint p2;
    __block NSArray<NSValue *> *expectedValues;

    beforeEach(^{
      p0 = CGPointZero;
      p1 = CGPointMake(0, 1);
      p2 = CGPointMake(1, 1);
      parameterizedObject.returnedValuesForXKey =
          {p0.x, (p0.x + p1.x) / 2, p1.x, (p1.x + p2.x) / 2, p2.x};
      parameterizedObject.returnedValuesForYKey =
          {p0.y, (p0.y + p1.y) / 2, p1.y, (p1.y + p2.y) / 2, p2.y};

      numberOfSamples = 5;
      desiredMinParametricValue = 7;
      reparameterization =
          [LTReparameterization arcLengthReparameterizationForObject:parameterizedObject
                                                     numberOfSamples:numberOfSamples
                                                  minParametricValue:desiredMinParametricValue
                                   parameterizationKeyForXCoordinate:@"xCoordinate"
                                   parameterizationKeyForYCoordinate:@"yCoordinate"];
      CGFloats values{parameterizedObject.minParametricValue, 3, 4, 5,
                      parameterizedObject.maxParametricValue};
      expectedValues = $(values);
    });

    it(@"should return a reparameterization with the correct intrinsic parametric range", ^{
      expect(reparameterization.minParametricValue).to.equal(desiredMinParametricValue);
      expect(reparameterization.maxParametricValue)
          .to.beCloseToWithin(desiredMinParametricValue + CGPointDistance(p0, p1) +
                              CGPointDistance(p1, p2), kEpsilon);
    });

    it(@"should create reparameterization using correct values for x-coordinates", ^{
      NSArray<NSValue *> *receivedValuesForXKey = $(parameterizedObject.receivedValuesForXKey);
      expect(receivedValuesForXKey).to.equal(expectedValues);
    });

    it(@"should create reparameterization using correct values for y-coordinates", ^{
      NSArray<NSValue *> *receivedValuesForYKey = $(parameterizedObject.receivedValuesForYKey);
      expect(receivedValuesForYKey).to.equal(expectedValues);
    });
  });
});

context(@"invalid API calls", ^{
  it(@"should raise when calling with numberOfSamples smaller than 2", ^{
    expect(^{
      reparameterization =
          [LTReparameterization arcLengthReparameterizationForObject:parameterizedObject
                                                     numberOfSamples:1 minParametricValue:0
                                   parameterizationKeyForXCoordinate:@"xCoordinate"
                                   parameterizationKeyForYCoordinate:@"yCoordinate"];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise when calling with invalid keys", ^{
    expect(^{
      reparameterization =
          [LTReparameterization arcLengthReparameterizationForObject:parameterizedObject
                                                     numberOfSamples:1 minParametricValue:0
                                   parameterizationKeyForXCoordinate:@"nonExistingKeys"
                                   parameterizationKeyForYCoordinate:@"yCoordinate"];
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
