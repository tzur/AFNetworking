// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Block called after setting the \c LTBoundedCGFloat's value.
typedef void (^LTBoundedCGFloatSetterBlock)(CGFloat value, CGFloat oldValue);
/// Block called after setting the \c LTBoundedDouble's value.
typedef void (^LTBoundedDoubleSetterBlock)(double value, double oldValue);
/// Block called after setting the \c LTBoundedNSInteger's value.
typedef void (^LTBoundedNSIntegerSetterBlock)(NSInteger value, NSInteger oldValue);
/// Block called after setting the \c LTBoundedNSUInteger's value.
typedef void (^LTBoundedNSUIntegerSetterBlock)(NSUInteger value, NSUInteger oldValue);
/// Block called after setting the \c LTBoundedGLKVector3's value.
typedef void (^LTBoundedGLKVector3SetterBlock)(GLKVector3 value, GLKVector3 oldValue);
/// Block called after setting the \c LTBoundedGLKVector4's value.
typedef void (^LTBoundedGLKVector4SetterBlock)(GLKVector4 value, GLKVector4 oldValue);

/// Base class for the bounded type objects.
@interface LTBoundedType : NSObject
@end

/// Represents a \c CGFloat bounded in the range [minValue,maxValue] with a defined default value.
@interface LTBoundedCGFloat : LTBoundedType

+ (instancetype)min:(CGFloat)minValue max:(CGFloat)maxValue default:(CGFloat)defaultValue;
+ (instancetype)min:(CGFloat)minValue max:(CGFloat)maxValue default:(CGFloat)defaultValue
    afterSetterBlock:(LTBoundedCGFloatSetterBlock)afterSetterBlock;

@property (nonatomic) CGFloat value;
@property (readonly, nonatomic) CGFloat minValue;
@property (readonly, nonatomic) CGFloat maxValue;
@property (readonly, nonatomic) CGFloat defaultValue;
@property (copy, nonatomic) LTBoundedCGFloatSetterBlock afterSetterBlock;

@end

/// Represents a \c double bounded in the range [minValue,maxValue] with a defined default value.
@interface LTBoundedDouble : LTBoundedType

+ (instancetype)min:(double)minValue max:(double)maxValue default:(double)defaultValue;
+ (instancetype)min:(double)minValue max:(double)maxValue default:(double)defaultValue
   afterSetterBlock:(LTBoundedDoubleSetterBlock)afterSetterBlock;

@property (nonatomic) double value;
@property (readonly, nonatomic) double minValue;
@property (readonly, nonatomic) double maxValue;
@property (readonly, nonatomic) double defaultValue;
@property (copy, nonatomic) LTBoundedDoubleSetterBlock afterSetterBlock;

@end

/// Represents an \c NSInteger bounded in the range [minValue,maxValue] with a defined default
/// value.
@interface LTBoundedNSInteger : LTBoundedType

+ (instancetype)min:(NSInteger)minValue max:(NSInteger)maxValue default:(NSInteger)defaultValue;
+ (instancetype)min:(NSInteger)minValue max:(NSInteger)maxValue default:(NSInteger)defaultValue
   afterSetterBlock:(LTBoundedNSIntegerSetterBlock)afterSetterBlock;

@property (nonatomic) NSInteger value;
@property (readonly, nonatomic) NSInteger minValue;
@property (readonly, nonatomic) NSInteger maxValue;
@property (readonly, nonatomic) NSInteger defaultValue;
@property (copy, nonatomic) LTBoundedNSIntegerSetterBlock afterSetterBlock;

@end

/// Represents an \c NSUInteger bounded in the range [minValue,maxValue] with a defined default
/// value.
@interface LTBoundedNSUInteger : LTBoundedType

+ (instancetype)min:(NSUInteger)minValue max:(NSUInteger)maxValue default:(NSUInteger)defaultValue;
+ (instancetype)min:(NSUInteger)minValue max:(NSUInteger)maxValue default:(NSUInteger)defaultValue
   afterSetterBlock:(LTBoundedNSUIntegerSetterBlock)afterSetterBlock;

@property (nonatomic) NSUInteger value;
@property (readonly, nonatomic) NSUInteger minValue;
@property (readonly, nonatomic) NSUInteger maxValue;
@property (readonly, nonatomic) NSUInteger defaultValue;
@property (copy, nonatomic) LTBoundedNSUIntegerSetterBlock afterSetterBlock;

@end

/// Represents a \c GLKVector3 bounded in the range [minValue,maxValue] with a defined default
/// value.
@interface LTBoundedGLKVector3 : LTBoundedType

+ (instancetype)min:(GLKVector3)minValue max:(GLKVector3)maxValue default:(GLKVector3)defaultValue;
+ (instancetype)min:(GLKVector3)minValue max:(GLKVector3)maxValue default:(GLKVector3)defaultValue
   afterSetterBlock:(LTBoundedGLKVector3SetterBlock)afterSetterBlock;

@property (nonatomic) GLKVector3 value;
@property (readonly, nonatomic) GLKVector3 minValue;
@property (readonly, nonatomic) GLKVector3 maxValue;
@property (readonly, nonatomic) GLKVector3 defaultValue;
@property (copy, nonatomic) LTBoundedGLKVector3SetterBlock afterSetterBlock;

@end

/// Represents a \c GLKVector4 bounded in the range [minValue,maxValue] with a defined default
/// value.
@interface LTBoundedGLKVector4 : LTBoundedType

+ (instancetype)min:(GLKVector4)minValue max:(GLKVector4)maxValue default:(GLKVector4)defaultValue;
+ (instancetype)min:(GLKVector4)minValue max:(GLKVector4)maxValue default:(GLKVector4)defaultValue
   afterSetterBlock:(LTBoundedGLKVector4SetterBlock)afterSetterBlock;

@property (nonatomic) GLKVector4 value;
@property (readonly, nonatomic) GLKVector4 minValue;
@property (readonly, nonatomic) GLKVector4 maxValue;
@property (readonly, nonatomic) GLKVector4 defaultValue;
@property (copy, nonatomic) LTBoundedGLKVector4SetterBlock afterSetterBlock;

@end
