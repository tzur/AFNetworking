// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidator.h"

NS_ASSUME_NONNULL_BEGIN

@class FBRHTTPClient;

/// Receipt validator that validates receipts using the Validatricks server.
///
/// The validator sends receipt validation requests to the receipt validation endpoint of the
/// Valdiatricks server using an \c FBRHTTPClient.
@interface BZRValidatricksReceiptValidator : NSObject <BZRReceiptValidator>

/// Returns a URL to the latest version of Validatricks receipt validator. The returned URL is an
/// HTTPS URL.
+ (NSURL *)defaultValidatricksServerURL;

/// Enpoint of Validatricks receipt validator. The endpoint is a path appended to the server URL
/// when validation requests are issued.
+ (NSString *)receiptValidationEndpoint;

/// Initializes the validator with the default Validatrcks server URL, using the default API key
/// and with Lightricks' default pinned certificates.
- (instancetype)init;

/// Initializes the validator with an HTTP client provided by
/// \c +[FBRHTTPClient bzr_clientWithServerURL:APIKet:pinnedCertificates:] passing it the given
/// \c serverURL, \c APIKey and \c pinnedCertificates.
///
/// @see FBRHTTPClient+Validatricks.
- (instancetype)initWithServerURL:(NSURL *)serverURL APIKey:(nullable NSString *)APIKey
         pinnedServerCertificates:(nullable NSSet<NSData *> *)pinnedCertificates;

/// Initializes the validator with the given HTTP \c client. \c client will be used to send receipt
/// validation requests to the Validatricks server.
- (instancetype)initWithHTTPClient:(FBRHTTPClient *)client NS_DESIGNATED_INITIALIZER;

/// URL of the Validatricks server configured for this validator.
@property (readonly, nonatomic) NSURL *serverURL;

@end

NS_ASSUME_NONNULL_END
