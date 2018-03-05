// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Barak Weiss.

NS_ASSUME_NONNULL_BEGIN

/// Tweak with a \c currentValue taken from the latest value of a \c RACSignal.
@interface SHKSignalBasedTweak : NSObject <FBTweak>

- (instancetype)init NS_UNAVAILABLE;

/// Initialized with \c identifier as the \c identifier of the tweak, \c name as the \c name of the
/// tweak and \c currentValueSignal as the source of values for \c currentValue.
/// \c currentValueSignal can send values of any type.
- (instancetype)initWithIdentifier:(NSString *)identifier name:(NSString *)name
                currentValueSignal:(RACSignal *)currentValueSignal NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
