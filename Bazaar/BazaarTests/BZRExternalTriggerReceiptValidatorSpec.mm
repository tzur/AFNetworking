// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRExternalTriggerReceiptValidator.h"

#import "BZREvent.h"
#import "BZRFakeMultiAppReceiptValidationStatusProvider.h"

SpecBegin(BZRExternalTriggerReceiptValidator)

__block BZRFakeMultiAppReceiptValidationStatusProvider *validationStatusProvider;
__block BZRExternalTriggerReceiptValidator *receiptValidator;

beforeEach(^{
  validationStatusProvider = OCMClassMock([BZRFakeMultiAppReceiptValidationStatusProvider class]);
  receiptValidator =
      [[BZRExternalTriggerReceiptValidator alloc]
       initWithValidationStatusProvider:validationStatusProvider];
});

context(@"deallocating object", ^{
  it(@"should not create retain cycle", ^{
    BZRExternalTriggerReceiptValidator * __weak weakPeriodicValidator;
    RACSignal * __weak errorsSignal;

    @autoreleasepool {
      BZRExternalTriggerReceiptValidator *receiptValidator =
          [[BZRExternalTriggerReceiptValidator alloc]
           initWithValidationStatusProvider:validationStatusProvider];
      weakPeriodicValidator = receiptValidator;

      OCMStub([validationStatusProvider fetchReceiptValidationStatus])
          .andReturn([RACSignal error:[NSError lt_errorWithCode:1337]]);
      [receiptValidator activateWithTrigger:[RACSignal return:@"foo"]];
      errorsSignal = [receiptValidator.eventsSignal testRecorder];
    }

    expect(errorsSignal).to.beNil();
    expect(weakPeriodicValidator).to.beNil();
  });
});

context(@"activation", ^{
  it(@"should validate receipt when the trigger signal fires", ^{
    RACSignal *receiptValidationTrigger = [RACSignal return:[RACUnit defaultUnit]];
    [receiptValidator activateWithTrigger:receiptValidationTrigger];
    OCMVerify([validationStatusProvider fetchReceiptValidationStatus]);
  });

  it(@"should send error event when receipt validation provider errs", ^{
    NSError *error = [NSError lt_errorWithCode:1337];
    OCMStub([validationStatusProvider fetchReceiptValidationStatus])
        .andReturn([RACSignal error:error]);

    LLSignalTestRecorder *recorder = [receiptValidator.eventsSignal testRecorder];

    RACSignal *receiptValidationTrigger = [RACSignal return:[RACUnit defaultUnit]];
    [receiptValidator activateWithTrigger:receiptValidationTrigger];

    BZREvent *errorEvent = [[BZREvent alloc] initWithType:$(BZREventTypeNonCriticalError)
                                               eventError:error];
    expect(recorder).will.sendValues(@[errorEvent]);
  });

  it(@"should hold trigger signal strongly and keep subscription to it", ^{
    OCMExpect([validationStatusProvider fetchReceiptValidationStatus]);
    @autoreleasepool {
      RACSignal *triggerSignal = [[RACSignal
          return:[RACUnit defaultUnit]]
          deliverOn:[RACScheduler scheduler]];
      [receiptValidator activateWithTrigger:triggerSignal];
    }

    OCMVerifyAllWithDelay((id)validationStatusProvider, 0.1);
  });

  it(@"should unsubscribe from the trigger signal when reactivated with new trigger signal", ^{
    RACSubject *triggerSignal = [RACSubject subject];
    RACSignal *anotherTriggerSignal = [RACSignal never];

    [receiptValidator activateWithTrigger:triggerSignal];
    [receiptValidator activateWithTrigger:anotherTriggerSignal];

    OCMReject([validationStatusProvider fetchReceiptValidationStatus]);
    [triggerSignal sendNext:[RACUnit defaultUnit]];
  });

  it(@"should unsubscribe from the trigger signal when deallocated", ^{
    RACSubject *triggerSignal = [RACSubject subject];
    BZRExternalTriggerReceiptValidator __weak *weakReceiptValidator;
    @autoreleasepool {
      BZRExternalTriggerReceiptValidator *receiptValidator =
          [[BZRExternalTriggerReceiptValidator alloc]
           initWithValidationStatusProvider:validationStatusProvider];
      weakReceiptValidator = receiptValidator;
      [receiptValidator activateWithTrigger:triggerSignal];
    }

    expect(weakReceiptValidator).to.beNil();

    OCMReject([validationStatusProvider fetchReceiptValidationStatus]);
    [triggerSignal sendNext:[RACUnit defaultUnit]];
  });
});

context(@"deactivation", ^{
  it(@"should not validate receipt after deactivation", ^{
    RACSubject *subject = [RACSubject subject];
    [receiptValidator activateWithTrigger:subject];
    [receiptValidator deactivate];

    OCMReject([validationStatusProvider fetchReceiptValidationStatus]);
    [subject sendNext:@"foo"];
  });
});

SpecEnd
