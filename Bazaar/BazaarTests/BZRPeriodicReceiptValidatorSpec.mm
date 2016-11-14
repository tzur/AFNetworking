// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPeriodicReceiptValidator.h"

#import "BZRReceiptValidationStatusProvider.h"

SpecBegin(BZRPeriodicReceiptValidator)

__block id<BZRReceiptValidationStatusProvider> receiptValidationStatusProvider;
__block BZRPeriodicReceiptValidator *periodicReceiptValidator;

beforeEach(^{
  receiptValidationStatusProvider = OCMProtocolMock(@protocol(BZRReceiptValidationStatusProvider));
  periodicReceiptValidator =
      [[BZRPeriodicReceiptValidator alloc]
       initWithReceiptValidationProvider:receiptValidationStatusProvider];
});

context(@"deallocating object", ^{
  it(@"should not create retain cycle", ^{
    BZRPeriodicReceiptValidator * __weak weakPeriodicValidator;
    RACSignal * __weak errorsSignal;

    @autoreleasepool {
      BZRPeriodicReceiptValidator *periodicReceiptValidator =
          [[BZRPeriodicReceiptValidator alloc]
           initWithReceiptValidationProvider:receiptValidationStatusProvider];
      weakPeriodicValidator = periodicReceiptValidator;

      OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
      [periodicReceiptValidator activatePeriodicValidationCheck:[RACSignal return:@"foo"]];
      errorsSignal = [periodicReceiptValidator.errorsSignal testRecorder];
    }

    expect(errorsSignal).to.beNil();
    expect(weakPeriodicValidator).to.beNil();
  });
});

context(@"activation", ^{
  it(@"should validate receipt when validateReceiptSignal fires", ^{
    RACSignal *receiptValidationTrigger = [RACSignal return:[RACUnit defaultUnit]];
    [periodicReceiptValidator activatePeriodicValidationCheck:receiptValidationTrigger];
    OCMVerify([receiptValidationStatusProvider fetchReceiptValidationStatus]);
  });

  it(@"should send error when receipt validation provider errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([receiptValidationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal error:error]);

    LLSignalTestRecorder *recorder = [periodicReceiptValidator.errorsSignal testRecorder];

    RACSignal *receiptValidationTrigger = [RACSignal return:[RACUnit defaultUnit]];
    [periodicReceiptValidator activatePeriodicValidationCheck:receiptValidationTrigger];

    expect(recorder).will.sendValues(@[error]);
  });

  it(@"should hold trigger signal strongly and keep subscription to it", ^{
    OCMExpect([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    @autoreleasepool {
      RACSignal *triggerSignal = [[RACSignal
          return:[RACUnit defaultUnit]]
          subscribeOn:[RACScheduler scheduler]];
      [periodicReceiptValidator activatePeriodicValidationCheck:triggerSignal];
    }

    OCMVerifyAllWithDelay((id)receiptValidationStatusProvider, 0.1);
  });

  it(@"should unsubscribe from the trigger signal when reactivated with new trigger signal", ^{
    RACSubject *triggerSignal = [RACSubject subject];
    RACSignal *anotherTriggerSignal = [RACSignal never];

    [periodicReceiptValidator activatePeriodicValidationCheck:triggerSignal];
    [periodicReceiptValidator activatePeriodicValidationCheck:anotherTriggerSignal];

    OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    [triggerSignal sendNext:[RACUnit defaultUnit]];
  });

  it(@"should unsubscribe from the trigger signal when deallocated", ^{
    RACSubject *triggerSignal = [RACSubject subject];
    BZRPeriodicReceiptValidator __weak *weakPeriodicReceiptValidator;
    @autoreleasepool {
      BZRPeriodicReceiptValidator *periodicReceiptValidator =
          [[BZRPeriodicReceiptValidator alloc]
           initWithReceiptValidationProvider:receiptValidationStatusProvider];
      weakPeriodicReceiptValidator = periodicReceiptValidator;
      [periodicReceiptValidator activatePeriodicValidationCheck:triggerSignal];
    }

    expect(weakPeriodicReceiptValidator).to.beNil();

    OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);
    [triggerSignal sendNext:[RACUnit defaultUnit]];
  });
});

context(@"deactivating timer", ^{
  it(@"should not validate receipt after timer has been deactivated", ^{
    RACSubject *subject = [RACSubject subject];
    OCMReject([receiptValidationStatusProvider fetchReceiptValidationStatus]);

    [periodicReceiptValidator activatePeriodicValidationCheck:subject];
    [periodicReceiptValidator deactivatePeriodicValidationCheck];
    [subject sendNext:@"foo"];
  });
});

SpecEnd
