// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventOrPredicate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LTContentTouchEventOrPredicate

@synthesize predicates = _predicates;

#pragma mark -
#pragma mark LTContentTouchEventMultiPredicate
#pragma mark -

- (instancetype)initWithPredicates:(NSArray<id<LTContentTouchEventPredicate>> *)predicates {
  if (self = [super init]) {
    [self validatePredicates:predicates];
    _predicates = [predicates copy];
  }
  return self;
}

- (void)validatePredicates:(NSArray<id<LTContentTouchEventPredicate>> *)predicates {
  LTParameterAssert([predicates isKindOfClass:NSArray.class],
                    @"Invalid predicates collection (%@): array expected", predicates);
  for (id predicate in predicates) {
    LTParameterAssert([predicate conformsToProtocol:@protocol(LTContentTouchEventPredicate)],
                      @"Invalid predicate (%@): must conform to LTContentTouchEventPredicate "
                      "protocol", predicate);
  }
}

+ (instancetype)predicateWithPredicates:(NSArray<id<LTContentTouchEventPredicate>> *)predicates {
  return [[[self class] alloc] initWithPredicates:predicates];
}

#pragma mark -
#pragma mark LTContentTouchEventPredicate
#pragma mark -

- (BOOL)isValidEvent:(id<LTContentTouchEvent>)event givenEvent:(id<LTContentTouchEvent>)baseEvent {
  for (id<LTContentTouchEventPredicate> predicate in self.predicates) {
    if ([predicate isValidEvent:event givenEvent:baseEvent]) {
      return YES;
    }
  }
  return NO;
}

@end

NS_ASSUME_NONNULL_END
