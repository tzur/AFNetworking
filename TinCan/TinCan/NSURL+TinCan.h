// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Michael Kimyagarov.

NS_ASSUME_NONNULL_BEGIN

/// Category augmenting \c NSURL with \c TinCan's URL creation functionality.
@interface NSURL (TinCan)

/// Returns a URL of a directory designated for a message with the given \c appGroupID, \c scheme
/// and \c identifier. Returns \c nil if this application doesn't have a valid application group set
/// in the application's entitlements.
+ (nullable NSURL *)tin_messageDirectoryURLWithAppGroup:(NSString *)appGroupID
                                                 scheme:(NSString *)scheme
                                             identifier:(NSUUID *)identifier;

/// Returns a URL of a directory for the given \c appGroupID. This directory is shared among all the
/// application with the same \c appGroupID. Returns \c nil if this application doesn't have a valid
/// application group set in the application's entitlements.
+ (nullable NSURL *)tin_appGroupDirectoryURL:(NSString *)appGroupID;

@end

NS_ASSUME_NONNULL_END
