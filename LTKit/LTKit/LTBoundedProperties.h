// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

/// Base class for the bounded type objects.
@interface LTBoundedType : NSObject
@end

/// Represents a \c CGFloat bounded in the range [minValue,maxValue] with a defined default value.
@interface LTBoundedCGFloat : LTBoundedType

+ (instancetype)min:(CGFloat)minValue max:(CGFloat)maxValue default:(CGFloat)defaultValue;
+ (instancetype)min:(CGFloat)minValue max:(CGFloat)maxValue default:(CGFloat)defaultValue
    afterSetterBlock:(LTVoidBlock)afterSetterBlock;

@property (nonatomic) CGFloat value;
@property (readonly, nonatomic) CGFloat minValue;
@property (readonly, nonatomic) CGFloat maxValue;
@property (readonly, nonatomic) CGFloat defaultValue;

@end

/// Represents a \c double bounded in the range [minValue,maxValue] with a defined default value.
@interface LTBoundedDouble : LTBoundedType

+ (instancetype)min:(double)minValue max:(double)maxValue default:(double)defaultValue;
+ (instancetype)min:(double)minValue max:(double)maxValue default:(double)defaultValue
   afterSetterBlock:(LTVoidBlock)afterSetterBlock;

@property (nonatomic) double value;
@property (readonly, nonatomic) double minValue;
@property (readonly, nonatomic) double maxValue;
@property (readonly, nonatomic) double defaultValue;

@end

/// Represents an \c NSInteger bounded in the range [minValue,maxValue] with a defined default
/// value.
@interface LTBoundedInteger : LTBoundedType

+ (instancetype)min:(NSInteger)minValue max:(NSInteger)maxValue default:(NSInteger)defaultValue;
+ (instancetype)min:(NSInteger)minValue max:(NSInteger)maxValue default:(NSInteger)defaultValue
   afterSetterBlock:(LTVoidBlock)afterSetterBlock;

@property (nonatomic) NSInteger value;
@property (readonly, nonatomic) NSInteger minValue;
@property (readonly, nonatomic) NSInteger maxValue;
@property (readonly, nonatomic) NSInteger defaultValue;

@end

/// Represents an \c NSUInteger bounded in the range [minValue,maxValue] with a defined default
/// value.
@interface LTBoundedUInteger : LTBoundedType

+ (instancetype)min:(NSUInteger)minValue max:(NSUInteger)maxValue default:(NSUInteger)defaultValue;
+ (instancetype)min:(NSUInteger)minValue max:(NSUInteger)maxValue default:(NSUInteger)defaultValue
   afterSetterBlock:(LTVoidBlock)afterSetterBlock;

@property (nonatomic) NSUInteger value;
@property (readonly, nonatomic) NSUInteger minValue;
@property (readonly, nonatomic) NSUInteger maxValue;
@property (readonly, nonatomic) NSUInteger defaultValue;

@end

/// Represents a \c GLKVector3 bounded in the range [minValue,maxValue] with a defined default
/// value.
@interface LTBoundedGLKVector3 : LTBoundedType

+ (instancetype)min:(GLKVector3)minValue max:(GLKVector3)maxValue default:(GLKVector3)defaultValue;
+ (instancetype)min:(GLKVector3)minValue max:(GLKVector3)maxValue default:(GLKVector3)defaultValue
   afterSetterBlock:(LTVoidBlock)afterSetterBlock;

@property (nonatomic) GLKVector3 value;
@property (readonly, nonatomic) GLKVector3 minValue;
@property (readonly, nonatomic) GLKVector3 maxValue;
@property (readonly, nonatomic) GLKVector3 defaultValue;

@end

/// Represents a \c GLKVector4 bounded in the range [minValue,maxValue] with a defined default
/// value.
@interface LTBoundedGLKVector4 : LTBoundedType

+ (instancetype)min:(GLKVector4)minValue max:(GLKVector4)maxValue default:(GLKVector4)defaultValue;
+ (instancetype)min:(GLKVector4)minValue max:(GLKVector4)maxValue default:(GLKVector4)defaultValue
   afterSetterBlock:(LTVoidBlock)afterSetterBlock;

@property (nonatomic) GLKVector4 value;
@property (readonly, nonatomic) GLKVector4 minValue;
@property (readonly, nonatomic) GLKVector4 maxValue;
@property (readonly, nonatomic) GLKVector4 defaultValue;

@end
