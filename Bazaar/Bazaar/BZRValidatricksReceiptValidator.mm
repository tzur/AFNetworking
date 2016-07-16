// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksReceiptValidator.h"

#import <Fiber/FBRHTTPRequest.h>
#import <Fiber/RACSignal+Fiber.h>

#import "BZRReceiptValidationParameters.h"
#import "BZRReceiptValidationParameters+Validatricks.h"
#import "BZRValidatricksReceiptValidationResponse.h"
#import "FBRHTTPClient+Validatricks.h"
#import "NSErrorCodes+Bazaar.h"
#import "RACSignal+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BZRValidatricksReceiptValidator ()

/// HTTP client used to send validation requests to Validatricks server.
@property (readonly, nonatomic) FBRHTTPClient *httpClient;

@end

@implementation BZRValidatricksReceiptValidator

/// Validatricks server host name.
static NSString * const kValidatricksServerHostName = @"api.lightricks.com";

/// Latest version of Validatricks receipt validator.
static NSString * const kLatestValidatorVersion = @"v1";

/// Default API key for Validatricks server.
static NSString * const kValidatricksAPIKey = @"AkPQ45BJFN8GdEuCA9WTm7zaauQSVAil6ZtMp1U3";

/// Receipt validation endpoint of the Validatricks server.
static NSString * const kReceiptValidationEndpoint = @"/validateReceipt";

+ (NSURL *)defaultValidatricksServerURL {
  NSString *serverURLString = [NSString stringWithFormat:@"https://%@/store/%@",
                               kValidatricksServerHostName, kLatestValidatorVersion];
  return [NSURL URLWithString:serverURLString];
}

+ (NSString *)receiptValidationEndpoint {
  return kReceiptValidationEndpoint;
}

- (instancetype)init {
  // TODO:(dlahyani) Load Lightricks certificate here and send it to the client for SSL pinning.
  return [self initWithServerURL:[[self class] defaultValidatricksServerURL]
                          APIKey:kValidatricksAPIKey pinnedServerCertificates:nil];
}

- (instancetype)initWithServerURL:(NSURL *)serverURL APIKey:(nullable NSString *)APIKey
         pinnedServerCertificates:(nullable NSSet<NSData *> *)pinnedCertificates {
  FBRHTTPClient *client = [FBRHTTPClient bzr_validatricksClientWithServerURL:serverURL APIKey:APIKey
                                                          pinnedCertificates:pinnedCertificates];
  return [self initWithHTTPClient:client];
}

- (instancetype)initWithHTTPClient:(FBRHTTPClient *)client {
  if (self = [super init]) {
    _httpClient = client;
  }
  return self;
}

- (NSURL *)serverURL {
  return self.httpClient.baseURL;
}

#pragma mark -
#pragma mark BZRReceiptValidator
#pragma mark -

- (RACSignal *)validateReceiptWithParameters:(BZRReceiptValidationParameters *)parameters {
  FBRHTTPRequestParameters *requestParameters = parameters.validatricksRequestParameters;
  return [[[self.httpClient POST:kReceiptValidationEndpoint withParameters:requestParameters]
      fbr_deserializeJSON]
      bzr_deserializeModel:[BZRValidatricksReceiptValidationResponse class]];
}

@end

NS_ASSUME_NONNULL_END
