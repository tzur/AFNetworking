// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRValidatricksRobustClient.h"

#import "BZRReceiptValidationParameters+Validatricks.h"
#import "BZRReceiptValidationStatus.h"

SpecBegin(BZRValidatricksRobustClient)

static NSString * const kUserId = @"USER_ID";
static NSString * const kRequestId = @"REQUEST_ID";
static NSString * const kCreditType = @"CREDIT_TYPE";
static NSArray<NSString *> * const kConsumableItems = @[@"CONSUMABLE_ITEM1", @"CONSUMABLE_ITEM2"];
static NSArray<NSString *> * const kConsumableTypes = @[@"CONSUMABLE_TYPE1", @"CONSUMABLE_TYPE2"];

/// Name of the Robust Client shared examples.
static NSString * const kRobustClientSharedExamplesName = @"RobustClient";

/// Key in the \c data object provided to the Robust Client shared examples mapping to
/// a block that should be called with the robust client.
static NSString *const kRobustClientCallKey = @"RobustClientCallBlock";

/// Key in the \c data object provided to the Robust Client shared examples mapping to
/// a block that should be run with the internal clients, when \c kRobustClientCall is called.
static NSString *const kInnerClientCallKey = @"ClientCallBlock";

/// Key in the \c data object provided to Validatricks requests shared examples mapping to a JSON
/// serializable object that can be delivered by the server on successful request.
static NSString * const kSuccessfulResultKey = @"SuccessfulResult";

/// Block added to the \c data dictionary passed to the Robust Client shared examples The block
/// is used to initiate a request with the given \c client and should return the request signal.
typedef RACSignal *(^BZRValidatricksRobustClientCallBlock)(BZRValidatricksRobustClient *client);

/// Block added to the \c data dictionary passed to the Robust Client shared examples The block
/// is used to stub the result off calling to the internals client.
typedef RACSignal *(^BZRValidatricksClientCallBlock)(id<BZRValidatricksClient> client);

