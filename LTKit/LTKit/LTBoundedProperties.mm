// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBoundedProperties.h"

#import "LTGLKitExtensions.h"

#pragma mark -
#pragma mark LTBoundedType
#pragma mark -

@implementation LTBoundedType

- (instancetype)initBoundedType {
  return [super init];
}

- (instancetype)init {
  LTMethodNotImplemented();
}

@end

#pragma mark -
#pragma mark LTBoundedCGFloat
#pragma mark -

@implementation LTBoundedCGFloat

+ (instancetype)min:(CGFloat)minValue max:(CGFloat)maxValue default:(CGFloat)defaultValue {
  return [[LTBoundedCGFloat alloc] initWithMin:minValue max:maxValue default:defaultValue
                              afterSetterBlock:^(CGFloat, CGFloat) {}];
}

+ (instancetype)min:(CGFloat)minValue max:(CGFloat)maxValue default:(CGFloat)defaultValue
   afterSetterBlock:(LTBoundedCGFloatSetterBlock)afterSetterBlock {
  return [[LTBoundedCGFloat alloc] initWithMin:minValue max:maxValue default:defaultValue
                              afterSetterBlock:afterSetterBlock];
}

- (instancetype)initWithMin:(CGFloat)minValue max:(CGFloat)maxValue default:(CGFloat)defaultValue
           afterSetterBlock:(LTBoundedCGFloatSetterBlock)afterSetterBlock {
  if (self = [super initBoundedType]) {
    LTParameterAssert(minValue <= maxValue);
    _minValue = minValue;
    _maxValue = maxValue;
    _defaultValue = defaultValue;
    self.value = defaultValue;
    self.afterSetterBlock = afterSetterBlock;
  }
  return self;
}

- (void)setValue:(CGFloat)value {
  LTParameterAssert(value >= self.minValue);
  LTParameterAssert(value <= self.maxValue);
  CGFloat oldValue = _value;
  _value = value;
  if (self.afterSetterBlock) {
    self.afterSetterBlock(value, oldValue);
  }
}

- (NSString *)debugDescription {
  return [@(self.value) stringValue];
}

@end

#pragma mark -
#pragma mark LTBoundedDouble
#pragma mark -

@implementation LTBoundedDouble

+ (instancetype)min:(double)minValue max:(double)maxValue default:(double)defaultValue {
  return [[LTBoundedDouble alloc] initWithMin:minValue max:maxValue default:defaultValue
                             afterSetterBlock:^(double, double) {}];
}

+ (instancetype)min:(double)minValue max:(double)maxValue default:(double)defaultValue
   afterSetterBlock:(LTBoundedDoubleSetterBlock)afterSetterBlock {
  return [[LTBoundedDouble alloc] initWithMin:minValue max:maxValue default:defaultValue
                             afterSetterBlock:afterSetterBlock];
}

- (instancetype)initWithMin:(double)minValue max:(double)maxValue default:(double)defaultValue
           afterSetterBlock:(LTBoundedDoubleSetterBlock)afterSetterBlock {
  if (self = [super initBoundedType]) {
    LTParameterAssert(minValue <= maxValue);
    _minValue = minValue;
    _maxValue = maxValue;
    _defaultValue = defaultValue;
    self.value = defaultValue;
    self.afterSetterBlock = afterSetterBlock;
  }
  return self;
}

- (void)setValue:(double)value {
  LTParameterAssert(value >= self.minValue);
  LTParameterAssert(value <= self.maxValue);
  double oldValue = _value;
  _value = value;
  if (self.afterSetterBlock) {
    self.afterSetterBlock(value, oldValue);
  }
}

- (NSString *)debugDescription {
  return [@(self.value) stringValue];
}

@end

#pragma mark -
#pragma mark LTBoundedNSInteger
#pragma mark -

@implementation LTBoundedNSInteger

+ (instancetype)min:(NSInteger)minValue max:(NSInteger)maxValue default:(NSInteger)defaultValue {
  return [[LTBoundedNSInteger alloc] initWithMin:minValue max:maxValue default:defaultValue
                                afterSetterBlock:^(NSInteger, NSInteger) {}];
}

+ (instancetype)min:(NSInteger)minValue max:(NSInteger)maxValue default:(NSInteger)defaultValue
   afterSetterBlock:(LTBoundedNSIntegerSetterBlock)afterSetterBlock {
  return [[LTBoundedNSInteger alloc] initWithMin:minValue max:maxValue default:defaultValue
                                afterSetterBlock:afterSetterBlock];
}

- (instancetype)initWithMin:(NSInteger)minValue max:(NSInteger)maxValue
                    default:(NSInteger)defaultValue
           afterSetterBlock:(LTBoundedNSIntegerSetterBlock)afterSetterBlock {
  if (self = [super initBoundedType]) {
    LTParameterAssert(minValue <= maxValue);
    _minValue = minValue;
    _maxValue = maxValue;
    _defaultValue = defaultValue;
    self.value = defaultValue;
    self.afterSetterBlock = afterSetterBlock;
  }
  return self;
}

- (void)setValue:(NSInteger)value {
  LTParameterAssert(value >= self.minValue);
  LTParameterAssert(value <= self.maxValue);
  NSInteger oldValue = _value;
  _value = value;
  if (self.afterSetterBlock) {
    self.afterSetterBlock(value, oldValue);
  }
}

- (NSString *)debugDescription {
  return [@(self.value) stringValue];
}

@end

#pragma mark -
#pragma mark LTBoundedNSUInteger
#pragma mark -

