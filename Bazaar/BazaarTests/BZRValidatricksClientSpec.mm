// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksClient.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/NSError+Fiber.h>
#import <Fiber/NSErrorCodes+Fiber.h>
#import <FiberTestUtils/FBRHTTPTestUtils.h>

#import "BZRReceiptValidationParameters+Validatricks.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRValidatricksModels.h"
#import "NSError+Bazaar.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRValidatricksClient)

NSString * const userId = @"USER_ID";
NSString * const requestId = @"REQUEST_ID";
NSString * const creditType = @"CREDIT_TYPE";
NSArray<NSString *> * const consumableTypes = @[@"CONSUMABLE_TYPE1", @"CONSUMABLE_TYPE2"];
NSArray<NSString *> * const consumableItems = @[@"CONSUMABLE_ITEM1", @"CONSUMABLE_ITEM2"];

// Name of the Validatricks requests shared examples.
static NSString * const kValidatricksRequestSharedExamplesName = @"ValidatricksRequest";

// Key in the \c data object provided to Validatricks requests shared examples mapping to the HTTP
// method the request uses. Only "GET" or "POST" are allowed.
static NSString * const kRequestMethodKey = @"RequestMethod";

// Key in the \c data object provided to Validatricks requests shared examples mapping the request
// endpoint.
static NSString * const kRequestEndpointKey = @"RequestEndpoint";

// Key in the \c data object provided to Validatricks requests shared examples mapping to the
// expected HTTP request parameters. The value should be of type \c FBRHTTPRequestParameters.
static NSString * const kRequestParametersKey = @"RequestParameters";

// Key in the \c data object provided to Validatricks requests shared examples mapping to a JSON
// serializable object that can be delivered by the server on successful request.
static NSString * const kSuccessfulResultKey = @"SuccessfulResult";

// Key in the \c data object provided to Validatricks requests shared examples mapping to a block
// of type \c BZRValidatricksClientRequestBlock used to initiate a request on the given Validatricks
// client.
static NSString * const kSendRequestBlockKey = @"SendRequestBlock";

// Block added to the \c data dictionary passed to Validatricks requests shared examples. The block
// is used to initiate a request with the given \c client and should return the request signal.
typedef RACSignal *(^BZRValidatricksClientRequestBlock)(BZRValidatricksClient *client);

