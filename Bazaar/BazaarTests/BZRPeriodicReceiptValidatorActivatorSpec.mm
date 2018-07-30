// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPeriodicReceiptValidatorActivator.h"

#import "BZRExternalTriggerReceiptValidator.h"
#import "BZRReceiptValidationDateProvider.h"
#import "BZRTimeProvider.h"

/// Fake receipt validation date provider that initializes \c nextValidationDate to
/// \c [NSDate date].
@interface BZRFakeReceiptValidationDateProvider : NSObject <BZRReceiptValidationDateProvider>

/// Redeclared as readwrite.
@property (strong, readwrite, nonatomic, nullable) NSDate *nextValidationDate;

@end

@implementation BZRFakeReceiptValidationDateProvider
@end

SpecBegin(BZRPeriodicReceiptValidatorActivator)

__block BZRExternalTriggerReceiptValidator *receiptValidator;
__block BZRFakeReceiptValidationDateProvider *validationDateProvider;
__block NSDate *currentTime;
__block id<BZRTimeProvider> timeProvider;

beforeEach(^{
  receiptValidator = OCMClassMock([BZRExternalTriggerReceiptValidator class]);
  validationDateProvider = [[BZRFakeReceiptValidationDateProvider alloc] init];
  currentTime = [NSDate dateWithTimeIntervalSince1970:1337];
  timeProvider = OCMProtocolMock(@protocol(BZRTimeProvider));
  OCMStub([timeProvider currentTime]).andReturn([RACSignal return:currentTime]);
  auto __unused activator = [[BZRPeriodicReceiptValidatorActivator alloc]
      initWithReceiptValidator:receiptValidator
      validationDateProvider:validationDateProvider timeProvider:timeProvider];
});

context(@"deallocating object", ^{
  it(@"should dealloc when all strong references are relinquished", ^{
    BZRPeriodicReceiptValidatorActivator * __weak weakPeriodicValidatorActivator;

    @autoreleasepool {
      BZRPeriodicReceiptValidatorActivator *receiptValidatorActivator =
          [[BZRPeriodicReceiptValidatorActivator alloc]
           initWithReceiptValidator:receiptValidator
           validationDateProvider:validationDateProvider timeProvider:timeProvider];
      weakPeriodicValidatorActivator = receiptValidatorActivator;
    }

    expect(weakPeriodicValidatorActivator).will.beNil();
  });
});

context(@"subscription exists", ^{
  context(@"activating receipt validation", ^{
    it(@"should deactivate periodic validator if next validation date is nil", ^{
      OCMVerify([receiptValidator deactivate]);
    });

    it(@"should activate periodic validation if next validation date is not nil", ^{
      validationDateProvider.nextValidationDate = [currentTime dateByAddingTimeInterval:1];

      OCMVerify([receiptValidator activateWithTrigger:OCMOCK_ANY]);
    });

    it(@"should send value immediately if next validation date is earlier than current time", ^{
      __block RACSignal *validateReceiptSignal;
      OCMStub([receiptValidator activateWithTrigger:OCMOCK_ANY])
          .andDo(^(NSInvocation *invocation) {
            __unsafe_unretained RACSignal *signal;
            [invocation getArgument:&signal atIndex:2];
            validateReceiptSignal = signal;
          });
      validationDateProvider.nextValidationDate = [currentTime dateByAddingTimeInterval:-1];

      expect(validateReceiptSignal).to.sendValuesWithCount(1);
    });
  });
});

SpecEnd