@implementation LTBoundedNSUInteger

+ (instancetype)min:(NSUInteger)minValue max:(NSUInteger)maxValue default:(NSUInteger)defaultValue {
  return [[LTBoundedNSUInteger alloc] initWithMin:minValue max:maxValue default:defaultValue
                                 afterSetterBlock:^(NSUInteger, NSUInteger) {}];
}

+ (instancetype)min:(NSUInteger)minValue max:(NSUInteger)maxValue default:(NSUInteger)defaultValue
   afterSetterBlock:(LTBoundedNSUIntegerSetterBlock)afterSetterBlock {
  return [[LTBoundedNSUInteger alloc] initWithMin:minValue max:maxValue default:defaultValue
                                 afterSetterBlock:afterSetterBlock];
}

- (instancetype)initWithMin:(NSUInteger)minValue max:(NSUInteger)maxValue
                    default:(NSUInteger)defaultValue
           afterSetterBlock:(LTBoundedNSUIntegerSetterBlock)afterSetterBlock {
  if (self = [super initBoundedType]) {
    LTParameterAssert(minValue <= maxValue);
    _minValue = minValue;
    _maxValue = maxValue;
    _defaultValue = defaultValue;
    self.value = defaultValue;
    self.afterSetterBlock = afterSetterBlock;
  }
  return self;
}

- (void)setValue:(NSUInteger)value {
  LTParameterAssert(value >= self.minValue);
  LTParameterAssert(value <= self.maxValue);
  NSUInteger oldValue = _value;
  _value = value;
  if (self.afterSetterBlock) {
    self.afterSetterBlock(value, oldValue);
  }
}

- (NSString *)debugDescription {
  return [@(self.value) stringValue];
}

@end

#pragma mark -
#pragma mark LTBoundedGLKVector3
#pragma mark -

@implementation LTBoundedGLKVector3

+ (instancetype)min:(GLKVector3)minValue max:(GLKVector3)maxValue default:(GLKVector3)defaultValue {
  return [[LTBoundedGLKVector3 alloc] initWithMin:minValue max:maxValue default:defaultValue
                                 afterSetterBlock:^(GLKVector3, GLKVector3) {}];
}

+ (instancetype)min:(GLKVector3)minValue max:(GLKVector3)maxValue default:(GLKVector3)defaultValue
   afterSetterBlock:(LTBoundedGLKVector3SetterBlock)afterSetterBlock {
  return [[LTBoundedGLKVector3 alloc] initWithMin:minValue max:maxValue default:defaultValue
                                 afterSetterBlock:afterSetterBlock];
}

- (instancetype)initWithMin:(GLKVector3)minValue max:(GLKVector3)maxValue
                    default:(GLKVector3)defaultValue
           afterSetterBlock:(LTBoundedGLKVector3SetterBlock)afterSetterBlock {
  if (self = [super initBoundedType]) {
    LTParameterAssert(minValue <= maxValue);
    _minValue = minValue;
    _maxValue = maxValue;
    _defaultValue = defaultValue;
    self.value = defaultValue;
    self.afterSetterBlock = afterSetterBlock;
  }
  return self;
}

- (void)setValue:(GLKVector3)value {
  LTParameterAssert(value >= self.minValue);
  LTParameterAssert(value <= self.maxValue);
  GLKVector3 oldValue = _value;
  _value = value;
  if (self.afterSetterBlock) {
    self.afterSetterBlock(value, oldValue);
  }
}

- (NSString *)debugDescription {
  return [NSString stringWithFormat:@"(%g, %g, %g)", self.value.x, self.value.y, self.value.z];
}

@end

#pragma mark -
#pragma mark LTBoundedGLKVector4
#pragma mark -

@implementation LTBoundedGLKVector4

+ (instancetype)min:(GLKVector4)minValue max:(GLKVector4)maxValue default:(GLKVector4)defaultValue {
  return [[LTBoundedGLKVector4 alloc] initWithMin:minValue max:maxValue default:defaultValue
                                 afterSetterBlock:^(GLKVector4, GLKVector4) {}];
}

+ (instancetype)min:(GLKVector4)minValue max:(GLKVector4)maxValue default:(GLKVector4)defaultValue
   afterSetterBlock:(LTBoundedGLKVector4SetterBlock)afterSetterBlock {
  return [[LTBoundedGLKVector4 alloc] initWithMin:minValue max:maxValue default:defaultValue
                                 afterSetterBlock:afterSetterBlock];
}

- (instancetype)initWithMin:(GLKVector4)minValue max:(GLKVector4)maxValue
                    default:(GLKVector4)defaultValue
           afterSetterBlock:(LTBoundedGLKVector4SetterBlock)afterSetterBlock {
  if (self = [super initBoundedType]) {
    LTParameterAssert(minValue <= maxValue);
    _minValue = minValue;
    _maxValue = maxValue;
    _defaultValue = defaultValue;
    self.value = defaultValue;
    self.afterSetterBlock = afterSetterBlock;
  }
  return self;
}

- (void)setValue:(GLKVector4)value {
  LTParameterAssert(value >= self.minValue);
  LTParameterAssert(value <= self.maxValue);
  GLKVector4 oldValue = _value;
  _value = value;
  if (self.afterSetterBlock) {
    self.afterSetterBlock(value, oldValue);
  }
}

- (NSString *)debugDescription {
  return [NSString stringWithFormat:@"(%g, %g, %g, %g)",
          self.value.x, self.value.y, self.value.z, self.value.w];
}

@end
