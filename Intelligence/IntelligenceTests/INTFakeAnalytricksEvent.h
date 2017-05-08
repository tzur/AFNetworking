// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Boris Talesnik.

#import <LTKit/LTValueObject.h>

#import "INTAnalytricksEvent.h"

NS_ASSUME_NONNULL_BEGIN

/// Fake analytricks event that allows initialization with any \c properties dictionary.
@interface INTFakeAnalytricksEvent : LTValueObject <INTAnalytricksEvent>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithProperties:(NSDictionary<NSString *, id> *)properties
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
