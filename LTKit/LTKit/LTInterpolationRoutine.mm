// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTInterpolationRoutine.h"

#import "LTInterpolatedObject.h"

@interface LTInterpolationRoutine ()

/// Array of objects acting as keyframes for the interpolation.
@property (strong, nonatomic) NSArray *keyFrames;

/// Dictionary mapping each property to interpolate to its polynomial coefficients (\c NSArray of
/// \c NSNumbers).
@property (strong, nonatomic) NSDictionary *coefficients;

@end

@implementation LTInterpolationRoutine

+ (NSUInteger)expectedKeyFrames {
  LTAssert(NO, "@Abstract method that should be implemented by subclasses");
}

- (instancetype)initWithKeyFrames:(NSArray *)keyFrames {
  if (self = [super init]) {
    [self validateKeyFrames:(NSArray *)keyFrames];
    self.keyFrames = [keyFrames copy];
    self.coefficients = [self calculateCoefficientsForKeyFrames:self.keyFrames];
  }
  return self;
}

- (void)validateKeyFrames:(NSArray *)keyFrames {
  LTParameterAssert(keyFrames.count == [[self class] expectedKeyFrames]);
  for (id object in keyFrames) {
    LTParameterAssert([object conformsToProtocol:@protocol(LTInterpolatedObject)]);
    LTParameterAssert([object isKindOfClass:[keyFrames.firstObject class]]);
  }
}

- (NSDictionary *)calculateCoefficientsForKeyFrames:(NSArray __unused *)keyFrames {
  LTAssert(NO, "@Abstract method that should be implemented by subclasses");
}

- (id)valueAtKey:(CGFloat)key {
  LTParameterAssert(key >= 0 && key <= 1);
  NSMutableDictionary *properties = [NSMutableDictionary dictionary];
  for (NSString *propertyName in [self.keyFrames.firstObject propertiesToInterpolate]) {
    properties[propertyName] = [self valueOfPropertyNamed:propertyName atKey:key];
  }
  
  if ([self.keyFrames.firstObject respondsToSelector:@selector(initWithInterpolatedProperties:)]) {
    return [[[self.keyFrames.firstObject class] alloc] initWithInterpolatedProperties:properties];
  } else {
    NSObject *object = [[[self.keyFrames.firstObject class] alloc] init];
    [object setValuesForKeysWithDictionary:properties];
    return object;
  }
}

- (NSNumber *)valueOfPropertyNamed:(NSString *)name atKey:(CGFloat)key {
  NSArray *coefficientsForProperty = self.coefficients[name];
  double value = 0;
  for (NSNumber *coefficient in coefficientsForProperty) {
    value = key * value + [coefficient doubleValue];
  }
  return @(value);
}

@end
