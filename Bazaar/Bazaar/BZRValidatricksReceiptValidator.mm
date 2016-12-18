// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksReceiptValidator.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPClientProvider.h>
#import <Fiber/RACSignal+Fiber.h>

#import "BZRReceiptValidationParameters+Validatricks.h"
#import "BZRValidatricksReceiptValidationStatus.h"
#import "NSErrorCodes+Bazaar.h"
#import "RACSignal+Bazaar.h"

#import "BZRValidatricksHTTPClientProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRValidatricksReceiptValidator ()

/// Provider used to provide HTTP clients.
@property (readonly, nonatomic) id<FBRHTTPClientProvider> clientProvider;

@end

@implementation BZRValidatricksReceiptValidator

/// Receipt validation endpoint of the Validatricks server.
static NSString * const kReceiptValidationEndpoint = @"validateReceipt";

+ (NSString *)receiptValidationEndpoint {
  return kReceiptValidationEndpoint;
}

- (instancetype)init {
  return [self initWithHTTPClientProvider:[[BZRValidatricksHTTPClientProvider alloc] init]];
}

- (instancetype)initWithHTTPClientProvider:(id<FBRHTTPClientProvider>)clientProvider {
  if (self = [super init]) {
    _clientProvider = clientProvider;
  }
  return self;
}

#pragma mark -
#pragma mark BZRReceiptValidator
#pragma mark -

- (RACSignal *)validateReceiptWithParameters:(BZRReceiptValidationParameters *)parameters {
  FBRHTTPRequestParameters *requestParameters = parameters.validatricksRequestParameters;
  return [[[[self.clientProvider HTTPClient]
      POST:kReceiptValidationEndpoint withParameters:requestParameters]
      fbr_deserializeJSON]
      bzr_deserializeModel:[BZRValidatricksReceiptValidationStatus class]];
}

@end

NS_ASSUME_NONNULL_END
