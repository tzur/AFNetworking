// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRReceiptValidationStatusCache.h"

#import "BZRKeychainStorageRoute.h"
#import "BZRReceiptModel.h"
#import "BZRReceiptValidationStatus.h"
#import "BZRTestUtils.h"
#import "BZRValidatricksReceiptModelDeprecated.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRReceiptValidationStatusCache)

static NSString * const kValidationStatusKey = @"validationStatus";
static NSString * const kValidationDateKey = @"validationDate";
static NSString * const kCachedReceiptValidationStatusStorageKey = @"receiptValidationStatus";

__block BZRKeychainStorageRoute *keychainStorageRoute;
__block BZRReceiptValidationStatus *receiptValidationStatus;
__block BZRReceiptValidationStatusCache *validationStatusCache;
__block NSString *applicationBundleID;

beforeEach(^{
  keychainStorageRoute = OCMClassMock([BZRKeychainStorageRoute class]);
  receiptValidationStatus = BZRReceiptValidationStatusWithExpiry(NO);
  validationStatusCache =
      [[BZRReceiptValidationStatusCache alloc] initWithKeychainStorage:keychainStorageRoute];

  applicationBundleID = @"foo";
});

context(@"cache access", ^{
  it(@"should read receipt validation status and cached date from cache", ^{
    auto cachedDate = [NSDate date];
    NSDictionary *receiptDictionary = @{
      kValidationStatusKey: receiptValidationStatus,
      kValidationDateKey: cachedDate
    };

    OCMExpect([keychainStorageRoute valueForKey:kCachedReceiptValidationStatusStorageKey
        serviceName:applicationBundleID error:[OCMArg anyObjectRef]]).andReturn(receiptDictionary);

    auto validationStatusCacheEntry =
        [validationStatusCache loadCacheEntryOfApplicationWithBundleID:applicationBundleID
                                                                 error:nil];

    expect(validationStatusCacheEntry.receiptValidationStatus).to.equal(receiptValidationStatus);
    expect(validationStatusCacheEntry.cachingDateTime).to.equal(cachedDate);
    OCMVerifyAll((id)keychainStorageRoute);
  });

  it(@"should store receipt validation to cache", ^{
    auto cachedDate = [NSDate date];
    NSDictionary<NSString *, id> *cachedReceiptDictionary = @{
      kValidationStatusKey: receiptValidationStatus,
      kValidationDateKey: cachedDate
    };
    OCMExpect([keychainStorageRoute setValue:cachedReceiptDictionary
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
        serviceName:applicationBundleID error:[OCMArg setTo:error]]).andReturn(NO);
    validationStatusCache = [[BZRReceiptValidationStatusCache alloc]
                             initWithKeychainStorage:keychainStorageRoute];
    auto cacheEntry = [[BZRReceiptValidationStatusCacheEntry alloc]
                       initWithReceiptValidationStatus:receiptValidationStatus
                       cachingDateTime:[NSDate date]];
    NSError *returnedError;
    BOOL success = [validationStatusCache storeCacheEntry:cacheEntry
                                      applicationBundleID:applicationBundleID error:&returnedError];

    expect(returnedError).to.equal(error);
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

  context(@"old version cache entry", ^{
    __block MTLJSONAdapter *adapter;

    beforeEach(^{
      adapter = OCMClassMock(MTLJSONAdapter.class);
    });

    afterEach(^{
      adapter = nil;
    });

    it(@"should store new version receipt validation status and cached date if the old version is "
        "found in cache", ^{
      auto cachedDate = [NSDate date];
      auto receiptValidationStatusJSON =
          [MTLJSONAdapter JSONDictionaryFromModel:receiptValidationStatus];
      NSError *error;
      BZRValidatricksReceiptValidationStatus *validatricksReceiptValidationStatus =
          [MTLJSONAdapter modelOfClass:BZRValidatricksReceiptValidationStatus.class
                    fromJSONDictionary:receiptValidationStatusJSON error:&error];
      NSDictionary<NSString *, id> *cachedReceiptDictionary = @{
        kValidationStatusKey: validatricksReceiptValidationStatus,
        kValidationDateKey: cachedDate
      };
      OCMStub([keychainStorageRoute valueForKey:kCachedReceiptValidationStatusStorageKey
          serviceName:applicationBundleID error:[OCMArg anyObjectRef]])
          .andReturn(cachedReceiptDictionary);

      NSDictionary<NSString *, id> *expectedReceiptDictionaryToStore = @{
        kValidationStatusKey: receiptValidationStatus,
        kValidationDateKey: cachedDate
      };
      OCMExpect([keychainStorageRoute setValue:expectedReceiptDictionaryToStore
          forKey:kCachedReceiptValidationStatusStorageKey serviceName:applicationBundleID
          error:[OCMArg anyObjectRef]]).andReturn(YES);

      [validationStatusCache loadCacheEntryOfApplicationWithBundleID:applicationBundleID error:nil];

      OCMVerifyAll((id)keychainStorageRoute);
    });

    it(@"should return nil if failed to serialize stored receipt validation status to JSON", ^{
      auto cachedDate = [NSDate date];
      auto receiptValidationStatusJSON =
          [MTLJSONAdapter JSONDictionaryFromModel:receiptValidationStatus];
      NSError *error;
      BZRValidatricksReceiptValidationStatus *validatricksReceiptValidationStatus =
          [MTLJSONAdapter modelOfClass:BZRValidatricksReceiptValidationStatus.class
                    fromJSONDictionary:receiptValidationStatusJSON error:&error];
      NSDictionary<NSString *, id> *cachedReceiptDictionary = @{
        kValidationStatusKey: validatricksReceiptValidationStatus,
        kValidationDateKey: cachedDate
      };
      OCMStub([keychainStorageRoute valueForKey:kCachedReceiptValidationStatusStorageKey
          serviceName:applicationBundleID error:[OCMArg anyObjectRef]])
          .andReturn(cachedReceiptDictionary);

      OCMStub([(id)adapter JSONDictionaryFromModel:OCMOCK_ANY]);

      expect([validationStatusCache loadCacheEntryOfApplicationWithBundleID:applicationBundleID
                                                                      error:nil]).to.beNil();
    });

    it(@"should return nil if failed to serialize stored receipt validation status to JSON", ^{
      auto cachedDate = [NSDate date];
      auto receiptValidationStatusJSON =
          [MTLJSONAdapter JSONDictionaryFromModel:receiptValidationStatus];
      NSError *error;
      BZRValidatricksReceiptValidationStatus *validatricksReceiptValidationStatus =
          [MTLJSONAdapter modelOfClass:BZRValidatricksReceiptValidationStatus.class
                    fromJSONDictionary:receiptValidationStatusJSON error:&error];
      NSDictionary<NSString *, id> *cachedReceiptDictionary = @{
        kValidationStatusKey: validatricksReceiptValidationStatus,
        kValidationDateKey: cachedDate
      };
      OCMStub([keychainStorageRoute valueForKey:kCachedReceiptValidationStatusStorageKey
          serviceName:applicationBundleID error:[OCMArg anyObjectRef]])
          .andReturn(cachedReceiptDictionary);

      OCMStub([(id)adapter modelOfClass:OCMOCK_ANY fromJSONDictionary:OCMOCK_ANY
                                  error:[OCMArg anyObjectRef]]);

      expect([validationStatusCache loadCacheEntryOfApplicationWithBundleID:applicationBundleID
                                                                      error:nil]).to.beNil();
    });
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
