// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Barak Weiss.

#import <FBTweak/FBTweak.h>

NS_ASSUME_NONNULL_BEGIN

/// Allows observing \c FBMutableTweak change using \c RACSignal.
@interface FBMutableTweak (RACSignalSupport)

/// Returns a signal which sends the \c currentValue of the receiver, then the new value any time it
/// changes. If \c currentValue is \c nil, \c defaultValue is sent. Does not complete or err.
- (RACSignal *)shk_valueChanged;

@end

NS_ASSUME_NONNULL_END
