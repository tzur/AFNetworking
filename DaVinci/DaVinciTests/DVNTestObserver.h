// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Amit Yitzhack.

NS_ASSUME_NONNULL_BEGIN

/// Observer for testing KVO-compliance.
@interface DVNTestObserver : NSObject

/// Last observed value.
@property (strong, nonatomic) id observedValue;

@end

NS_ASSUME_NONNULL_END
