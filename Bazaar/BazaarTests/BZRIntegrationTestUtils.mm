// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yonatan Oren.

#import "BZRIntegrationTestUtils.h"

#import <LTKit/NSFileManager+LTKit.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"

NS_ASSUME_NONNULL_BEGIN

void BZRStubDataMockReceiptData(NSData *dataMock, NSString *receiptString) {
  auto receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
  auto receiptDataFromFile = [receiptString dataUsingEncoding:NSUTF8StringEncoding];
  OCMStub([(id)dataMock dataWithContentsOfURL:receiptURL]).andReturn(receiptDataFromFile);
}

void BZRStubFileManagerToReturnJSONWithProducts(NSFileManager *fileManager, NSString *filepath,
    NSArray<BZRProduct *> *products) {
  auto JSONArray = [MTLJSONAdapter JSONArrayFromModels:products];
  auto JSONData = [NSJSONSerialization dataWithJSONObject:JSONArray options:0 error:NULL];
  OCMStub([(id)[fileManager lt_dataWithContentsOfFile:filepath options:0
                                                error:[OCMArg anyObjectRef]]
      ignoringNonObjectArgs]).andReturn(JSONData);
}

void BZRStubFileManagerToReturnJSONWithASingleProduct(NSFileManager *fileManager,
    NSString *filepath, NSString *productIdentifier) {
  return BZRStubFileManagerToReturnJSONWithProducts(fileManager, filepath,
      @[BZRProductWithIdentifier(productIdentifier)]);
}

void BZRStubHTTPClientToReturnReceiptValidationStatus
    (BZRReceiptValidationStatus *receiptValidationStatus) {
  auto JSONObject = [MTLJSONAdapter JSONDictionaryFromModel:receiptValidationStatus];
  auto receiptValidationStatusData =
      [NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:nil];

  auto isValidateReceiptRequest = ^BOOL(NSURLRequest *request) {
    return [request.URL.absoluteString containsString:@"validateReceipt"];
  };
  auto responseWithReceiptValidationStatus = ^OHHTTPStubsResponse *(NSURLRequest *) {
    return [OHHTTPStubsResponse responseWithData:receiptValidationStatusData statusCode:200
                                         headers:nil];
  };
  [OHHTTPStubs stubRequestsPassingTest:isValidateReceiptRequest
                      withStubResponse:responseWithReceiptValidationStatus];
}

NSData *BZRPopNextValidationStatusData
    (NSMutableArray<BZRReceiptValidationStatus *> *receiptValidationStatusArray) {
  auto receiptValidationStatus = receiptValidationStatusArray.firstObject;
  if (receiptValidationStatusArray.count > 1) {
    [receiptValidationStatusArray removeObjectAtIndex:0];
  }
  auto JSONObject = [MTLJSONAdapter JSONDictionaryFromModel:receiptValidationStatus];
  auto receiptValidationStatusData =
      [NSJSONSerialization dataWithJSONObject:JSONObject options:0 error:nil];
  return receiptValidationStatusData;
}

void BZRStubHTTPClientToReturnReceiptValidationStatusesInOrder(
    NSArray<BZRReceiptValidationStatus *> *receiptValidationStatusArray) {
  __block auto mutableStatusArray = [receiptValidationStatusArray mutableCopy];
  auto isValidateReceiptRequest = ^BOOL(NSURLRequest *request) {
    return [request.URL.absoluteString containsString:@"validateReceipt"];
  };
  auto responseWithReceiptValidationStatus = ^OHHTTPStubsResponse *(NSURLRequest *) {
    @synchronized (mutableStatusArray) {
      auto receiptValidationStatusData = BZRPopNextValidationStatusData(mutableStatusArray);
      return [OHHTTPStubsResponse responseWithData:receiptValidationStatusData statusCode:200
                                           headers:nil];
    }
  };
  [OHHTTPStubs stubRequestsPassingTest:isValidateReceiptRequest
                      withStubResponse:responseWithReceiptValidationStatus];
}

NS_ASSUME_NONNULL_END