// Shared examples for \c BZRValidatricksClient requests. These examples use the \c data provided
// to stub the correct HTTP client methods, determine the expected request parameters, initate
// requests and verify the results. Most of the tests actually verify dealing with errors as these
// are the more complex scenarios to simulate.
sharedExamplesFor(kValidatricksRequestSharedExamplesName, ^(NSDictionary *data) {
  NSString * const requestMethod = data[kRequestMethodKey];
  NSString * const requestEndpoint = data[kRequestEndpointKey];
  NSDictionary * const requestParameters = data[kRequestParametersKey];
  BZRModel * const successfulResult = data[kSuccessfulResultKey];
  BZRValidatricksClientRequestBlock sendRequestBlock = data[kSendRequestBlockKey];

  NSString * const requestURL = [NSString stringWithFormat:@"https://%@", requestEndpoint];
  BZRValidatricksErrorInfo * const errorInfo =
      lt::nn([[BZRValidatricksErrorInfo alloc] initWithDictionary:@{
        @"requestId": requestId,
        @"error": @"RequestFailed",
        @"message": @"The request has failed"
      } error:nil]);

  __block FBRHTTPClient *HTTPClient;
  __block BZRValidatricksClient *client;
  __block RACSubject *requestSubject;

  beforeEach(^{
    HTTPClient = OCMClassMock([FBRHTTPClient class]);
    client = [[BZRValidatricksClient alloc] initWithHTTPClient:HTTPClient];
    requestSubject = [RACSubject subject];

    if ([requestMethod isEqualToString:@"GET"]) {
      OCMStub([HTTPClient GET:requestEndpoint withParameters:requestParameters headers:OCMOCK_ANY])
          .andReturn(requestSubject);
    } else if ([requestMethod isEqualToString:@"POST"]) {
      OCMStub([HTTPClient POST:requestEndpoint withParameters:requestParameters headers:OCMOCK_ANY])
          .andReturn(requestSubject);
    } else {
      LTAssert(NO, @"Request method must be either GET or POST, got %@", requestMethod);
    }
  });

  it(@"should err with the correct error info when the request signal errs", ^{
    auto requestError = [NSError lt_errorWithCode:1337];

    auto requestRecorder = [sendRequestBlock(client) testRecorder];
    [requestSubject sendError:requestError];

    expect(requestRecorder).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeValidatricksRequestFailed &&
          error.lt_underlyingError == requestError;
    });
  });

  it(@"should err with the correct error info if provided in the response", ^{
    auto response = FBRFakeHTTPJSONResponse(requestURL, errorInfo, 400);
    auto requestError = [NSError fbr_errorWithCode:FBRErrorCodeHTTPUnsuccessfulResponseReceived
                                       HTTPRequest:nil HTTPResponse:response underlyingError:nil];

    auto requestRecorder = [sendRequestBlock(client) testRecorder];
    [requestSubject sendError:requestError];

    expect(requestRecorder).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeValidatricksRequestFailed &&
          [error.bzr_validatricksErrorInfo isEqual:errorInfo];
    });
  });

  it(@"should err with the correct error info if no error info provided in the response", ^{
    auto response = FBRFakeHTTPResponse(requestURL, 400);
    auto requestError = [NSError fbr_errorWithCode:FBRErrorCodeHTTPUnsuccessfulResponseReceived
                                       HTTPRequest:nil HTTPResponse:response underlyingError:nil];

    auto requestRecorder = [sendRequestBlock(client) testRecorder];
    [requestSubject sendError:requestError];

    expect(requestRecorder).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeValidatricksRequestFailed &&
          [error.lt_underlyingError isEqual:requestError];
    });
  });

  it(@"should err with the correct error info if invalid error info provided in the response", ^{
    auto response = FBRFakeHTTPJSONResponse(requestURL, @{@"foo": @"bar"}, 400);
    auto requestError = [NSError fbr_errorWithCode:FBRErrorCodeHTTPUnsuccessfulResponseReceived
                                       HTTPRequest:nil HTTPResponse:response underlyingError:nil];

    auto requestRecorder = [sendRequestBlock(client) testRecorder];
    [requestSubject sendError:requestError];

    expect(requestRecorder).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeValidatricksRequestFailed &&
          [error.lt_underlyingErrors containsObject:requestError];
    });
  });

  it(@"should err with the correct error info if response content is nil", ^{
    auto response = FBRFakeHTTPResponse(requestURL, 200);
    auto progress = [[LTProgress alloc] initWithResult:response];

    auto requestRecorder = [sendRequestBlock(client) testRecorder];
    [requestSubject sendNext:progress];
    [requestSubject sendCompleted];

    expect(requestRecorder).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeValidatricksRequestFailed &&
          error.lt_underlyingError.code == FBRErrorCodeJSONDeserializationFailed;
    });
  });

  it(@"should err with the correct error info if response content is invalid", ^{
    auto response = FBRFakeHTTPJSONResponse(requestURL, @{@"foo": @"bar"}, 200);
    auto progress = [[LTProgress alloc] initWithResult:response];

    auto requestRecorder = [sendRequestBlock(client) testRecorder];
    [requestSubject sendNext:progress];
    [requestSubject sendCompleted];

    expect(requestRecorder).will.matchError(^BOOL(NSError *error) {
      return error.code == BZRErrorCodeValidatricksRequestFailed &&
          error.lt_underlyingError.code == BZRErrorCodeModelJSONDeserializationFailed;
    });
  });

  it(@"should deliver the correct result from the response", ^{
    auto response = FBRFakeHTTPJSONResponse(requestURL, successfulResult, 200);
    auto progess = [[LTProgress alloc] initWithResult:response];

    auto requestRecorder = [sendRequestBlock(client) testRecorder];
    [requestSubject sendNext:progess];
    [requestSubject sendCompleted];

    expect(requestRecorder).will.complete();
    expect(requestRecorder).to.sendValues(@[successfulResult]);
  });
});

