// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Accessors for properties declared using \c LTPropertyMacros.
@interface NSObject (PropertyAccessors)

/// Returns the minimum allowed value of the property with the given \c keyPath, located at
/// \c min<keyPath>. The object must respond to \c min<keyPath>.
- (nullable id)lt_minValueForKeyPath:(NSString *)keyPath;

/// Returns the maximal allowed value of the property with the given \c keyPath, located at
/// \c max<keyPath>. The object must respond to \c max<keyPath>.
- (nullable id)lt_maxValueForKeyPath:(NSString *)keyPath;

/// Returns the default value of the property with the given \c keyPath, located at
/// \c default<keyPath>. The object must respond to \c default<keyPath>.
- (nullable id)lt_defaultValueForKeyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
