// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Dekel Avrahami.

NS_ASSUME_NONNULL_BEGIN

/// Category for bundles of test targets.
@interface NSBundle (Test)

/// Returns the bundle of the currently running test target.
+ (NSBundle *)lt_testBundle;

@end

NS_ASSUME_NONNULL_END