/// Shared examples for \c BZRValidatricksRobustClient requests. These examples use the \c data
/// provided to stub the correct client methods, determine the expected request parameters, initiate
/// requests and verify the results and the order of the called internal clients.
sharedExamplesFor(kRobustClientSharedExamplesName, ^(NSDictionary *data) {
  __block NSError *error;
  __block id<BZRValidatricksClient> succeedingClient;
  __block id<BZRValidatricksClient> failingClient;
  __block id<BZRValidatricksClient> neverCalledClient;

  BZRModel * const successfulResult = data[kSuccessfulResultKey];
  BZRValidatricksClientCallBlock innerClientCall = data[kInnerClientCallKey];
  BZRValidatricksRobustClientCallBlock robustClientCall = data[kRobustClientCallKey];

  beforeEach(^{
    error = [NSError lt_errorWithCode:1337];

    succeedingClient = OCMProtocolMock(@protocol(BZRValidatricksClient));
    OCMExpect(innerClientCall(succeedingClient)).andReturn([RACSignal return:successfulResult]);

    failingClient = OCMProtocolMock(@protocol(BZRValidatricksClient));
    OCMExpect(innerClientCall(failingClient)).andReturn([RACSignal error:error]);

    neverCalledClient = OCMProtocolMock(@protocol(BZRValidatricksClient));
    OCMReject(innerClientCall(neverCalledClient));
  });

  context(@"no retries at all", ^{
    it(@"should call just the first client and only once if the first client call succeeds", ^{
      auto clients = @[succeedingClient, neverCalledClient];
      auto robustClient =
          [[BZRValidatricksRobustClient alloc] initWithClients:clients delayedRetries:0
                                           initialBackoffDelay:0 immediateRetries:0];

      auto recorder = [robustClientCall(robustClient) testRecorder];

      expect(recorder).to.complete();
      expect(recorder).to.sendValues(@[successfulResult]);

      OCMVerifyAll((id)succeedingClient);
    });

    it(@"should call just the first client and fail if the client fails", ^{
      auto clients = @[failingClient, neverCalledClient];
      auto robustClient =
          [[BZRValidatricksRobustClient alloc] initWithClients:clients delayedRetries:0
                                           initialBackoffDelay:0 immediateRetries:0];
      auto recorder = [robustClientCall(robustClient) testRecorder];

      expect(recorder).will.sendError(error);

      OCMVerifyAll((id)failingClient);
    });
  });

  context(@"immediate retries only", ^{
   it(@"should call the first two clients only if the first fails and the second succeeds", ^{
     auto clients = @[failingClient, succeedingClient, neverCalledClient];
     auto robustClient =
         [[BZRValidatricksRobustClient alloc] initWithClients:clients delayedRetries:0
                                          initialBackoffDelay:0 immediateRetries:2];
     auto recorder = [robustClientCall(robustClient) testRecorder];

     expect(recorder).will.complete();
     expect(recorder).will.sendValues(@[successfulResult]);

     OCMVerifyAll((id)succeedingClient);
     OCMVerifyAll((id)failingClient);
   });

    it(@"should call all the clients and fail if they all fail", ^{
      id<BZRValidatricksClient> anotherFailingClient =
          OCMProtocolMock(@protocol(BZRValidatricksClient));
      OCMExpect(innerClientCall(anotherFailingClient)).andReturn([RACSignal error:error]);

      auto clients = @[failingClient, anotherFailingClient];
      auto robustClient =
          [[BZRValidatricksRobustClient alloc] initWithClients:clients delayedRetries:0
                                           initialBackoffDelay:0 immediateRetries:1];
      auto recorder = [robustClientCall(robustClient) testRecorder];

      expect(recorder).will.sendError(error);

      OCMVerifyAll((id)failingClient);
      OCMVerifyAll((id)anotherFailingClient);
    });
  });

  context(@"delayed retries only", ^{
    it(@"should retry calling another client after a delay if the first client fails", ^{
      auto clients = @[failingClient, succeedingClient, neverCalledClient];
      auto robustClient =
          [[BZRValidatricksRobustClient alloc] initWithClients:clients delayedRetries:1
                                           initialBackoffDelay:0.00001 immediateRetries:0];
      auto recorder = [robustClientCall(robustClient) testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[successfulResult]);

      OCMVerifyAll((id)failingClient);
      OCMVerifyAll((id)succeedingClient);
    });

    it(@"should call all the clients and fail if they all fail", ^{
      id<BZRValidatricksClient> anotherFailingClient =
          OCMProtocolMock(@protocol(BZRValidatricksClient));
      OCMExpect(innerClientCall(anotherFailingClient)).andReturn([RACSignal error:error]);

      auto clients = @[failingClient, anotherFailingClient, neverCalledClient];
      auto robustClient =
          [[BZRValidatricksRobustClient alloc] initWithClients:clients delayedRetries:1
                                           initialBackoffDelay:0.00001 immediateRetries:0];
      auto recorder = [robustClientCall(robustClient) testRecorder];

      expect(recorder).will.sendError(error);

      OCMVerifyAll((id)failingClient);
      OCMVerifyAll((id)anotherFailingClient);
    });
  });

  context(@"delayed retries and immediate retries", ^{
    it(@"should retry two clients, wait and then try them again", ^{
      id<BZRValidatricksClient> failingTwiceClient =
          OCMProtocolMock(@protocol(BZRValidatricksClient));
      OCMExpect(innerClientCall(failingTwiceClient)).andReturn([RACSignal error:error]);
      OCMExpect(innerClientCall(failingTwiceClient)).andReturn([RACSignal error:error]);

      id<BZRValidatricksClient> failingThenSucceedingClient =
          OCMProtocolMock(@protocol(BZRValidatricksClient));
      OCMExpect(innerClientCall(failingThenSucceedingClient)).andReturn([RACSignal error:error]);
      OCMExpect(innerClientCall(failingThenSucceedingClient))
          .andReturn([RACSignal return:successfulResult]);

      auto clients = @[failingTwiceClient, failingThenSucceedingClient];
      auto robustClient =
          [[BZRValidatricksRobustClient alloc] initWithClients:clients delayedRetries:1
                                           initialBackoffDelay:0.00001 immediateRetries:1];
      auto recorder = [robustClientCall(robustClient) testRecorder];

      expect(recorder).will.complete();
      expect(recorder).will.sendValues(@[successfulResult]);

      OCMVerifyAll((id)failingTwiceClient);
      OCMVerifyAll((id)failingThenSucceedingClient);
    });
  });
});

