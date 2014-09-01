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
/// Block called after setting the \c LTBoundedLTVector3's value.
typedef void (^LTBoundedLTVector3SetterBlock)(LTVector3 value, LTVector3 oldValue);
/// Block called after setting the \c LTBoundedLTVector4's value.
typedef void (^LTBoundedLTVector4SetterBlock)(LTVector4 value, LTVector4 oldValue);

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

/// Represents a \c LTVector3 bounded in the range [minValue,maxValue] with a defined default
/// value.
@interface LTBoundedLTVector3 : LTBoundedType

+ (instancetype)min:(LTVector3)minValue max:(LTVector3)maxValue default:(LTVector3)defaultValue;
+ (instancetype)min:(LTVector3)minValue max:(LTVector3)maxValue default:(LTVector3)defaultValue
   afterSetterBlock:(LTBoundedLTVector3SetterBlock)afterSetterBlock;

@property (nonatomic) LTVector3 value;
@property (readonly, nonatomic) LTVector3 minValue;
@property (readonly, nonatomic) LTVector3 maxValue;
@property (readonly, nonatomic) LTVector3 defaultValue;
@property (copy, nonatomic) LTBoundedLTVector3SetterBlock afterSetterBlock;

@end

/// Represents a \c LTVector4 bounded in the range [minValue,maxValue] with a defined default
/// value.
@interface LTBoundedLTVector4 : LTBoundedType

+ (instancetype)min:(LTVector4)minValue max:(LTVector4)maxValue default:(LTVector4)defaultValue;
+ (instancetype)min:(LTVector4)minValue max:(LTVector4)maxValue default:(LTVector4)defaultValue
   afterSetterBlock:(LTBoundedLTVector4SetterBlock)afterSetterBlock;

@property (nonatomic) LTVector4 value;
@property (readonly, nonatomic) LTVector4 minValue;
@property (readonly, nonatomic) LTVector4 maxValue;
@property (readonly, nonatomic) LTVector4 defaultValue;
@property (copy, nonatomic) LTBoundedLTVector4SetterBlock afterSetterBlock;

@end
