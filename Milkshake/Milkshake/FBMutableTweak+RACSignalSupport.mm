// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import "FBMutableTweak+RACSignalSupport.h"

NS_ASSUME_NONNULL_BEGIN

@implementation FBMutableTweak (RACSignalSupport)

- (RACSignal *)shk_valueChanged {
  return [RACObserve(self, currentValue) map:^FBTweakValue(FBTweakValue _Nullable value) {
    return value ?: self.defaultValue;
  }];
}

@end

NS_ASSUME_NONNULL_END
