// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Daniel Lahyani.

#import "BZRValidatricksReceiptValidator.h"

#import <Fiber/FBRHTTPClient.h>
#import <Fiber/FBRHTTPRequest.h>
#import <Fiber/FBRHTTPResponse.h>
#import <Fiber/FBRHTTPTaskProgress.h>
#import <Fiber/NSErrorCodes+Fiber.h>

#import "BZRReceiptValidationError.h"
#import "BZRReceiptValidationParameters+Validatricks.h"
#import "BZRValidatricksReceiptValidationResponse.h"
#import "FBRHTTPClient+Validatricks.h"
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

beforeEach(^{
  client = OCMClassMock([FBRHTTPClient class]);
});

it(@"should provide default server URL", ^{
  expect([BZRValidatricksReceiptValidator defaultValidatricksServerURL]).toNot.beNil();
});


it(@"should provide receipt validation endpoint", ^{
  expect([BZRValidatricksReceiptValidator receiptValidationEndpoint]).toNot.beNil();
});

it(@"should provide server URL and receipt validation endpoint that can be composed together", ^{
  NSURL *serverURL = [BZRValidatricksReceiptValidator defaultValidatricksServerURL];
  NSString *validatorEndpoint = [BZRValidatricksReceiptValidator receiptValidationEndpoint];
  NSURL *compositeURL = [NSURL URLWithString:validatorEndpoint relativeToURL:serverURL];

  expect(compositeURL.absoluteString).to.beginWith(serverURL.absoluteString);
  expect([compositeURL.pathComponents lastObject]).to.equal(validatorEndpoint);
});

context(@"initialization", ^{
  it(@"should initalize an HTTP client with the server URL", ^{
    NSURL *serverURL = [BZRValidatricksReceiptValidator defaultValidatricksServerURL];
    BZRValidatricksReceiptValidator __unused *validator =
        [[BZRValidatricksReceiptValidator alloc] init];

    expect(validator).toNot.beNil();
    expect(validator.serverURL).to.equal(serverURL);
  });

  it(@"should initalize an HTTP client with the specified parameters", ^{
    NSURL *serverURL = [NSURL URLWithString:@"https://foo.bar"];
    NSString *APIKey = @"foo";
    NSSet<NSData *> *certificates =
        [NSSet setWithObject:[@"bar" dataUsingEncoding:NSUTF8StringEncoding]];
    OCMExpect([client bzr_validatricksClientWithServerURL:serverURL APIKey:APIKey
                                       pinnedCertificates:certificates]).andReturn(client);

    BZRValidatricksReceiptValidator __unused *validator =
        [[BZRValidatricksReceiptValidator alloc] initWithServerURL:serverURL APIKey:APIKey
                                          pinnedServerCertificates:certificates];
    OCMVerifyAll(client);
  });
});

context(@"receipt validation", ^{
  __block BZRReceiptValidationParameters *parameters;
  __block FBRHTTPRequestParameters *requestParameters;
  __block NSString *URLString;
  __block BZRValidatricksReceiptValidator *validator;

  beforeEach(^{
    NSData *receiptData = [@"foobar" dataUsingEncoding:NSUTF8StringEncoding];
    parameters = [[BZRReceiptValidationParameters alloc] initWithReceiptData:receiptData
                                                         applicationBundleId:@"foobar"
                                                                    deviceId:nil];
    requestParameters = [parameters validatricksRequestParameters];
    URLString = [BZRValidatricksReceiptValidator receiptValidationEndpoint];

    validator = [[BZRValidatricksReceiptValidator alloc] initWithHTTPClient:client];
  });

  it(@"should send a post request to the server with the correct url string and parameters", ^{
    OCMExpect([client POST:URLString withParameters:requestParameters]);
    [validator validateReceiptWithParameters:parameters];

    OCMVerifyAll(client);
  });

  context(@"signal specifications", ^{
    __block RACSubject *subject;
    __block LLSignalTestRecorder *recorder;
    __block NSDictionary *JSONResponse;

    beforeEach(^{
      subject = [RACSubject subject];
      OCMStub([client POST:URLString withParameters:requestParameters]).andReturn(subject);
      recorder = [[validator validateReceiptWithParameters:parameters] testRecorder];

      JSONResponse = @{
        @"valid": @NO,
        @"reason": @"invalidJson",
        @"currentDateTime": @1337
      };
    });

    it(@"should send the deserialized validation response and then complete", ^{
      BZRValidatricksReceiptValidationResponse *response =
          [MTLJSONAdapter modelOfClass:[BZRValidatricksReceiptValidationResponse class]
                    fromJSONDictionary:JSONResponse error:nil];
      [subject sendNext:BZRValidatricksResponseWithJSONObject(JSONResponse)];
      [subject sendCompleted];

      expect(recorder).to.sendValues(@[response]);
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
});

SpecEnd
