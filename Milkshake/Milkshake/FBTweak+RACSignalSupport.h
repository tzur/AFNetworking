// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <FBTweak/FBTweak.h>

NS_ASSUME_NONNULL_BEGIN

/// Allows observing \c FBTweak change using \c RACSignal.
@interface FBTweak (RACSignalSupport)

/// Returns a signal which sends the \c currentValue of the receiver, then the new value any time it
/// changes. Does not complete or err.
- (RACSignal *)shk_valueChanged;

@end

NS_ASSUME_NONNULL_END