context(@"validate receipt", ^{
  auto const receiptData = [@"RECEIPT_DATA" dataUsingEncoding:NSUTF8StringEncoding];
  auto const appStoreLocale = [NSLocale currentLocale];
  auto const parameters =
      [[BZRReceiptValidationParameters alloc]
       initWithCurrentApplicationBundleID:@"foobar" applicationBundleID:@"foobar"
       receiptData:receiptData deviceID:nil appStoreLocale:appStoreLocale userID:kUserId];
  BZRReceiptValidationStatus * const successfulResult =
      [MTLJSONAdapter modelOfClass:BZRReceiptValidationStatus.class fromJSONDictionary:@{
        @"requestId": kRequestId,
        @"valid": @NO,
        @"reason": @"invalidJson",
        @"currentDateTime": @1337,
      } error:nil];
  auto robustClientCall = ^RACSignal *(BZRValidatricksRobustClient *robustClient) {
    return [robustClient validateReceipt:parameters];
  };
  auto clientCall = ^RACSignal *(id<BZRValidatricksClient> client) {
    return [client validateReceipt:parameters];
  };

  itShouldBehaveLike(kRobustClientSharedExamplesName, @{
    kRobustClientCallKey: robustClientCall,
    kInnerClientCallKey: clientCall,
    kSuccessfulResultKey: successfulResult
  });
});

context(@"get user credit", ^{
  BZRUserCreditStatus * const successfulResult =
      [MTLJSONAdapter modelOfClass:BZRUserCreditStatus.class fromJSONDictionary:@{
        @"requestId": kRequestId,
        @"creditType": kCreditType,
        @"credit": @1337,
        @"consumedItems": @[@{
          @"consumableItemId": kConsumableItems[0],
          @"consumableType": kConsumableTypes[0]
        }]
      } error:nil];
  auto robustClientCall = ^RACSignal *(BZRValidatricksRobustClient *robustClient) {
    return [robustClient getCreditOfType:kCreditType forUser:kUserId];
  };
  auto clientCall = ^RACSignal *(id<BZRValidatricksClient> client) {
    return [client getCreditOfType:kCreditType forUser:kUserId];
  };

  itShouldBehaveLike(kRobustClientSharedExamplesName, @{
    kRobustClientCallKey: robustClientCall,
    kInnerClientCallKey: clientCall,
    kSuccessfulResultKey: successfulResult
  });
});

context(@"get consumables prices", ^{
  BZRConsumableTypesPriceInfo * const successfulResult =
      [MTLJSONAdapter modelOfClass:BZRConsumableTypesPriceInfo.class fromJSONDictionary:@{
        @"requestId": kRequestId,
        @"creditType": kCreditType,
        @"consumableTypesPrices": @{
          kConsumableTypes[0]: @13,
          kConsumableTypes[1]: @37
        }
      } error:nil];
  auto robustClientCall = ^RACSignal *(BZRValidatricksRobustClient *robustClient) {
    return [robustClient getPricesInCreditType:kCreditType forConsumableTypes:kConsumableTypes];
  };
  auto clientCall = ^RACSignal *(id<BZRValidatricksClient> client) {
    return [client getPricesInCreditType:kCreditType forConsumableTypes:kConsumableTypes];
  };

  itShouldBehaveLike(kRobustClientSharedExamplesName, @{
    kRobustClientCallKey: robustClientCall,
    kInnerClientCallKey: clientCall,
    kSuccessfulResultKey: successfulResult
  });
});

context(@"redeem consumables", ^{
  auto const consumableItem =
      lt::nn([[BZRConsumableItemDescriptor alloc] initWithDictionary:@{
        @instanceKeypath(BZRConsumableItemDescriptor, consumableItemId): kConsumableItems[0],
        @instanceKeypath(BZRConsumableItemDescriptor, consumableType): kConsumableTypes[0]
      } error:nil]);
  BZRRedeemConsumablesStatus * const successfulResult =
      [MTLJSONAdapter modelOfClass:BZRRedeemConsumablesStatus.class fromJSONDictionary:@{
        @"requestId": kRequestId,
        @"creditType": kCreditType,
        @"currentCredit": @1337,
        @"consumedItems": @[@{
          @"consumableItemId": kConsumableItems[0],
          @"consumableType": kConsumableTypes[0],
          @"redeemedCredit": @1337
        }]
      } error:nil];
  auto robustClientCall = ^RACSignal *(BZRValidatricksRobustClient *robustClient) {
    return [robustClient redeemConsumableItems:@[consumableItem] ofCreditType:kCreditType
                                        userId:kUserId];
  };
  auto innerClientCall = ^RACSignal *(id<BZRValidatricksClient> client) {
    return [client redeemConsumableItems:@[consumableItem] ofCreditType:kCreditType
                                  userId:kUserId];
  };

  itShouldBehaveLike(kRobustClientSharedExamplesName, @{
    kRobustClientCallKey: robustClientCall,
    kInnerClientCallKey: innerClientCall,
    kSuccessfulResultKey: successfulResult
  });
});

SpecEnd
