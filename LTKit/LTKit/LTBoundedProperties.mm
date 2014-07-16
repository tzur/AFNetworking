// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTBoundedProperties.h"

#import "LTGLKitExtensions.h"

#pragma mark -
#pragma mark LTBoundedType
#pragma mark -

@interface LTBoundedType ()
@property (copy, nonatomic) LTVoidBlock afterSetterBlock;
@end

@implementation LTBoundedType

- (instancetype)initBoundedType {
  return [super init];
}

- (instancetype)init {
  LTMethodNotImplemented();
}

- (void)afterSetter {
  if (self.afterSetterBlock) {
    self.afterSetterBlock();
  }
}

@end

#pragma mark -
#pragma mark LTBoundedCGFloat
#pragma mark -

@implementation LTBoundedCGFloat

+ (instancetype)min:(CGFloat)minValue max:(CGFloat)maxValue default:(CGFloat)defaultValue {
  return [[LTBoundedCGFloat alloc] initWithMin:minValue max:maxValue default:defaultValue
                              afterSetterBlock:^{}];
}

+ (instancetype)min:(CGFloat)minValue max:(CGFloat)maxValue default:(CGFloat)defaultValue
   afterSetterBlock:(LTVoidBlock)afterSetterBlock {
  return [[LTBoundedCGFloat alloc] initWithMin:minValue max:maxValue default:defaultValue
                              afterSetterBlock:afterSetterBlock];
}

- (instancetype)initWithMin:(CGFloat)minValue max:(CGFloat)maxValue default:(CGFloat)defaultValue
           afterSetterBlock:(LTVoidBlock)afterSetterBlock {
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
  _value = value;
  [self afterSetter];
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
                             afterSetterBlock:^{}];
}

+ (instancetype)min:(double)minValue max:(double)maxValue default:(double)defaultValue
   afterSetterBlock:(LTVoidBlock)afterSetterBlock {
  return [[LTBoundedDouble alloc] initWithMin:minValue max:maxValue default:defaultValue
                             afterSetterBlock:afterSetterBlock];
}

- (instancetype)initWithMin:(double)minValue max:(double)maxValue default:(double)defaultValue
           afterSetterBlock:(LTVoidBlock)afterSetterBlock {
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
  _value = value;
  [self afterSetter];
}

- (NSString *)debugDescription {
  return [@(self.value) stringValue];
}

@end

#pragma mark -
#pragma mark LTBoundedInteger
#pragma mark -

@implementation LTBoundedInteger

+ (instancetype)min:(NSInteger)minValue max:(NSInteger)maxValue default:(NSInteger)defaultValue {
  return [[LTBoundedInteger alloc] initWithMin:minValue max:maxValue default:defaultValue
                              afterSetterBlock:^{}];
}

+ (instancetype)min:(NSInteger)minValue max:(NSInteger)maxValue default:(NSInteger)defaultValue
   afterSetterBlock:(LTVoidBlock)afterSetterBlock {
  return [[LTBoundedInteger alloc] initWithMin:minValue max:maxValue default:defaultValue
                              afterSetterBlock:afterSetterBlock];
}

- (instancetype)initWithMin:(NSInteger)minValue max:(NSInteger)maxValue
                    default:(NSInteger)defaultValue afterSetterBlock:(LTVoidBlock)afterSetterBlock {
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
  _value = value;
  [self afterSetter];
}

- (NSString *)debugDescription {
  return [@(self.value) stringValue];
}

@end

#pragma mark -
#pragma mark LTBoundedUInteger
#pragma mark -

@implementation LTBoundedUInteger

+ (instancetype)min:(NSUInteger)minValue max:(NSUInteger)maxValue default:(NSUInteger)defaultValue {
  return [[LTBoundedUInteger alloc] initWithMin:minValue max:maxValue default:defaultValue
                               afterSetterBlock:^{}];
}

+ (instancetype)min:(NSUInteger)minValue max:(NSUInteger)maxValue default:(NSUInteger)defaultValue
   afterSetterBlock:(LTVoidBlock)afterSetterBlock {
  return [[LTBoundedUInteger alloc] initWithMin:minValue max:maxValue default:defaultValue
                               afterSetterBlock:afterSetterBlock];
}

- (instancetype)initWithMin:(NSUInteger)minValue max:(NSUInteger)maxValue
                    default:(NSUInteger)defaultValue
           afterSetterBlock:(LTVoidBlock)afterSetterBlock {
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
  _value = value;
  [self afterSetter];
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
                               afterSetterBlock:^{}];
}

+ (instancetype)min:(GLKVector3)minValue max:(GLKVector3)maxValue default:(GLKVector3)defaultValue
   afterSetterBlock:(LTVoidBlock)afterSetterBlock {
  return [[LTBoundedGLKVector3 alloc] initWithMin:minValue max:maxValue default:defaultValue
                               afterSetterBlock:afterSetterBlock];
}

- (instancetype)initWithMin:(GLKVector3)minValue max:(GLKVector3)maxValue
                    default:(GLKVector3)defaultValue
           afterSetterBlock:(LTVoidBlock)afterSetterBlock {
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
  _value = value;
  [self afterSetter];
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
                                 afterSetterBlock:^{}];
}

+ (instancetype)min:(GLKVector4)minValue max:(GLKVector4)maxValue default:(GLKVector4)defaultValue
   afterSetterBlock:(LTVoidBlock)afterSetterBlock {
  return [[LTBoundedGLKVector4 alloc] initWithMin:minValue max:maxValue default:defaultValue
                                 afterSetterBlock:afterSetterBlock];
}

- (instancetype)initWithMin:(GLKVector4)minValue max:(GLKVector4)maxValue
                    default:(GLKVector4)defaultValue
           afterSetterBlock:(LTVoidBlock)afterSetterBlock {
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
  _value = value;
  [self afterSetter];
}

- (NSString *)debugDescription {
  return [NSString stringWithFormat:@"(%g, %g, %g, %g)",
          self.value.x, self.value.y, self.value.z, self.value.w];
}

@end
