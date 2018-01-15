// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRReceiptValidationStatusCache.h"

#import "BZRKeychainStorageRoute.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"
#import "BZRTimeProvider.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRReceiptValidationStatusCache)

static NSString * const kValidationStatusKey = @"validationStatus";
static NSString * const kValidationDateKey = @"validationDate";
static NSString * const kCachedReceiptValidationStatusStorageKey = @"receiptValidationStatus";

__block BZRKeychainStorageRoute *keychainStorageRoute;
__block BZRReceiptValidationStatus *receiptValidationStatus;
__block RACSubject *underlyingEventsSubject;
__block BZRReceiptValidationStatusCache *validationStatusCache;
__block NSString *applicationBundleID;

beforeEach(^{
  keychainStorageRoute = OCMClassMock([BZRKeychainStorageRoute class]);
  receiptValidationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
  underlyingEventsSubject = [RACSubject subject];
  validationStatusCache =
      [[BZRReceiptValidationStatusCache alloc] initWithKeychainStorage:keychainStorageRoute];

  applicationBundleID = @"foo";
});

context(@"cache access", ^{
  it(@"should read receipt validation status and cached date from cache", ^{
    BZRReceiptValidationStatus *validationStatus = OCMClassMock([BZRReceiptValidationStatus class]);
    auto cachedDate = [NSDate date];
    NSDictionary *receiptDictionary = @{
      kValidationStatusKey: validationStatus,
      kValidationDateKey: cachedDate
    };

    OCMExpect([keychainStorageRoute valueForKey:OCMOCK_ANY serviceName:applicationBundleID
        error:[OCMArg anyObjectRef]]).andReturn(receiptDictionary);
    validationStatusCache = [[BZRReceiptValidationStatusCache alloc]
                              initWithKeychainStorage:keychainStorageRoute];

    auto validationStatusCacheEntry =
        [validationStatusCache loadCacheEntryOfApplicationWithBundleID:applicationBundleID
                                                                 error:nil];

    expect(validationStatusCacheEntry.receiptValidationStatus).to.equal(validationStatus);
    expect(validationStatusCacheEntry.cachingDateTime).to.equal(cachedDate);
    OCMVerifyAll((id)keychainStorageRoute);
  });

  it(@"should store receipt validation to cache", ^{
    auto cachedDate = [NSDate date];
    auto checkDictionaryValuesBlock = ^BOOL(NSDictionary *receiptDictionary) {
      return receiptDictionary[kValidationStatusKey] == receiptValidationStatus &&
          receiptDictionary[kValidationDateKey] == cachedDate;
    };
    OCMExpect([keychainStorageRoute setValue:[OCMArg checkWithBlock:checkDictionaryValuesBlock]
                                      forKey:kCachedReceiptValidationStatusStorageKey
                                 serviceName:applicationBundleID
                                       error:[OCMArg anyObjectRef]]).andReturn(YES);
    validationStatusCache = [[BZRReceiptValidationStatusCache alloc]
                             initWithKeychainStorage:keychainStorageRoute];

    auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                       initWithReceiptValidationStatus:receiptValidationStatus
                       cachingDateTime:cachedDate];
    NSError *error;
    auto success = [validationStatusCache storeCacheEntry:cacheEntry
                                      applicationBundleID:applicationBundleID error:&error];
    expect(success).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll((id)keychainStorageRoute);
  });

  it(@"should store nil to cache", ^{
    OCMExpect([keychainStorageRoute setValue:nil
                                      forKey:kCachedReceiptValidationStatusStorageKey
                                 serviceName:applicationBundleID
                                       error:[OCMArg anyObjectRef]]).andReturn(YES);
    validationStatusCache = [[BZRReceiptValidationStatusCache alloc]
                             initWithKeychainStorage:keychainStorageRoute];

    NSError *error;
    BOOL success = [validationStatusCache storeCacheEntry:nil
                                      applicationBundleID:applicationBundleID error:&error];

    expect(success).to.beTruthy();
    expect(error).to.beNil();
    OCMVerifyAll((id)keychainStorageRoute);
  });

  it(@"should return error if failed to store to the storage", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorageRoute setValue:OCMOCK_ANY forKey:OCMOCK_ANY
                               serviceName:applicationBundleID error:[OCMArg setTo:error]])
        .andReturn(NO);
    validationStatusCache = [[BZRReceiptValidationStatusCache alloc]
                             initWithKeychainStorage:keychainStorageRoute];
    auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                       initWithReceiptValidationStatus:receiptValidationStatus
                       cachingDateTime:[NSDate date]];
    NSError *returnedError;
    BOOL success = [validationStatusCache storeCacheEntry:cacheEntry
                                      applicationBundleID:applicationBundleID error:&returnedError];

    expect(returnedError.code).to.equal(BZRErrorCodeStoringToKeychainStorageFailed);
    expect(returnedError.lt_underlyingError.code).to.equal(1337);
    expect(success).to.beFalsy();
  });

  it(@"should return error if failed to read from storage", ^{
    NSError *storageError = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorageRoute valueForKey:OCMOCK_ANY serviceName:applicationBundleID
                                        error:[OCMArg setTo:storageError]]);
    validationStatusCache = [[BZRReceiptValidationStatusCache alloc]
                             initWithKeychainStorage:keychainStorageRoute];
    NSError *error;
    auto value = [validationStatusCache loadCacheEntryOfApplicationWithBundleID:applicationBundleID
                                                                          error:&error];

    expect(error).to.equal(storageError);
    expect(value).to.beNil();
  });
});

context(@"loading multiple cache entries from cache", ^{
  __block BZRReceiptValidationStatusCacheEntry *cacheEntry;

  beforeEach(^{
    validationStatusCache = OCMPartialMock(validationStatusCache);
    receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(YES);
    cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                  initWithReceiptValidationStatus:receiptValidationStatus
                  cachingDateTime:[NSDate date]];
  });

  afterEach(^{
    validationStatusCache = nil;
  });

  it(@"should return dictionary with the receipt validation status of the requested bundle IDs", ^{
    auto secondReceiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
    auto secondReceiptValidationStatusCacheEntry =
        [[BZRReceiptValidationStatusCacheEntry alloc]
         initWithReceiptValidationStatus:secondReceiptValidationStatus
         cachingDateTime:[NSDate dateWithTimeIntervalSince1970:1337]];

    OCMStub([validationStatusCache loadCacheEntryOfApplicationWithBundleID:@"foo"
        error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);
    OCMStub([validationStatusCache loadCacheEntryOfApplicationWithBundleID:@"bar"
        error:[OCMArg anyObjectRef]]).andReturn(secondReceiptValidationStatusCacheEntry);

    auto cacheEntries =
        [validationStatusCache loadReceiptValidationStatusCacheEntries:@[@"foo", @"bar"].lt_set];

    expect(cacheEntries).to.equal(@{
      @"foo": cacheEntry,
      @"bar": secondReceiptValidationStatusCacheEntry
    });
  });

  it(@"should return dictionary without bundleIDs whose cache entry wasn't found", ^{
    OCMStub([validationStatusCache loadCacheEntryOfApplicationWithBundleID:@"foo"
        error:[OCMArg anyObjectRef]]).andReturn(cacheEntry);

    auto cacheEntries =
        [validationStatusCache loadReceiptValidationStatusCacheEntries:@[@"foo", @"bar"].lt_set];

    expect(cacheEntries).to.equal(@{@"foo": cacheEntry});
  });
});

SpecEnd
