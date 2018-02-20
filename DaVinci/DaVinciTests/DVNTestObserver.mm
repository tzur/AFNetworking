// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

#import "DVNTestObserver.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DVNTestObserver

- (void)observeValueForKeyPath:(nullable NSString __unused *)keyPath
                      ofObject:(nullable __unused id)object
                        change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(nullable void __unused *)context {
  self.observedValue = change[NSKeyValueChangeNewKey];
}

@end

NS_ASSUME_NONNULL_END
