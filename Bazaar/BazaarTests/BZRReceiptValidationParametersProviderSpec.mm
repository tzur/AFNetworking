// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRReceiptValidationParametersProvider.h"

#import "BZREvent.h"
#import "BZRKeychainStorage+TypeSafety.h"
#import "NSErrorCodes+Bazaar.h"

SpecBegin(BZRReceiptValidationParametersProviderSpec)

__block BZRKeychainStorage *keychainStorage;
__block BZRReceiptValidationParametersProvider *parametersProvider;

beforeEach(^{
  keychainStorage = OCMClassMock([BZRKeychainStorage class]);
  parametersProvider =
      [[BZRReceiptValidationParametersProvider alloc] initWithKeychainStorage:keychainStorage];
});

context(@"loading app store locale from storage", ^{
  it(@"should be nil if app store locale not found in storage", ^{
    expect([parametersProvider appStoreLocale]).to.beNil();
  });

  it(@"should be nil if there was an error loading the app store locale", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorage valueOfClass:NSLocale.class forKey:OCMOCK_ANY
                                    error:[OCMArg setTo:error]]);

    expect([parametersProvider appStoreLocale]).to.beNil();
  });

  it(@"should send error event if there was an error loading the app store locale", ^{
    NSError *storageError = [NSError lt_errorWithCode:1337];
    OCMStub([keychainStorage valueOfClass:NSString.class forKey:OCMOCK_ANY
                                    error:[OCMArg setTo:storageError]]);

    parametersProvider =
        [[BZRReceiptValidationParametersProvider alloc] initWithKeychainStorage:keychainStorage];
    auto recorder = [parametersProvider.eventsSignal testRecorder];

    expect(recorder).to.matchValue(0, ^BOOL(BZREvent *event) {
      NSError *error = event.eventError;
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] &&
          error.code == BZRErrorCodeLoadingDataFromStorageFailed &&
          error.lt_underlyingError == storageError;
    });
  });
});

context(@"storing app store locale to storage", ^{
  it(@"should store app store locale to storage after it has been set", ^{
    NSLocale *appStoreLocale = [NSLocale currentLocale];

    OCMExpect([keychainStorage setValue:appStoreLocale forKey:OCMOCK_ANY
                                  error:[OCMArg anyObjectRef]]);

    parametersProvider.appStoreLocale = appStoreLocale;
  });

  it(@"should not store app store locale if the new value is identical to the old one", ^{
    NSLocale *appStoreLocale = [NSLocale currentLocale];
    parametersProvider.appStoreLocale = appStoreLocale;

    OCMReject([keychainStorage setValue:appStoreLocale forKey:OCMOCK_ANY
                                  error:[OCMArg anyObjectRef]]);

    parametersProvider.appStoreLocale = [NSLocale currentLocale];
  });

  it(@"should send error event if there was an error storing the app store locale to storage", ^{
    NSLocale *appStoreLocale = [NSLocale currentLocale];
    auto recorder = [parametersProvider.eventsSignal testRecorder];
    NSError *storageError = [NSError lt_errorWithCode:1337];
    OCMExpect([keychainStorage setValue:[appStoreLocale localeIdentifier] forKey:OCMOCK_ANY
                                  error:[OCMArg setTo:storageError]]);

    parametersProvider.appStoreLocale = appStoreLocale;

    expect(recorder).to.matchValue(0, ^BOOL(BZREvent *event) {
      NSError *error = event.eventError;
      return [event.eventType isEqual:$(BZREventTypeNonCriticalError)] &&
          error.code == BZRErrorCodeStoringDataToStorageFailed &&
          error.lt_underlyingError == storageError;
    });
  });
});

context(@"KVO-compliance", ^{
  it(@"should update when app store locale changes", ^{
    RACSignal *appStoreLocaleSignal = [RACObserve(parametersProvider, appStoreLocale) testRecorder];

    parametersProvider.appStoreLocale = [NSLocale currentLocale];

    expect(appStoreLocaleSignal).to.sendValues(@[
      [NSNull null],
      [NSLocale currentLocale]
    ]);
  });
});

SpecEnd
