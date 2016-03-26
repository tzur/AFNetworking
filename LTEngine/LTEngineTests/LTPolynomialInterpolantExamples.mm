// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTPolynomialInterpolantExamples.h"

#import "LTPolynomialInterpolant.h"

NSString * const LTPolynomialInterpolantExamples = @"LTPolynomialInterpolantExamples";
NSString * const LTPolynomialInterpolantFactoryExamples = @"LTInterpolationRoutineFactoryExamples";

NSString * const LTPolynomialInterpolantClass = @"LTInterpolationRoutineExamplesClass";
NSString * const LTPolynomialInterpolantFactory = @"LTInterpolationRoutineFactoryExamplesFactory";

static NSArray *LTArrayWithInstancesOfObject(NSObject *object, NSUInteger numInstances) {
  NSMutableArray *array = [NSMutableArray array];
  for (NSUInteger i = 0; i < numInstances; ++i) {
    [array addObject:object];
  }
  return array;
}

static BOOL LTEqualWhithin(double a, double b, double withinValue = FLT_EPSILON) {
  double lowerBound = a - withinValue;
  double upperBound = a + withinValue;
  return (b >= lowerBound) && (b <= upperBound);
}

#pragma mark -
#pragma mark InterpolatedObject
#pragma mark -

@interface InterpolatedObject ()

@property (nonatomic) CGFloat pointToInterpolateX;
@property (nonatomic) CGFloat pointToInterpolateY;

@end

@implementation InterpolatedObject

- (instancetype)initWithInterpolatedProperties:(NSDictionary<NSString *, NSNumber *> *)properties {
  InterpolatedObject *object = [[InterpolatedObject alloc] init];
  [object setValuesForKeysWithDictionary:properties];
  return object;
}

- (NSArray *)propertiesToInterpolate {
  return @[@"floatToInterpolate", @"doubleToInterpolate",
           @"pointToInterpolateX", @"pointToInterpolateY"];
}

- (void)setPointToInterpolateX:(CGFloat)pointToInterpolateX {
  _pointToInterpolate.x = pointToInterpolateX;
}

- (void)setPointToInterpolateY:(CGFloat)pointToInterpolateY {
  _pointToInterpolate.y = pointToInterpolateY;
}

- (CGFloat)pointToInterpolateX {
  return _pointToInterpolate.x;
}

- (CGFloat)pointToInterpolateY {
  return _pointToInterpolate.y;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[self class]]) {
    return NO;
  }
  InterpolatedObject *other = object;
  return LTEqualWhithin(self.propertyNotToInterpolate, other.propertyNotToInterpolate) &&
         LTEqualWhithin(self.floatToInterpolate, other.floatToInterpolate) &&
         LTEqualWhithin(self.doubleToInterpolate, other.doubleToInterpolate) &&
         LTEqualWhithin(self.pointToInterpolate.x, other.pointToInterpolate.x) &&
         LTEqualWhithin(self.pointToInterpolate.y, other.pointToInterpolate.y);
}

@end

#pragma mark -
#pragma mark InterpolatedObjectWithOptionalInitializer
#pragma mark -

/// Used to test whether the \c initWithInterpolatedProperties initializer is used when available.
@interface InterpolatedObjectWithOptionalInitializer : InterpolatedObject

@property (nonatomic) BOOL didUseInitWithInterpolatedProperties;

@end

@implementation InterpolatedObjectWithOptionalInitializer

- (instancetype)initWithInterpolatedProperties:(NSDictionary __unused *)properties {
  if (self = [super init]) {
    self.didUseInitWithInterpolatedProperties = YES;
  }
  return self;
}

@end

#pragma mark -
#pragma mark Shared Tests
#pragma mark -

SharedExamplesBegin(LTPolynomialInterpolantExamples)

sharedExamplesFor(LTPolynomialInterpolantFactoryExamples, ^(NSDictionary *data) {
  __block id<LTPolynomialInterpolantFactory> factory;
  __block Class expectedInterpolationRoutineClass;
  __block InterpolatedObject *keyObject;
  __block NSUInteger expectedKeyFrames;
  
  beforeEach(^{
    factory = data[LTPolynomialInterpolantFactory];
    expectedInterpolationRoutineClass = data[LTPolynomialInterpolantClass];
    expectedKeyFrames = [factory expectedKeyFrames];
    keyObject = [[InterpolatedObject alloc] init];
  });
  
  it(@"should initialize with the expected number of keyframes", ^{
    NSArray *keyFrames = LTArrayWithInstancesOfObject(keyObject, expectedKeyFrames);
    LTPolynomialInterpolant *interpolant = [factory interpolantWithKeyFrames:keyFrames];
    expect([interpolant isKindOfClass:expectedInterpolationRoutineClass]).to.beTruthy();
  });
  
  it(@"expected number of keyframes should match the instance's expected number of keyframes", ^{
    NSArray *keyFrames = LTArrayWithInstancesOfObject(keyObject, expectedKeyFrames);
    LTPolynomialInterpolant *interpolant = [factory interpolantWithKeyFrames:keyFrames];
    expect([factory expectedKeyFrames]).to.equal([[interpolant class] expectedKeyFrames]);
  });
  
  it(@"range of interval in window should match the instance's range", ^{
    NSArray *keyFrames = LTArrayWithInstancesOfObject(keyObject, expectedKeyFrames);
    LTPolynomialInterpolant *interpolant = [factory interpolantWithKeyFrames:keyFrames];
    NSRange factoryRange = [factory rangeOfIntervalInWindow];
    NSRange instanceRange = [[interpolant class] rangeOfIntervalInWindow];
    expect(factoryRange.location).to.equal(instanceRange.location);
    expect(factoryRange.length).to.equal(instanceRange.length);
  });
});

