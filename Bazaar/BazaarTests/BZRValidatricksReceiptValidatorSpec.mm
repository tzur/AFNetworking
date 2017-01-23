// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksReceiptValidator.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPClientProvider.h>
#import <Fiber/FBRHTTPRequest.h>
#import <Fiber/FBRHTTPResponse.h>
#import <Fiber/FBRHTTPTaskProgress.h>
#import <Fiber/NSErrorCodes+Fiber.h>

#import "BZREvent+AdditionalInfo.h"
#import "BZRReceiptValidationError.h"
#import "BZRReceiptValidationParameters+Validatricks.h"
#import "BZRValidatricksReceiptValidationStatus.h"
#import "NSErrorCodes+Bazaar.h"

/// Generates and returns a \c FBRHTTPTaskProgress object wrapping an \c FBRHTTPResponse with the
/// given \c responseData as its content. The returned object can be sent on an HTTPClient signals.
static FBRHTTPTaskProgress *BZRValidatricksResponseWithData(NSData * _Nullable responseData) {
  NSHTTPURLResponse *responseMetadata = OCMClassMock([NSHTTPURLResponse class]);
  FBRHTTPResponse *response = [[FBRHTTPResponse alloc] initWithMetadata:responseMetadata
                                                                content:responseData];
  return [[FBRHTTPTaskProgress alloc] initWithResponse:response];
}

/// Generates and returns a \c FBRHTTPTaskProgress object wrapping an \c FBRHTTPResponse with the
/// given \c JSONObject as its content. The returned object can be sent on an HTTPClient signals.
static FBRHTTPTaskProgress *BZRValidatricksResponseWithJSONObject
    (NSDictionary * _Nullable JSONObject) {
  NSData *responseData = JSONObject ?
      [NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:nil] : nil;
  return BZRValidatricksResponseWithData(responseData);
}

SpecBegin(BZRValidatricksReceiptValidator)

__block id client;
__block id<FBRHTTPClientProvider> clientProvider;

beforeEach(^{
  client = OCMClassMock([FBRHTTPClient class]);
  clientProvider = OCMProtocolMock(@protocol(FBRHTTPClientProvider));
});

it(@"should provide receipt validation endpoint", ^{
  expect([BZRValidatricksReceiptValidator receiptValidationEndpoint]).toNot.beNil();
});

context(@"receipt validation", ^{
  __block BZRReceiptValidationParameters *parameters;
  __block FBRHTTPRequestParameters *requestParameters;
  __block NSString *URLString;
  __block BZRValidatricksReceiptValidator *validator;
  __block NSDictionary *JSONResponse;

  beforeEach(^{
    NSData *receiptData = [@"foobar" dataUsingEncoding:NSUTF8StringEncoding];
    parameters = [[BZRReceiptValidationParameters alloc] initWithReceiptData:receiptData
                                                         applicationBundleId:@"foobar"
                                                                    deviceId:nil
                                                              appStoreLocale:nil];
    requestParameters = [parameters validatricksRequestParameters];
    URLString = [BZRValidatricksReceiptValidator receiptValidationEndpoint];

    validator = [[BZRValidatricksReceiptValidator alloc] initWithHTTPClientProvider:clientProvider];

    JSONResponse = @{
      @"valid": @NO,
      @"reason": @"invalidJson",
      @"currentDateTime": @1337,
      @"requestId": @"id"
    };
  });

  it(@"should send a post request to the server with the correct url string and parameters", ^{
    OCMStub([clientProvider HTTPClient]).andReturn(client);
    OCMExpect([client POST:URLString withParameters:requestParameters]);

    [validator validateReceiptWithParameters:parameters];

    OCMVerifyAll(client);
  });

  it(@"should request another client if POST failed", ^{
    OCMExpect([clientProvider HTTPClient]).andReturn(client);
    OCMExpect([clientProvider HTTPClient]).andReturn(client);
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([client POST:URLString withParameters:requestParameters])
        .andReturn([RACSignal error:error]);

    expect([validator validateReceiptWithParameters:parameters]).will.finish();
    expect([validator validateReceiptWithParameters:parameters]).will.finish();

    OCMVerifyAll((id)clientProvider);
  });

  context(@"signal specifications", ^{
    __block RACSubject *subject;
    __block LLSignalTestRecorder *recorder;

    beforeEach(^{
      subject = [RACSubject subject];
      OCMStub([client POST:URLString withParameters:requestParameters]).andReturn(subject);
      OCMStub([clientProvider HTTPClient]).andReturn(client);
      recorder = [[validator validateReceiptWithParameters:parameters] testRecorder];
    });

    it(@"should send the deserialized validation response and then complete", ^{
      BZRValidatricksReceiptValidationStatus *status =
          [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptValidationStatus class]
                    fromJSONDictionary:JSONResponse error:nil];
      [subject sendNext:BZRValidatricksResponseWithJSONObject(JSONResponse)];
      [subject sendCompleted];

      expect(recorder).to.sendValues(@[status]);
      expect(recorder).to.complete();
    });

    it(@"should err if the underlying signal errs", ^{
      NSError *error = [NSError lt_errorWithCode:1337];
      [subject sendError:error];

      expect(recorder).to.sendError(error);
    });

    it(@"should err if the server response contains no data", ^{
      [subject sendNext:BZRValidatricksResponseWithJSONObject(nil)];

      expect(recorder).to.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == FBRErrorCodeJSONDeserializationFailed;
      });
    });

    it(@"should err if the server response contains non-json data", ^{
      NSData *responseData = [NSKeyedArchiver archivedDataWithRootObject:@"foo"];
      [subject sendNext:BZRValidatricksResponseWithData(responseData)];

      expect(recorder).to.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == FBRErrorCodeJSONDeserializationFailed;
      });
    });

    it(@"should err if the server response contains invalid json data", ^{
      [subject sendNext:BZRValidatricksResponseWithJSONObject(@{@"foo": @"bar"})];

      expect(recorder).to.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodeModelJSONDeserializationFailed;
      });
    });

    it(@"should err if the json object is missing some required properies", ^{
      NSMutableDictionary *JSONObject = [JSONResponse mutableCopy];
      JSONObject[@"currentDateTime"] = nil;

      [subject sendNext:BZRValidatricksResponseWithJSONObject(JSONObject)];
      expect(recorder).to.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodeModelJSONDeserializationFailed;
      });
    });

    it(@"should err if the json object yields a model in invalid state", ^{
      NSMutableDictionary *JSONObject = [JSONResponse mutableCopy];
      JSONObject[@"valid"] = @YES;

      [subject sendNext:BZRValidatricksResponseWithJSONObject(JSONObject)];
      expect(recorder).to.matchError(^BOOL(NSError *error) {
        return error.lt_isLTDomain && error.code == BZRErrorCodeModelJSONDeserializationFailed;
      });
    });
  });

  context(@"events signal", ^{
    __block LLSignalTestRecorder *recorder;

    beforeEach(^{
      recorder = [validator.eventsSignal testRecorder];
    });

    it(@"should send BZREvent with the request id from receipt validation status", ^{
      RACSignal *responseSignal =
          [RACSignal return:BZRValidatricksResponseWithJSONObject(JSONResponse)];
      OCMStub([client POST:URLString withParameters:requestParameters]).andReturn(responseSignal);
      OCMStub([clientProvider HTTPClient]).andReturn(client);

      expect([validator validateReceiptWithParameters:parameters]).will.complete();
      expect(recorder).to.sendValues(@[[BZREvent receiptValidationStatusReceivedEvent:@"id"]]);
    });
  });
});

SpecEnd
