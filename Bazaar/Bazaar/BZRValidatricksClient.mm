// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksClient.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/NSError+Fiber.h>
#import <Fiber/NSErrorCodes+Fiber.h>
#import <Fiber/RACSignal+Fiber.h>
#import <LTKit/LTTimer.h>

#import "BZREvent.h"
#import "BZRReceiptEnvironment.h"
#import "BZRReceiptValidationParameters+Validatricks.h"
#import "BZRReceiptValidationStatus.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"
#import "NSValueTransformer+Bazaar.h"
#import "RACSignal+Bazaar.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const kBZREventValidatricksResponseTypeKey = @"BZREventValidatricksResponseType";

NSString * const kBZREventValidatricksResponseKey = @"BZREventValidatricksResponse";

NSString * const kBZREventValidatricksRequestDurationKey = @"BZREventValidatricksRequestDuration";

NSString * const kBZRErrorValidatricksRequestDuration = @"BZRErrorValidatricksRequestDuration";

@interface BZRValidatricksClient ()

/// HTTP client used for sending requests to Validatricks server.
@property (readonly, nonatomic) FBRHTTPClient *HTTPClient;

/// The other end of \c eventsSignal.
@property (readonly, nonatomic) RACSubject<BZREvent *> *eventsSubject;

@end

@implementation BZRValidatricksClient

#pragma mark -
#pragma mark Validatricks Server Endpoints
#pragma mark -

/// Validatricks "validate receipt" endpoint path.
static NSString * const kValidatricksValidateReceiptEndpoint = @"validateReceipt";

/// Validatricks "get user credit" endpoint path.
static NSString * const kValidatricksGetUserCreditEndpoint = @"userCredit";

/// Validatricks "get consumable types prices" endpoint path.
static NSString * const kValidatricksGetConsumableTypesPricesEndpoint = @"consumableTypesPrices";

/// Validatricks "redeem consumable items" endpoint path.
static NSString * const kValidatricksRedeemConsumablesEndpoint = @"redeem";

#pragma mark -
#pragma mark Validatricks Server Parameters Names
#pragma mark -

/// User-ID parameter name for Validatricks endpoints.
static NSString * const kValidatricksUserIdKey = @"userId";

/// Credit-type parameter name for Validatricks endpoints.
static NSString * const kValidatricksCreditTypeKey = @"creditType";

/// Consumable-types parameter name for Validatricks endpoints.
static NSString * const kValidatricksConsumableTypesKey = @"consumableTypes";

/// Consumable items parameter names for Validatricks endpoints.
static NSString * const kValidatricksConsumableItemsKey = @"consumableItems";

/// Environment parameter names for Validatricks endpoints.
static NSString * const kValidatricksEnvironmentKey = @"environment";

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (instancetype)initWithHTTPClient:(FBRHTTPClient *)HTTPClient {
  if (self = [super init]) {
    _HTTPClient = HTTPClient;
    _eventsSubject = [RACSubject subject];
  }
  return self;
}

- (RACSignal<BZREvent *> *)eventsSignal {
  return [self.eventsSubject takeUntil:[self rac_willDeallocSignal]];
}

#pragma mark -
#pragma mark Public API
#pragma mark -

- (RACSignal<BZRReceiptValidationStatus *> *)
    validateReceipt:(BZRReceiptValidationParameters *)validationParameters {
  FBRHTTPRequestParameters *parameters = validationParameters.validatricksRequestParameters;

  auto timer = [[LTTimer alloc] init];
  [timer start];
  return [[[[[self.HTTPClient
      POST:kValidatricksValidateReceiptEndpoint withParameters:parameters headers:nil]
      fbr_deserializeJSON]
      bzr_deserializeModel:BZRReceiptValidationStatus.class]
      doNext:^(BZRReceiptValidationStatus *receiptValidationStatus) {
        [self sendValidatricksResponseEvent:receiptValidationStatus
                            requestDuration:[timer stop]];
      }]
      catch:^(NSError *error) {
        auto timedError =
            [BZRValidatricksClient validatricksTimedClientErrorForUnderlyingError:error
                                                                  requestDuration:[timer stop]];
        return [RACSignal error:timedError];
      }];
}

