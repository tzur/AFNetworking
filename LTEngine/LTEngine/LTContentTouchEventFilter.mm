// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTContentTouchEventFilter.h"

#import "LTContentTouchEventPredicate.h"

NS_ASSUME_NONNULL_BEGIN

@interface LTContentTouchEventFilter ()

/// The last event that was pushed into the filter and accepted by \c predicate, or \c nil if no
/// event has been accepted yet.
@property (readwrite, nonatomic, nullable) id<LTContentTouchEvent> lastValidEvent;

@end

@implementation LTContentTouchEventFilter

- (instancetype)initWithPredicate:(id<LTContentTouchEventPredicate>)predicate {

  if (self = [super init]) {
    _predicate = predicate;
  }
  return self;
}

- (LTContentTouchEvents *)pushEventsAndFilter:(LTContentTouchEvents *)events {
  if (!events.count) {
    return @[];
  }

  LTMutableContentTouchEvents *filteredEvents = [NSMutableArray array];

  for (id<LTContentTouchEvent> event in events) {
    if (self.lastValidEvent &&
        ![self.predicate isValidEvent:event givenEvent:self.lastValidEvent]) {
      continue;
    }

    [filteredEvents addObject:event];
    self.lastValidEvent = event;
  }

  return [filteredEvents copy];
}

@end

NS_ASSUME_NONNULL_END
