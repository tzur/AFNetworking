// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Neria Saada.

#import "BZRKeychainStorageMigrator.h"

#import "BZREvent.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRKeychainStorageMigrator)

static NSString * const kSourceKey = @"dictionaryKey";
static NSDictionary<NSString *, id> * const sourceValue = @{@"foo": @"bar"};

__block BZRKeychainStorage *sourceKeychainStorage;
__block BZRKeychainStorage *targetKeychainStorage;
__block BZRKeychainStorageMigrator *migrator;

context(@"migrator", ^{
  beforeEach(^{
    sourceKeychainStorage = OCMClassMock([BZRKeychainStorage class]);
    targetKeychainStorage = OCMClassMock([BZRKeychainStorage class]);

    migrator =
        [[BZRKeychainStorageMigrator alloc] initWithSourceKeychainStorage:sourceKeychainStorage
                                                    targetKeychainStorage:targetKeychainStorage];
  });

  context(@"migrating keychain storage", ^{
    beforeEach(^{
      OCMStub([sourceKeychainStorage valueOfClass:[sourceValue class] forKey:kSourceKey
                                            error:[OCMArg anyObjectRef]]).andReturn(sourceValue);
    });

    it(@"should migrate the specified value from source keychain if there is no data in the target "
           "keychain storage", ^{
      OCMExpect([targetKeychainStorage setValue:sourceValue forKey:kSourceKey
                                          error:[OCMArg anyObjectRef]]).andReturn(YES);

      BOOL success = [migrator migrateValueForKey:kSourceKey ofClass:[sourceValue class] error:nil];

      expect(success).to.equal(YES);
      OCMVerifyAll(targetKeychainStorage);
    });

    it(@"should not migrate value of key that exists in target keychain storage", ^{
      OCMStub([targetKeychainStorage valueOfClass:[sourceValue class] forKey:kSourceKey
                                            error:[OCMArg anyObjectRef]]).andReturn(@{});
      OCMReject([targetKeychainStorage setValue:sourceValue forKey:kSourceKey
                                          error:[OCMArg anyObjectRef]]);

      BOOL success = [migrator migrateValueForKey:kSourceKey ofClass:[sourceValue class] error:nil];
      expect(success).to.equal(YES);
    });

    context(@"clearing the source keychain storage after migratation", ^{
      it(@"should clear the source keychain storage after migration", ^{
        OCMStub([targetKeychainStorage setValue:OCMOCK_ANY forKey:kSourceKey
                                          error:[OCMArg anyObjectRef]]).andReturn(YES);

        [migrator migrateValueForKey:kSourceKey ofClass:[sourceValue class] error:nil];

        OCMVerify([sourceKeychainStorage setValue:nil forKey:kSourceKey
                                            error:[OCMArg anyObjectRef]]);
      });

      it(@"should not clear the source keychain storage if the migration didn't succeed", ^{
        OCMStub([targetKeychainStorage setValue:OCMOCK_ANY forKey:kSourceKey
                                          error:[OCMArg anyObjectRef]]).andReturn(NO);
        OCMReject([sourceKeychainStorage setValue:nil forKey:kSourceKey
                                            error:[OCMArg anyObjectRef]]);

        [migrator migrateValueForKey:kSourceKey ofClass:[sourceValue class]  error:nil];
      });
    });
  });

  context(@"storage errors", ^{
    __block NSError *error;

    beforeEach(^{
      error = [NSError lt_errorWithCode:1337];
    });

    it(@"should return error when failed to read from source storage", ^{
      OCMStub([sourceKeychainStorage valueOfClass:OCMOCK_ANY forKey:OCMOCK_ANY
                                            error:[OCMArg setTo:error]]);
      OCMReject([targetKeychainStorage setValue:OCMOCK_ANY forKey:kSourceKey
                                          error:[OCMArg anyObjectRef]]);

      NSError *underlyingError;
      BOOL success = [migrator migrateValueForKey:kSourceKey ofClass:[sourceValue class]
                                            error:&underlyingError];
      expect(underlyingError).to.equal(error);
      expect(success).to.equal(NO);
    });

    it(@"should return storage error when saving to target storage has failed", ^{
      OCMStub([sourceKeychainStorage valueOfClass:[sourceValue class] forKey:OCMOCK_ANY
                                            error:[OCMArg anyObjectRef]]).andReturn(@{});
      OCMStub([targetKeychainStorage setValue:OCMOCK_ANY forKey:OCMOCK_ANY
                                        error:[OCMArg setTo:error]]).andReturn(NO);

      NSError *underlyingError;
      BOOL success = [migrator migrateValueForKey:kSourceKey ofClass:[sourceValue class]
                                            error:&underlyingError];
      expect(underlyingError).to.equal(error);
      expect(success).to.equal(NO);
    });
  });
});

SpecEnd