- (RACSignal<BZRUserCreditStatus *> *)getCreditOfType:(NSString *)creditType
                                              forUser:(NSString *)userId
                                          environment:(BZRReceiptEnvironment *)environment {
  NSString *environmentParameter =
      lt::nn([[NSValueTransformer bzr_validatricksReceiptEnvironmentValueTransformer]
              reverseTransformedValue:environment]);
  FBRHTTPRequestParameters *parameters = @{
    kValidatricksCreditTypeKey: creditType,
    kValidatricksUserIdKey: userId,
    kValidatricksEnvironmentKey: environmentParameter
  };

  auto timer = [[LTTimer alloc] init];
  [timer start];
  return [[[[[self.HTTPClient
      GET:kValidatricksGetUserCreditEndpoint withParameters:parameters headers:nil]
      fbr_deserializeJSON]
      bzr_deserializeModel:BZRUserCreditStatus.class]
      doNext:^(BZRUserCreditStatus *userCreditStatus) {
        [self sendValidatricksResponseEvent:userCreditStatus
                            requestDuration:[timer stop]];
      }]
      catch:^(NSError *error) {
        auto timedError =
            [BZRValidatricksClient validatricksTimedClientErrorForUnderlyingError:error
                                                                  requestDuration:[timer stop]];
        return [RACSignal error:timedError];
      }];
}

- (RACSignal<BZRConsumableTypesPriceInfo *> *)getPricesInCreditType:(NSString *)creditType
    forConsumableTypes:(NSArray<NSString *> *)consumableTypes {
  FBRHTTPRequestParameters *parameters = @{
    kValidatricksCreditTypeKey: creditType,
    kValidatricksConsumableTypesKey: [consumableTypes componentsJoinedByString:@","]
  };

  auto timer = [[LTTimer alloc] init];
  [timer start];
  return [[[[[self.HTTPClient
      GET:kValidatricksGetConsumableTypesPricesEndpoint withParameters:parameters headers:nil]
      fbr_deserializeJSON]
      bzr_deserializeModel:BZRConsumableTypesPriceInfo.class]
      doNext:^(BZRConsumableTypesPriceInfo *consumableTypesPriceInfo) {
        [self sendValidatricksResponseEvent:consumableTypesPriceInfo
                            requestDuration:[timer stop]];
      }]
      catch:^(NSError *error) {
        auto timedError =
            [BZRValidatricksClient validatricksTimedClientErrorForUnderlyingError:error
                                                                  requestDuration:[timer stop]];
        return [RACSignal error:timedError];
      }];
}

- (RACSignal<BZRRedeemConsumablesStatus *> *)
    redeemConsumableItems:(NSArray<BZRConsumableItemDescriptor *> *)items
    ofCreditType:(NSString *)creditType userId:(NSString *)userId
    environment:(BZRReceiptEnvironment *)environment {
  NSString *environmentParameter =
      lt::nn([[NSValueTransformer bzr_validatricksReceiptEnvironmentValueTransformer]
              reverseTransformedValue:environment]);
  FBRHTTPRequestParameters *parameters = @{
    kValidatricksConsumableItemsKey: [MTLJSONAdapter JSONArrayFromModels:items],
    kValidatricksCreditTypeKey: creditType,
    kValidatricksUserIdKey: userId,
    kValidatricksEnvironmentKey: environmentParameter
  };

  auto timer = [[LTTimer alloc] init];
  [timer start];
  return [[[[[self.HTTPClient
      POST:kValidatricksRedeemConsumablesEndpoint withParameters:parameters headers:nil]
      fbr_deserializeJSON]
      bzr_deserializeModel:BZRRedeemConsumablesStatus.class]
      doNext:^(BZRRedeemConsumablesStatus *redeemConsumablesStatus) {
        [self sendValidatricksResponseEvent:redeemConsumablesStatus
                            requestDuration:[timer stop]];
      }]
      catch:^(NSError *error) {
        auto timedError =
            [BZRValidatricksClient validatricksTimedClientErrorForUnderlyingError:error
                                                                  requestDuration:[timer stop]];
        return [RACSignal error:timedError];
      }];
}

#pragma mark -
#pragma mark Sending Events
#pragma mark -

- (void)sendValidatricksResponseEvent:(BZRModel *)validatricksResponse
                      requestDuration:(NSTimeInterval)requestDuration {
  auto responseTypeString = [self responseTypeStringForValidatricksResponse:validatricksResponse];
  const auto eventInfo = @{
    kBZREventValidatricksResponseTypeKey: responseTypeString,
    kBZREventValidatricksResponseKey: validatricksResponse,
    kBZREventValidatricksRequestDurationKey: @(requestDuration)
  };
  auto responseEvent =
      [[BZREvent alloc] initWithType:$(BZREventTypeInformational) eventInfo:eventInfo];
  [self.eventsSubject sendNext:responseEvent];
}

