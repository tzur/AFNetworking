// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTErrorCodesRegistry.h"

NS_ENUM(NSInteger) {
  LTKitTestsProductID = 127
};

LTErrorCodesDeclare(LTKitTestsProductID,
  LTKitTestsErrorCodeFoo,
  LTKitTestsErrorCodeBar
);

LTErrorCodesImplement(LTKitTestsProductID,
  LTKitTestsErrorCodeFoo,
  LTKitTestsErrorCodeBar
);

SpecBegin(LTErrorCodesRegistry)

context(@"auto registration", ^{
  it(@"should auto register error code", ^{
    NSString *description = [[LTErrorCodesRegistry sharedRegistry]
                             descriptionForErrorCode:LTKitTestsErrorCodeFoo];
    expect(description).notTo.beNil();
  });

  it(@"should register code with a proper description", ^{
    NSString *description = [[LTErrorCodesRegistry sharedRegistry]
                             descriptionForErrorCode:LTKitTestsErrorCodeFoo];
    expect(description).to.equal(@"LTKitTestsErrorCodeFoo");
  });
});

context(@"errors", ^{
  it(@"should raise if trying to register the same error code twice", ^{
    expect(^{
      [[LTErrorCodesRegistry sharedRegistry] registerErrorCodes:@{
        @(LTKitTestsErrorCodeFoo): @"foo"
      }];
    }).to.raise(NSInvalidArgumentException);
  });

  it(@"should raise if trying to register the same error description twice", ^{
    expect(^{
      [[LTErrorCodesRegistry sharedRegistry] registerErrorCodes:@{
        @(NSIntegerMax): @"LTKitTestsErrorCodeFoo"
      }];
    }).to.raise(NSInvalidArgumentException);
  });
});

SpecEnd
