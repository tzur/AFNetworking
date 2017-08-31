// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSArray+SelectorName.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSArray (SelectorName)

- (NSString *)lt_selectorNameFromComponents {
  __block NSMutableString *methodName = [NSMutableString string];

  for (NSString *component in self) {
    NSMutableString *mutableComponent = [component mutableCopy];
    [mutableComponent replaceOccurrencesOfString:@" " withString:@"" options:0
                                           range:NSMakeRange(0, mutableComponent.length)];

    if (!mutableComponent.length) {
      continue;
    }

    NSString *firstLetter = [mutableComponent substringToIndex:1];
    NSString *transformedLetter = methodName.length ? firstLetter.uppercaseString :
        firstLetter.lowercaseString;
    [mutableComponent replaceCharactersInRange:NSMakeRange(0, 1)
                                    withString:transformedLetter];
    [methodName appendString:mutableComponent];
  };

  return [methodName copy];
}

- (SEL)lt_selectorFromComponents {
  return NSSelectorFromString([self lt_selectorNameFromComponents]);
}

@end

NS_ASSUME_NONNULL_END
