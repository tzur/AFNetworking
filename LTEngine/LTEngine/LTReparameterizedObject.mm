// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTReparameterizedObject.h"

#import "LTReparameterization.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTReparameterizedObject

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithParameterizedObject:(id<LTParameterizedValueObject>)parameterizedObject
                         reparameterization:(LTReparameterization *)reparameterization {
  if (self = [super init]) {
    _parameterizedObject = parameterizedObject;
    _reparameterization = reparameterization;
  }
  return self;
}

#pragma mark -
#pragma mark NSObject
#pragma mark -

- (BOOL)isEqual:(LTReparameterizedObject *)reparameterizedObject {
  if (self == reparameterizedObject) {
    return YES;
  }

  if (![reparameterizedObject isKindOfClass:[self class]]) {
    return NO;
  }

  return [self.parameterizedObject isEqual:reparameterizedObject.parameterizedObject] &&
      [self.reparameterization isEqual:reparameterizedObject.reparameterization];
}

- (NSUInteger)hash {
  return self.parameterizedObject.hash ^ self.reparameterization.hash;
}

#pragma mark -
#pragma mark NSCopying
#pragma mark -

- (id)copyWithZone:(nullable NSZone __unused *)zone {
  return self;
}

#pragma mark -
#pragma mark LTParameterizedObject - Methods
#pragma mark -

- (LTParameterizationKeyToValue *)mappingForParametricValue:(CGFloat)value {
  return [self.parameterizedObject
          mappingForParametricValue:[self reparameterizedParametricValue:value]];
}

- (LTParameterizationKeyToValues *)mappingForParametricValues:(const CGFloats &)values {
  return [self.parameterizedObject
          mappingForParametricValues:[self reparameterizedParametricValues:values]];
}

- (CGFloat)floatForParametricValue:(CGFloat)value key:(NSString *)key {
  return [self.parameterizedObject
          floatForParametricValue:[self reparameterizedParametricValue:value] key:key];
}

- (CGFloats)floatsForParametricValues:(const CGFloats &)values key:(NSString *)key {
  return [self.parameterizedObject
          floatsForParametricValues:[self reparameterizedParametricValues:values] key:key];
}

#pragma mark -
#pragma mark LTParameterizedObject - Properties
#pragma mark -

- (NSSet<NSString *> *)parameterizationKeys {
  return self.parameterizedObject.parameterizationKeys;
}

- (CGFloat)minParametricValue {
  return self.reparameterization.minParametricValue;
}

- (CGFloat)maxParametricValue {
  return self.reparameterization.maxParametricValue;
}

#pragma mark -
#pragma mark Auxiliary methods
#pragma mark -

- (CGFloat)reparameterizedParametricValue:(CGFloat)value {
  CGFloat result = [self.reparameterization floatForParametricValue:value];
  CGFloat min = self.parameterizedObject.minParametricValue;
  CGFloat max = self.parameterizedObject.maxParametricValue;
  return min + result * (max - min);
}

- (CGFloats)reparameterizedParametricValues:(const CGFloats &)values {
  CGFloats result(values.size());
  std::transform(values.cbegin(), values.cend(), result.begin(), [self](const CGFloat &value) {
    return [self reparameterizedParametricValue:value];
  });
  return result;
}

@end

NS_ASSUME_NONNULL_END
