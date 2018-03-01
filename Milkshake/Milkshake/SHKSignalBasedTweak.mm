// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "SHKSignalBasedTweak.h"

NS_ASSUME_NONNULL_BEGIN

@implementation SHKSignalBasedTweak

@synthesize identifier = _identifier;
@synthesize name = _name;
@synthesize currentValue = _currentValue;

- (instancetype)initWithIdentifier:(NSString *)identifier name:(NSString *)name
                currentValueSignal:(RACSignal *)currentValueSignal {
  if (self = [super init]) {
    _identifier = identifier;
    _name = name;
    RAC(self, currentValue) = currentValueSignal;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END
