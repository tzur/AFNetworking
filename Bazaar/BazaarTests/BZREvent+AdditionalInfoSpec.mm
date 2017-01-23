// Copyright (c) 2017 Lightricks. All rights reserved.
// Created by Ben Yohay.

#import "BZREvent+AdditionalInfo.h"

SpecBegin(BZREvent_AdditionalInfo)

context(@"additional info", ^{
  it(@"should set request id correctly", ^{
    BZREvent *event = [BZREvent receiptValidationStatusReceivedEvent:@"foo"];

    expect(event.requestId).to.equal(@"foo");
  });
});

SpecEnd
