// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSArray+SelectorName.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSArray (SelectorName)

- (NSString *)lt_selectorNameFromComponents {
  __block NSMutableString *methodName = [NSMutableString string];

  [self enumerateObjectsUsingBlock:^(NSString *component, NSUInteger idx, BOOL *) {
    NSMutableString *mutableComponent = [component mutableCopy];
    [mutableComponent replaceOccurrencesOfString:@" " withString:@"" options:0
                                           range:NSMakeRange(0, mutableComponent.length)];

    if (!mutableComponent.length) {
      return;
    }

    NSString *firstLetter = [mutableComponent substringToIndex:1];
    NSString *transformedLetter = idx ? firstLetter.uppercaseString : firstLetter.lowercaseString;
    [mutableComponent replaceCharactersInRange:NSMakeRange(0, 1)
                                    withString:transformedLetter];
    [methodName appendString:mutableComponent];
  }];
  
  return [methodName copy];
}

- (SEL)lt_selectorFromComponents {
  return NSSelectorFromString([self lt_selectorNameFromComponents]);
}

@end

NS_ASSUME_NONNULL_END
