// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZRPeriodicReceiptValidatorActivator.h"

#import <LTKit/LTDateProvider.h>

#import "BZRExternalTriggerReceiptValidator.h"
#import "BZRReceiptValidationDateProvider.h"

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
__block NSDate *currentDate;
__block id<LTDateProvider> dateProvider;

beforeEach(^{
  receiptValidator = OCMClassMock([BZRExternalTriggerReceiptValidator class]);
  validationDateProvider = [[BZRFakeReceiptValidationDateProvider alloc] init];
  currentDate = [NSDate dateWithTimeIntervalSince1970:1337];
  dateProvider = OCMClassMock(LTDateProvider.class);
  OCMStub([dateProvider currentDate]).andReturn(currentDate);
  auto __unused activator = [[BZRPeriodicReceiptValidatorActivator alloc]
      initWithReceiptValidator:receiptValidator
      validationDateProvider:validationDateProvider dateProvider:dateProvider];
});

context(@"deallocating object", ^{
  it(@"should dealloc when all strong references are relinquished", ^{
    BZRPeriodicReceiptValidatorActivator * __weak weakPeriodicValidatorActivator;

    @autoreleasepool {
      BZRPeriodicReceiptValidatorActivator *receiptValidatorActivator =
          [[BZRPeriodicReceiptValidatorActivator alloc]
           initWithReceiptValidator:receiptValidator
           validationDateProvider:validationDateProvider dateProvider:dateProvider];
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
      validationDateProvider.nextValidationDate = [currentDate dateByAddingTimeInterval:1];

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
      validationDateProvider.nextValidationDate = [currentDate dateByAddingTimeInterval:-1];

      expect(validateReceiptSignal).to.sendValuesWithCount(1);
    });
  });
});

SpecEnd