/// This function is used in order to make sure that the response type will always show the same
/// string, regardless of the class name.
- (NSString *)responseTypeStringForValidatricksResponse:(BZRModel *)validatricksResponse {
  auto validatricksResponseClassName = NSStringFromClass(validatricksResponse.class);
  static auto classNameToResponseType = @{
    NSStringFromClass(BZRReceiptValidationStatus.class): @"ReceiptValidationStatus",
    NSStringFromClass(BZRUserCreditStatus.class): @"UserCreditStatus",
    NSStringFromClass(BZRConsumableTypesPriceInfo.class): @"ConsumableTypesPriceInfo",
    NSStringFromClass(BZRRedeemConsumablesStatus.class): @"RedeemConsumablesStatus"
  };
  return classNameToResponseType[validatricksResponseClassName] ?: validatricksResponseClassName;
}

#pragma mark -
#pragma mark Errors Decoration
#pragma mark -

// Returns an \c NSError with code \c BZRErrorCodeValidatricksRequestFailed and other properties
// based on the given \c error.
//
// If the specified \c error indicates that we got a response from the server with unsuccessful HTTP
// status code (eg. 4XX or 5XX) and the response has content, this method tries to parse the
// content as a JSONified \c BZRValidatricksErrorInfo object. If deserialization of the
// \c BZRValidatricksErrorInfo succeeds it will be provided via the \c bzr_validatricksErrorInfo
// property of the returned error and the original error via the \c lt_underlyingError property.
// Otherwise an error containing both the original error and the deserialization error as
// underlying error is returned.
//
// For any other error, i.e. \c error contains no response from the server or the response has no
// content, the method simply wraps the error with a \c BZRErrorCodeValidatricksRequestFailed error.
+ (NSError *)validatricksTimedClientErrorForUnderlyingError:(NSError *)error
                                            requestDuration:(NSTimeInterval)requestDuration {
  auto validatricksError = [self validatricksClientErrorForUnderlyingError:error];
  auto userInfo = [validatricksError.userInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
    kBZRErrorValidatricksRequestDuration: @(requestDuration)
  }];
  return [NSError lt_errorWithCode:validatricksError.code userInfo:userInfo];
};

+ (NSError *)validatricksClientErrorForUnderlyingError:(NSError *)underlyingError {
  if (underlyingError.code != FBRErrorCodeHTTPUnsuccessfulResponseReceived ||
      !underlyingError.fbr_HTTPResponse.content) {
    return [NSError lt_errorWithCode:BZRErrorCodeValidatricksRequestFailed
                     underlyingError:underlyingError];
  }

  NSError * _Nullable JSONDeserializationError;
  NSDictionary * _Nullable JSONObject =
      [underlyingError.fbr_HTTPResponse deserializeJSONContentWithError:&JSONDeserializationError];
  if (JSONDeserializationError) {
    return [NSError lt_errorWithCode:BZRErrorCodeValidatricksRequestFailed
                    underlyingErrors:@[underlyingError, JSONDeserializationError]];
  }

  if (![self containsValidatricksErrorMetadata:JSONObject]) {
    return [NSError lt_errorWithCode:BZRErrorCodeValidatricksRequestFailed
                    underlyingError:underlyingError];
  }

  NSError * _Nullable validatricksErrorInfoDeserializationError;
  BZRValidatricksErrorInfo * _Nullable deserializedValidatricksError =
      [MTLJSONAdapter modelOfClass:BZRValidatricksErrorInfo.class fromJSONDictionary:JSONObject
       error:&validatricksErrorInfoDeserializationError];
  if (validatricksErrorInfoDeserializationError) {
    return [NSError lt_errorWithCode:BZRErrorCodeValidatricksRequestFailed
                    underlyingErrors:@[underlyingError, validatricksErrorInfoDeserializationError]];
  }

  auto requestURL = lt::nn(underlyingError.fbr_HTTPResponse).metadata.URL;
  return [NSError bzr_validatricksRequestErrorWithURL:requestURL
                                validatricksErrorInfo:deserializedValidatricksError
                                      underlyingError:underlyingError];
}

+ (BOOL)containsValidatricksErrorMetadata:(NSDictionary *)JSONObject {
  return JSONObject[@"error"] != nil;
}

@end

NS_ASSUME_NONNULL_END
