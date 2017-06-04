// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "LABAssignmentsSource.h"

NS_ASSUME_NONNULL_BEGIN

@implementation LABVariant

- (instancetype)initWithName:(NSString *)name
                 assignments:(NSDictionary<NSString *, id> *)assignments
                  experiment:(NSString *)experiment {
  if (self = [super init]) {
    _name = name;
    _assignments = assignments;
    _experiment = experiment;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
