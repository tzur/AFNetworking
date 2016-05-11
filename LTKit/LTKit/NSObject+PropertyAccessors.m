// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSObject+PropertyAccessors.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark NSString (Formatting)
#pragma mark -

@interface NSString (Formatting)

/// Returns the string with a capitalized first letter.
- (instancetype)lt_capitalizedFirstLetterOfString;

@end

@implementation NSString (Formatting)

- (instancetype)lt_capitalizedFirstLetterOfString {
  if (!self.length) {
    return self;
  }

  return [self stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                       withString:[[self substringToIndex:1] uppercaseString]];
}

@end

#pragma mark -
#pragma mark NSObject (PropertyAccessors)
#pragma mark -

@implementation NSObject (PropertyAccessors)

- (nullable id)lt_minValueForKeyPath:(NSString *)keyPath {
  NSString *capitalizedKeyPath = [keyPath lt_capitalizedFirstLetterOfString];
  NSString *defaultKeyPath = [NSString stringWithFormat:@"min%@", capitalizedKeyPath];
  return [self valueForKeyPath:defaultKeyPath];
}

- (nullable id)lt_maxValueForKeyPath:(NSString *)keyPath {
  NSString *capitalizedKeyPath = [keyPath lt_capitalizedFirstLetterOfString];
  NSString *defaultKeyPath = [NSString stringWithFormat:@"max%@", capitalizedKeyPath];
  return [self valueForKeyPath:defaultKeyPath];
}

- (nullable id)lt_defaultValueForKeyPath:(NSString *)keyPath {
  NSString *capitalizedKeyPath = [keyPath lt_capitalizedFirstLetterOfString];
  NSString *defaultKeyPath = [NSString stringWithFormat:@"default%@", capitalizedKeyPath];
  return [self valueForKeyPath:defaultKeyPath];
}

@end

NS_ASSUME_NONNULL_END