context(@"validate receipt", ^{
  NSData * const receiptData = [@"RECEIPT_DATA" dataUsingEncoding:NSUTF8StringEncoding];
  NSLocale * const appStoreLocale = [NSLocale currentLocale];
  BZRReceiptValidationParameters * const parameters =
      [[BZRReceiptValidationParameters alloc]
       initWithCurrentApplicationBundleID:@"foobar" applicationBundleID:@"foobar"
       receiptData:receiptData deviceID:nil appStoreLocale:appStoreLocale userID:userId];
  BZRReceiptValidationStatus * const successfulResult =
      [MTLJSONAdapter modelOfClass:BZRReceiptValidationStatus.class fromJSONDictionary:@{
        @"requestId": requestId,
        @"valid": @NO,
        @"reason": @"invalidJson",
        @"currentDateTime": @1337,
      } error:nil];

  itShouldBehaveLike(kValidatricksRequestSharedExamplesName, @{
    kRequestMethodKey: @"POST",
    kRequestEndpointKey: @"validateReceipt",
    kRequestParametersKey: [parameters validatricksRequestParameters],
    kSuccessfulResultKey: successfulResult,
    kSendRequestBlockKey: ^RACSignal *(BZRValidatricksClient *client) {
      return [client validateReceipt:parameters];
    }
  });
});

context(@"get user credit", ^{
  NSDictionary * const requestParameters = @{
    @"userId": userId,
    @"creditType": creditType
  };
  BZRUserCreditStatus * const successfulResult =
      [MTLJSONAdapter modelOfClass:BZRUserCreditStatus.class fromJSONDictionary:@{
        @"requestId": requestId,
        @"creditType": creditType,
        @"credit": @1337,
        @"consumedItems": @[@{
          @"consumableItemId": consumableItems[0],
          @"consumableType": consumableTypes[0]
        }]
      } error:nil];

  itShouldBehaveLike(kValidatricksRequestSharedExamplesName, @{
    kRequestMethodKey: @"GET",
    kRequestEndpointKey: @"userCredit",
    kRequestParametersKey: requestParameters,
    kSuccessfulResultKey: successfulResult,
    kSendRequestBlockKey: ^RACSignal *(BZRValidatricksClient *client) {
      return [client getCreditOfType:creditType forUser:userId];
    }
  });
});

context(@"get consumables prices", ^{
  NSDictionary * const requestParameters = @{
    @"creditType": creditType,
    @"consumableTypes": [consumableTypes componentsJoinedByString:@","]
  };
  BZRConsumableTypesPriceInfo * const successfulResult =
      [MTLJSONAdapter modelOfClass:BZRConsumableTypesPriceInfo.class fromJSONDictionary:@{
        @"requestId": requestId,
        @"creditType": creditType,
        @"consumableTypesPrices": @{
          consumableTypes[0]: @13,
          consumableTypes[1]: @37
        }
      } error:nil];

  itShouldBehaveLike(kValidatricksRequestSharedExamplesName, @{
    kRequestMethodKey: @"GET",
    kRequestEndpointKey: @"consumableTypesPrices",
    kRequestParametersKey: requestParameters,
    kSuccessfulResultKey: successfulResult,
    kSendRequestBlockKey: ^RACSignal *(BZRValidatricksClient *client) {
      return [client getPricesInCreditType:creditType forConsumableTypes:consumableTypes];
    }
  });
});

context(@"redeem consumables", ^{
  NSDictionary * const requestParameters = @{
    @"userId": userId,
    @"creditType": creditType,
    @"consumableItems": @[@{
      @"consumableItemId": consumableItems[0],
      @"consumableType": consumableTypes[0]
    }]
  };
  BZRConsumableItemDescriptor * const consumableItem =
      lt::nn([[BZRConsumableItemDescriptor alloc] initWithDictionary:@{
        @instanceKeypath(BZRConsumableItemDescriptor, consumableItemId): consumableItems[0],
        @instanceKeypath(BZRConsumableItemDescriptor, consumableType): consumableTypes[0]
      } error:nil]);
  BZRRedeemConsumablesStatus * const successfulResult =
      [MTLJSONAdapter modelOfClass:BZRRedeemConsumablesStatus.class fromJSONDictionary:@{
        @"requestId": requestId,
        @"creditType": creditType,
        @"currentCredit": @1337,
        @"consumedItems": @[@{
          @"consumableItemId": consumableItems[0],
          @"consumableType": consumableTypes[0],
          @"redeemedCredit": @1337
        }]
      } error:nil];

  itShouldBehaveLike(kValidatricksRequestSharedExamplesName, @{
    kRequestMethodKey: @"POST",
    kRequestEndpointKey: @"redeem",
    kRequestParametersKey: requestParameters,
    kSuccessfulResultKey: successfulResult,
    kSendRequestBlockKey: ^RACSignal *(BZRValidatricksClient *client) {
      return [client redeemConsumableItems:@[consumableItem] ofCreditType:creditType userId:userId];
    }
  });
});

SpecEnd
