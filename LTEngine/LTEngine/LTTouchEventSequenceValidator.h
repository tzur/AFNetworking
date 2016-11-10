// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Rouven Strauss.

#import "LTTouchEventDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/// Object verifying that the values used as parameters of the \c LTTouchEventDelegate methods
/// are valid and forwarding the calls to another \c id<LTTouchEventDelegate> object potentially
/// provided upon initialization. An exception is raised if any parameter value is invalid.
@interface LTTouchEventSequenceValidator : NSObject <LTTouchEventDelegate>

/// Initializes without a delegate.
- (instancetype)init;

/// Initializes with the given \c delegate. The given \c delegate is held strongly if
/// \c heldStrongly is \c YES.
- (instancetype)initWithDelegate:(nullable id<LTTouchEventDelegate>)delegate
                    heldStrongly:(BOOL)heldStrongly
    NS_DESIGNATED_INITIALIZER;

/// Delegate to which validated touch event sequences are forwarded.
@property (readonly, nonatomic, nullable) id<LTTouchEventDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
