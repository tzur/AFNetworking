// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark FBRCertificateValidationMode
#pragma mark -

/// Defines certificate validation mode for HTTPS sessions.
typedef NS_ENUM(NSUInteger, FBRCertificateValidationMode) {
  /// Standard server certificate and domain validation.
  FBRCertificateValidationModeStandard,
  /// Server certificate should be validated against a set of pinned certificates.
  FBRCertificateValidationModePinnedCertificates,
  /// Server certificate public-key should be validated against a set of pinned certificates.
  FBRCertificateValidationModePinnedPublicKeys
};

#pragma mark -
#pragma mark FBRHTTPSessionSecurityPolicy
#pragma mark -

/// Defines HTTP session security policy.
@interface FBRHTTPSessionSecurityPolicy : NSObject <NSCopying>

- (instancetype)init NS_UNAVAILABLE;

/// Creates a new security policy object using standard certificate validation for HTTPS sessions.
///
/// @see FBRCertificateValidationMode
+ (instancetype)standardSecurityPolicy;

/// Creates a new security policy object that instructs the session to validate server certificate
/// against the given set of \c pinnedCertificates.
///
/// @note If \c pinnedCertificates is empty then any communication attempt will be rejected.
+ (instancetype)securityPolicyWithPinnedCertificates:(NSSet<NSData *> *)certificates;

/// Creates a new security policy object that instructs the session to validate the public-key
/// specified by the server certificate against the given set of \c pinnedCertificates.
///
/// @note If \c pinnedCertificates is empty then any communication attempt will be rejected.
+ (instancetype)securityPolicyWithPinnedPublicKeysFromCertificates:
    (NSSet<NSData *> *)certificates;

/// Certificate validation mode.
@property (readonly, nonatomic) FBRCertificateValidationMode validationMode;

/// Pinned certificates used in server certificate validation or \c nil if \c validationMode
/// is \c FBRCertificateValidationModeStandard.
@property (readonly, nonatomic, nullable) NSSet<NSData *> *pinnedCertificates;

@end

NS_ASSUME_NONNULL_END
