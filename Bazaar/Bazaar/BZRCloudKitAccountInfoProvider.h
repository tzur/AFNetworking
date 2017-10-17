// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

@class BZRCloudKitAccountInfo, CKContainer, RACSignal<ValueType>;

/// Provides basic iCloud account information. The provider listens to CloudKit notifications and
/// updates the account info whenever a \c CKAccountChangedNotification notification arrives.
///
/// @note While CloudKit promises to notify on any iCloud account changes it fail to do so and the
/// notifications only arrives when user signs-out of iCloud but not when the user signs-in. Thus
/// the provider updates the account information whenever the application goes to foreground.
@interface BZRCloudKitAccountInfoProvider : NSObject

/// Initializes with the default container and the default notification center.
- (instancetype)init;

/// Initializes with a container with the given \c identifier.
- (instancetype)initWithContainerIdentifier:(NSString *)identifier;

/// Initializes with the given \c container, used to fetch the account status and the user record.
/// \c notificationCenter is used to listen to \c CKAccountChangedNotification and
/// \c UIApplicationWillEnterForeground.
- (instancetype)initWithContainer:(CKContainer *)container
               notificationCenter:(NSNotificationCenter *)notificationCenter
    NS_DESIGNATED_INITIALIZER;

/// Signal that continuously fetches the current user account information.
///
/// Upon subscription the signal fetches the account status and optionally the user record
/// identifier and delivers them wrapped in a \c BZRCloudKitAccountInfo object. The user record
/// identifier will be fetched only if the account status is \c BZRCloudKitAccountStatusAvailable,
/// otherwise partial account information will be provided with \c recordIdentifier set to \c nil.
/// The signal will repeat this process whenever a \c CKAccountChangedNotification or
/// \c UIApplicationWillEnterForeground notification is received and will send new account
/// information if one of its properties has changed. The signal errs in case an unrecoverable error
/// occurs while fetching the account status or the user record. The signal never completes. The
/// signal delivers on an arbitrary non-main thread.
///
/// @note Fetching the user record may be lengthy operation and it requires internet connection.
/// Thus when the account status is \c BZRCloudKitAccountStatusAvailable the account info is first
/// reported with the user record identifier set to \c nil and a complete account information is
/// delivered once internet connection becomes available and fetching the user record completes.
@property (readonly, nonatomic) RACSignal<BZRCloudKitAccountInfo *> *accountInfo;

@end

NS_ASSUME_NONNULL_END
