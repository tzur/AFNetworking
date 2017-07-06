// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

/// Object that provides access to the user information of other applications that uses the same
/// shared keychain.
@interface BZRSharedUserInfoReader : NSObject

/// Returns \c YES if the user has an active subscription to the application with the specified
/// \c bundleIdentifier, and that application stored the subscription information on the local
/// shared keychain.
- (BOOL)isSubscriberOfAppWithBundleIdentifier:(NSString *)bundleIdentifier;

@end
