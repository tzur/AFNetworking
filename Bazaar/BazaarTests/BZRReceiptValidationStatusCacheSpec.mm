// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRReceiptValidationStatusCache.h"

#import "BZRKeychainStorage+TypeSafety.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRReceiptValidationStatusCache)

static NSString * const kValidationStatusKey = @"validationStatus";
static NSString * const kValidationDateKey = @"validationDate";
static NSString * const kCachedReceiptValidationStatusStorageKey = @"receiptValidationStatus";

__block BZRKeychainStorage *keychainStorage;
__block BZRReceiptValidationStatus *receiptValidationStatus;
__block RACSubject *underlyingEventsSubject;
__block BZRReceiptValidationStatusCache *validationStatusCache;

beforeEach(^{
  keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
  underlyingEventsSubject = [RACSubject subject];
  validationStatusCache =
      [[BZRReceiptValidationStatusCache alloc] initWithKeychainStorage:keychainStorage];
});

context(@"cache access", ^{
  it(@"should read receipt validation status and cached date from cache", ^{
    BZRReceiptValidationStatus *validationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
    auto cachedDate = [NSDate date];
    NSDictionary *receiptDictionary = @{
      kValidationStatusKey: validationStatus,
      kValidationDateKey: cachedDate
    };

    OCMExpect([keychainStorage valueOfClass:[NSDictionary class] forKey:OCMOCK_ANY
                                      error:[OCMArg anyObjectRef]]).andReturn(receiptDictionary);
    validationStatusCache = [[BZRReceiptValidationStatusCache alloc]
                              initWithKeychainStorage:keychainStorage];

    auto validationStatusCacheEntry = [validationStatusCache loadCacheEntry:nil];

    expect(validationStatusCacheEntry.receiptValidationStatus).to.equal(validationStatus);
    expect(validationStatusCacheEntry.cachingDateTime).to.equal(cachedDate);
    OCMVerifyAll((id)keychainStorage);
  });

  it(@"should store receipt validation to cache", ^{
    auto cachedDate = [NSDate date];
    auto checkDictionaryValuesBlock = ^BOOL(NSDictionary *receiptDictionary) {
      return receiptDictionary[kValidationStatusKey] == receiptValidationStatus &&
          receiptDictionary[kValidationDateKey] == cachedDate;
    };
    OCMExpect([keychainStorage setValue:[OCMArg checkWithBlock:checkDictionaryValuesBlock]
                                 forKey:kCachedReceiptValidationStatusStorageKey
                                  error:[OCMArg anyObjectRef]]).andReturn(YES);
    validationStatusCache = [[BZRReceiptValidationStatusCache alloc]
                             initWithKeychainStorage:keychainStorage];

    auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                       initWithReceiptValidationStatus:receiptValidationStatus
                       cachingDateTime:cachedDate];
    NSError *error;
    auto success = [validationStatusCache storeCacheEntry:cacheEntry error:&error];
    expect(success).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll((id)keychainStorage);
  });

  it(@"should store nil to cache", ^{
    OCMExpect([keychainStorage setValue:nil
                                 forKey:kCachedReceiptValidationStatusStorageKey
                                  error:[OCMArg anyObjectRef]]).andReturn(YES);
    validationStatusCache = [[BZRReceiptValidationStatusCache alloc]
                             initWithKeychainStorage:keychainStorage];

    NSError *error;
    BOOL success = [validationStatusCache storeCacheEntry:nil error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll((id)keychainStorage);
  });

  it(@"should return error if failed to store to the storage", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorage setValue:OCMOCK_ANY forKey:OCMOCK_ANY error:[OCMArg setTo:error]])
        .andReturn(NO);
    validationStatusCache = [[BZRReceiptValidationStatusCache alloc]
                             initWithKeychainStorage:keychainStorage];
    auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                       initWithReceiptValidationStatus:receiptValidationStatus
                       cachingDateTime:[NSDate date]];
    NSError *returnedError;
    BOOL success = [validationStatusCache storeCacheEntry:cacheEntry error:&returnedError];

    expect(returnedError.code).to.equal(BZRErrorCodeStoringDataToStorageFailed);
    expect(returnedError.lt_underlyingError.code).to.equal(1337);
    expect(success).to.beFalsy();
  });

  it(@"should return error if failed to read from storage", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY error:[OCMArg setTo:error]]);
    validationStatusCache = [[BZRReceiptValidationStatusCache alloc]
                             initWithKeychainStorage:keychainStorage];
    NSError *returnedError;
    auto value = [validationStatusCache loadCacheEntry:&returnedError];

    expect(returnedError.code).to.equal(BZRErrorCodeLoadingDataFromStorageFailed);
    expect(returnedError.lt_underlyingError.code).to.equal(1337);
    expect(value).to.beNil();
  });
});

SpecEnd
