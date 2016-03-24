// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Barak Yoresh.

#import <DropboxSDK/DropboxSDK.h>

NS_ASSUME_NONNULL_BEGIN

@class RACDelegateProxy;

@interface DBSession (RACSignalSupport)

/// Creates a signal for authorization failures by the receiver.
///
/// When this method is invoked, the \c rac_delegateProxy will become the receiver's delegate. Any
/// previous delegate will become the <tt>-[RACDelegateProxy rac_proxiedDelegate]</tt>, so that it
/// receives any messages that the proxy doesn't know how to handle. Setting the receiver's
/// \c delegate afterward is considered undefined behavior.
///
/// Returns a signal which will send the corresponding user id if an authorization failure ocurred.
/// The signal will complete when the receiver is deallocated.
- (RACSignal *)ptn_authorizationFailureSignal;

/// A delegate proxy which will be set as the receiver's delegate when any of the
/// methods in this category are used.
@property (readonly, nonatomic) RACDelegateProxy *ptn_delegateProxy;

@end

NS_ASSUME_NONNULL_END
