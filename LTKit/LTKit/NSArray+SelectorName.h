// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (Joining)

/// Returns a string formatted per the conventions for naming a method by joining each element of
/// the receiver. To create the returned value, spaces in each element are removed. Then, the first
/// letter of the first components is lowercased, and the first letter of each consecutive element
/// is uppercased. Then the elements are concatenated together in their original order.
///
/// Examples:
///
/// @[@"foo", @"Bar"] -> @"fooBar".
///
/// @[@"Foo Baz", @"Bar"] -> @"fooBazBar".
///
/// @[@"Foo", @"bar Baz", @"Moo"] -> @"fooBarBazMoo".
- (NSString *)lt_selectorNameFromComponents;

/// Returns a selector with a name composed by joining each element of the receiver.
///
/// @see \c -lt_selectorNameFromComponents to see how the selector name is formatted from its
/// components.
- (SEL)lt_selectorFromComponents;

@end

NS_ASSUME_NONNULL_END
