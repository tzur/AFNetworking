// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "NSErrorCodes+LTKit.h"

NS_ENUM(NSInteger) {
  LTErrorCodesTestProductA = 254,
  LTErrorCodesTestProductB = 255
};

NS_ENUM(NSInteger) {
  LTErrorCodesTestSubsystemA = 1,
  LTErrorCodesTestSubsystemB = 2
};

LTErrorCodesDeclare(LTErrorCodesTestProductA,
  LTErrorCodesTestA,
  LTErrorCodesTestB
);

LTErrorCodesImplement(LTErrorCodesTestProductA,
  LTErrorCodesTestA,
  LTErrorCodesTestB
);

LTErrorCodesWithSubsystemDeclare(LTErrorCodesTestProductB, LTErrorCodesTestSubsystemA,
  LTErrorCodesSubsystemATestA,
  LTErrorCodesSubsystemATestB
);

LTErrorCodesWithSubsystemImplement(LTErrorCodesTestProductB, LTErrorCodesTestSubsystemA,
  LTErrorCodesSubsystemATestA,
  LTErrorCodesSubsystemATestB
);

LTErrorCodesWithSubsystemDeclare(LTErrorCodesTestProductB, LTErrorCodesTestSubsystemB,
  LTErrorCodesSubsystemBTestA,
  LTErrorCodesSubsystemBTestB
);

LTErrorCodesWithSubsystemImplement(LTErrorCodesTestProductB, LTErrorCodesTestSubsystemB,
  LTErrorCodesSubsystemBTestA,
  LTErrorCodesSubsystemBTestB
);

SpecBegin(NSErrorCodes_LTKit)

it(@"should define error codes without subsystem ID in the correct format", ^{
  expect(LTErrorCodesTestA).to.equal((LTErrorCodesTestProductA << LTErrorCodeOffsetProductID) + 0);
  expect(LTErrorCodesTestB).to.equal((LTErrorCodesTestProductA << LTErrorCodeOffsetProductID) + 1);
});

it(@"should define error codes with subsystem ID in the correct format", ^{
  expect(LTErrorCodesSubsystemATestA)
      .to.equal((LTErrorCodesTestProductB << LTErrorCodeOffsetProductID) |
                (LTErrorCodesTestSubsystemA << LTErrorCodeOffsetSubsystemID) + 0);
  expect(LTErrorCodesSubsystemATestB)
      .to.equal((LTErrorCodesTestProductB << LTErrorCodeOffsetProductID) |
                (LTErrorCodesTestSubsystemA << LTErrorCodeOffsetSubsystemID) + 1);

  expect(LTErrorCodesSubsystemBTestA)
      .to.equal((LTErrorCodesTestProductB << LTErrorCodeOffsetProductID) |
                (LTErrorCodesTestSubsystemB << LTErrorCodeOffsetSubsystemID) + 0);
  expect(LTErrorCodesSubsystemBTestB)
      .to.equal((LTErrorCodesTestProductB << LTErrorCodeOffsetProductID) |
                (LTErrorCodesTestSubsystemB << LTErrorCodeOffsetSubsystemID) + 1);
});

SpecEnd