sharedExamplesFor(LTPolynomialInterpolantExamples, ^(NSDictionary *data) {
  __block Class interpolantClass;
  __block InterpolatedObject *keyObject;
  __block NSUInteger expectedKeyFrames;
  
  beforeEach(^{
    interpolantClass = data[LTPolynomialInterpolantClass];
    expectedKeyFrames = [interpolantClass expectedKeyFrames];
    keyObject = [[InterpolatedObject alloc] init];
    keyObject.propertyNotToInterpolate = 1;
    keyObject.floatToInterpolate = 1;
    keyObject.doubleToInterpolate = 1;
    keyObject.pointToInterpolate = CGPointMake(2, 3);
  });
  
  context(@"initialization", ^{
    it(@"should initialize with the correct number of key frames", ^{
      expect(^{
        NSArray *keyFrames = LTArrayWithInstancesOfObject(keyObject, expectedKeyFrames);
        LTPolynomialInterpolant __unused *interpolant =
            [[interpolantClass alloc] initWithKeyFrames:keyFrames];
      }).notTo.raiseAny();
    });
    
    it(@"should not initialize with fewer key frames than necessary", ^{
      expect(^{
        NSArray *keyFrames = LTArrayWithInstancesOfObject(keyObject, expectedKeyFrames - 1);
        LTPolynomialInterpolant __unused *interpolant =
            [[interpolantClass alloc] initWithKeyFrames:keyFrames];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should not initialize with more key frames than necessary", ^{
      expect(^{
        NSArray *keyFrames = LTArrayWithInstancesOfObject(keyObject, expectedKeyFrames + 1);
        LTPolynomialInterpolant __unused *interpolant =
            [[interpolantClass alloc] initWithKeyFrames:keyFrames];
      }).to.raise(NSInvalidArgumentException);
    });
  });
  
  context(@"interpolation", ^{
    __block LTPolynomialInterpolant *interpolant;
    __block InterpolatedObject *interpolated;
    
    beforeEach(^{
      NSArray *keyFrames = LTArrayWithInstancesOfObject(keyObject, expectedKeyFrames);
      interpolant = [[interpolantClass alloc] initWithKeyFrames:keyFrames];
    });

    it(@"should return the correct range of the interval window", ^{
      NSRange range = [[interpolant class] rangeOfIntervalInWindow];
      expect(range.location).to.beInTheRangeOf(0, expectedKeyFrames);
      expect(range.location + range.length).to.beInTheRangeOf(0, expectedKeyFrames);
    });
    
    it(@"should not interpolate outside [0,1]", ^{
      expect(^{
        interpolated = [interpolant valueAtKey:-FLT_EPSILON];
      }).to.raise(NSInvalidArgumentException);
      expect(^{
        interpolated = [interpolant valueAtKey:1 + FLT_EPSILON];
      }).to.raise(NSInvalidArgumentException);
    });
    
    it(@"should interpolate a single property", ^{
      CGFloat value = [interpolant valueOfPropertyNamed:@"floatToInterpolate" atKey:0.5];
      expect(value).to.equal(keyObject.floatToInterpolate);
    });

    it(@"should return 0 when trying to interpolate a single invalid property", ^{
      CGFloat value = [interpolant valueOfPropertyNamed:@"propertyNotToInterpolate" atKey:0.5];
      expect(value).to.equal(0);
    });

    it(@"should interpolate a single property at multiple keys", ^{
      NSArray *keys = @[@0.25, @0.5, @0.75];
      CGFloats keysVector;
      for (NSNumber *key in keys) {
        keysVector.push_back([key doubleValue]);
      }
      
      CGFloats values = [interpolant valuesOfPropertyNamed:@"pointToInterpolateX"
                                                    atKeys:keysVector];
      expect(values.size()).to.equal(keysVector.size());
      for (NSUInteger i = 0; i < keys.count; ++i) {
        CGFloat key = keysVector[i];
        CGFloat value = values[i];
        CGFloat expectedValue = [interpolant valueOfPropertyNamed:@"pointToInterpolateX" atKey:key];
        expect(value).to.equal(expectedValue);
      }
    });
    
    it(@"should not interpolate undesired properties", ^{
      interpolated = [interpolant valueAtKey:0.5];
      expect(interpolated.propertyNotToInterpolate).to.equal(0);
    });
    
    it(@"should interpolate float properties", ^{
      interpolated = [interpolant valueAtKey:0.5];
      expect(interpolated.floatToInterpolate).to.equal(keyObject.floatToInterpolate);
    });
    
    it(@"should interpolate double properties", ^{
      interpolated = [interpolant valueAtKey:0.5];
      expect(interpolated.doubleToInterpolate).to.equal(keyObject.doubleToInterpolate);
    });
    
    it(@"should interpolate complex properties using helper properties", ^{
      interpolated = [interpolant valueAtKey:0.5];
      expect(interpolated.pointToInterpolate).to.equal(keyObject.pointToInterpolate);
    });
    
    it(@"should use the initWithInterpolatedProperties initializer if available", ^{
      InterpolatedObjectWithOptionalInitializer *keyObject =
          [[InterpolatedObjectWithOptionalInitializer alloc] init];
      expect(keyObject.didUseInitWithInterpolatedProperties).to.beFalsy();
      
      NSArray *keyFrames = LTArrayWithInstancesOfObject(keyObject, expectedKeyFrames);
      interpolant = [[interpolantClass alloc] initWithKeyFrames:keyFrames];
      InterpolatedObjectWithOptionalInitializer *interpolated = [interpolant valueAtKey:0.5];
      expect(interpolated.didUseInitWithInterpolatedProperties).to.beTruthy();
    });
  });
});

SharedExamplesEnd
