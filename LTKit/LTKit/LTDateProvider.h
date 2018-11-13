// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

NS_ASSUME_NONNULL_BEGIN

/// Protocol for providing the current date.
@protocol LTDateProvider <NSObject>

/// Returns the current date.
- (NSDate *)currentDate;

@end

/// Default implementation of LTDateProvider protocol.
@interface LTDateProvider : NSObject <LTDateProvider>

/// Returns a date provider.
+ (id<LTDateProvider>)dateProvider;

@end

NS_ASSUME_NONNULL_END
