// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREvent.h"

SpecBegin(BZREvent)

context(@"initialization", ^{
  __block NSError *eventError;
  __block NSDictionary *eventInfo;

  beforeEach(^{
    eventError = [NSError lt_errorWithCode:1337];
    eventInfo = @{@"foo": @"bar"};
  });

  it(@"should fail initialization if initialized with error without an error event type", ^{
    expect(^{
      BZREvent __unused *event =
          [[BZREvent alloc] initWithType:$(BZREventTypePurchaseStatus) eventError:eventError];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should fail initialization if initialized with description with an error event type", ^{
    expect(^{
      BZREvent __unused *event =
          [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError) eventInfo:eventInfo];
    }).to.raise(NSInternalInconsistencyException);
  });

  it(@"should initialize successfuly if initialized with description with a non-error event "
     "type", ^{
    expect(^{
      BZREvent __unused *event =
          [[BZREvent alloc] initWithType:$(BZREventTypePurchaseStatus) eventInfo:eventInfo];
    }).toNot.raiseAny();
  });

  it(@"should initialize successfuly if initialized with error with an error event type", ^{
    expect(^{
      BZREvent __unused *event =
          [[BZREvent alloc] initWithType:$(BZREventTypeCriticalError) eventError:eventError];
    }).toNot.raiseAny();
  });
});

SpecEnd
