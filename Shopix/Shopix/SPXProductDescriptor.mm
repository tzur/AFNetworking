// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SPXProductDescriptor.h"

#import <LTKit/NSArray+Functional.h>

#import "SPXProductAxis.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SPXProductDescriptor

- (instancetype)initWithIdentifier:(NSString *)identifier
                 baseProductValues:(NSSet *)baseProductValues benefitValues:(NSSet *)benefitValues {
  if (self = [super init]) {
    _identifier = identifier;
    _baseProductValues = baseProductValues;
    _benefitValues = benefitValues;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
