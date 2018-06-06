// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRValidatricksClient.h"

NS_ASSUME_NONNULL_BEGIN

/// A Validatricks client that handles error by retrying different clients and uses exponential
/// backoff.
/// The robust algorithm can be described in the following pseudo code:
/// @code
/// For delayed-try in (0..delayedRetries):
///     For immediate-try in (0..immediateRetries):
///         call next host
///         if success: return response
///     wait for (initialBackoffDelay * power(2, delayed-try)) seconds
/// return fail
/// @endcode
@interface BZRValidatricksRobustClient : NSObject <BZRValidatricksClient>

/// Initializes with a list of default host names which will be used to create
/// client. \c delayedRetries is set to \c 2, \c initialBackoffDelay is set to \c 0.25, and
/// \c immediateRetries is set to the number of hosts minus 1.
- (instancetype)init;

/// Initializes with a list of host names which will be used to create Validatricks \c clients, and
/// with other parameters as specified in the designated initializer.
- (instancetype)initWithHostNames:(NSArray<NSString *> *)hostNames
                   delayedRetries:(NSUInteger)delayedRetries
              initialBackoffDelay:(NSTimeInterval)initialBackoffDelay
                 immediateRetries:(NSUInteger)immediateRetries;

/// Initializes with a list of \c clients, \c delayedRetries is the maximal amount of delayed
/// retries (\c 0 for none), \c initialBackoffDelay is used as the base time for the
/// exponential backoff algorithm, and \c immediateRetries is the maximal number of
/// retries between delays (\c 0 for none).
- (instancetype)initWithClients:(NSArray<id<BZRValidatricksClient>> *)clients
                 delayedRetries:(NSUInteger)delayedRetries
            initialBackoffDelay:(NSTimeInterval)initialBackoffDelay
               immediateRetries:(NSUInteger)immediateRetries NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
