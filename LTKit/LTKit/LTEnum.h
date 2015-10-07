// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Represents an enum object, allowing to initialize with a given enum field name. Other methods
/// and properties are generated by the LTEnumImplement() macro.
///
/// @see LTEnumMacros.
@protocol LTEnum <NSCoding, NSCopying, NSObject>

/// Initializes a new enum with the given field name.
- (instancetype)initWithName:(NSString *)name;

/// Initializes a new enum with a default value.
+ (instancetype)enum;

/// Initializes a new enum with the given field name.
+ (instancetype)enumWithName:(NSString *)name;

/// Returns a new enum object with a lowest value greater than the receiving object, or \c nil if
/// the receiving object is the greatest enum value.
///
/// @note The order in which enum items were defined does not affect the objects provided by this
/// method.
- (nullable instancetype)enumWithNextValue;

/// Name of the currently value set.
@property (readonly, nonatomic) NSString *name;

@end

NS_ASSUME_NONNULL_END
