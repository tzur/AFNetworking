// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import <LTKit/LTValueObject.h>

NS_ASSUME_NONNULL_BEGIN

@class BZRCloudKitAccountStatus;

/// Basic iCloud account information.
@interface BZRCloudKitAccountInfo : LTValueObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the account information with the given \c accountStatus, \c containerIdentifier and
/// optionally with a \c recordIdentifier.
- (instancetype)initWithAccountStatus:(BZRCloudKitAccountStatus *)accountStatus
                  containerIdentifier:(NSString *)containerIdentifier
                 userRecordIdentifier:(nullable NSString *)userRecordIdentifier
    NS_DESIGNATED_INITIALIZER;

/// Status of the account associated with the CloudKit container.
@property (readonly, nonatomic) BZRCloudKitAccountStatus *accountStatus;

/// Identifier of the container that the user record is associated with.
@property (readonly, nonatomic) NSString *containerIdentifier;

/// Identifier of the user record associated with the current user or \c nil if the record
/// identifier is not available (eg. user record info was not fetched yet or can not be fetched
/// since the user is not signed in to iCloud).
@property (readonly, nonatomic, nullable) NSString *userRecordIdentifier;

@end

NS_ASSUME_NONNULL_END
