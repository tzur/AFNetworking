// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRReceiptValidator.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FBRHTTPClientProvider;

/// Receipt validator that validates receipts using the Validatricks server.
///
/// The validator sends receipt validation requests to the receipt validation endpoint of the
/// Validatricks server using an \c FBRHTTPClient provided by an \c FBRHTTPClientProvider.
@interface BZRValidatricksReceiptValidator : NSObject <BZRReceiptValidator>

/// Endpoint of Validatricks receipt validator. The endpoint is a path appended to the server URL
/// when validation requests are issued.
+ (NSString *)receiptValidationEndpoint;

/// Initializes the validator with the default Validatricks HTTP client provider.
- (instancetype)init;

/// Initializes the validator with the given clientProvider, which will be used to create HTTP
/// clients to send receipt validation requests to the Validatricks server. The clients provided by
/// \c clientProvider are expected to speak the Validatricks protocol.
- (instancetype)initWithHTTPClientProvider:(id<FBRHTTPClientProvider>)clientProvider
    NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
