// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTTouchCollectorFilter.h"

@interface LTTouchCollectorMultiFilter ()

@property (strong, nonatomic) NSArray *filters;

@end

@implementation LTTouchCollectorMultiFilter

- (instancetype)initWithFilters:(NSArray *)filters {
  if (self = [super init]) {
    NSMutableArray *array = [NSMutableArray array];
    for (id filter in filters) {
      if ([filter conformsToProtocol:@protocol(LTTouchCollectorFilter)]) {
        [array addObject:filter];
      }
    }
    self.filters = array;
  }
  return self;
}

- (BOOL)acceptNewPoint:(LTPainterPoint __unused *)newPoint
          withOldPoint:(LTPainterPoint __unused *)oldPoint {
  LTAssert(NO, @"[LTTouchCollectorMultiFilter acceptNewPoint:withOldPoint:] is an abstract method "
           "that should be overriden by subclasses");
}

@end

@implementation LTTouchCollectorAndFilter

- (BOOL)acceptNewPoint:(LTPainterPoint *)newPoint withOldPoint:(LTPainterPoint *)oldPoint {
  for (id<LTTouchCollectorFilter> filter in self.filters) {
    if (![filter acceptNewPoint:newPoint withOldPoint:oldPoint]) {
      return NO;
    }
  }
  return YES;
}

@end

@implementation LTTouchCollectorOrFilter

- (BOOL)acceptNewPoint:(LTPainterPoint *)newPoint withOldPoint:(LTPainterPoint *)oldPoint {
  for (id<LTTouchCollectorFilter> filter in self.filters) {
    if ([filter acceptNewPoint:newPoint withOldPoint:oldPoint]) {
      return YES;
    }
  }
  return !self.filters.count;
}

@end
