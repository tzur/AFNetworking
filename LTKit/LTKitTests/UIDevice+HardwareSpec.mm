// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "UIDevice+Hardware.h"

SpecBegin(UIDevice_Hardware)

__block UIDevice *device;

beforeEach(^{
  device = OCMPartialMock([UIDevice currentDevice]);
});

afterEach(^{
  device = nil;
});

context(@"device idioms", ^{
  context(@"ipad devices", ^{
    beforeEach(^{
      OCMStub([device userInterfaceIdiom]).andReturn(UIUserInterfaceIdiomPad);
      OCMStub([device lt_platformName]).andReturn(@"iPad1");
    });

    it(@"should return correct idiom", ^{
      expect(device.lt_isPadIdiom).to.beTruthy();
      expect(device.lt_isPhoneIdiom).to.beFalsy();
    });

    it(@"should execute ipad block", ^{
      __block BOOL executed = NO;

      [device lt_iPad:^{
        executed = YES;
      }];

      expect(executed).to.beTruthy();
    });

    it(@"should execute ipad block and not iphone", ^{
      __block BOOL iPadExecuted = NO;
      __block BOOL iPhoneExecuted = NO;

      [device lt_iPhone:^{
        iPhoneExecuted = YES;
      } iPad:^{
        iPadExecuted = YES;
      }];

      expect(iPhoneExecuted).to.beFalsy();
      expect(iPadExecuted).to.beTruthy();
    });

    it(@"should not execute iphone block", ^{
      __block BOOL executed = NO;

      [device lt_iPhone:^{
        executed = YES;
      }];

      expect(executed).to.beFalsy();
    });
  });

  context(@"iphone devices", ^{
    beforeEach(^{
      OCMStub([device userInterfaceIdiom]).andReturn(UIUserInterfaceIdiomPhone);
      OCMStub([device lt_platformName]).andReturn(@"iPhone1");
    });

    it(@"should return correct idiom", ^{
      expect(device.lt_isPadIdiom).to.beFalsy();
      expect(device.lt_isPhoneIdiom).to.beTruthy();
    });

    it(@"should execute iphone block", ^{
      __block BOOL executed = NO;

      [device lt_iPhone:^{
        executed = YES;
      }];

      expect(executed).to.beTruthy();
    });

    it(@"should execute iphone block and not ipad", ^{
      __block BOOL iPadExecuted = NO;
      __block BOOL iPhoneExecuted = NO;

      [device lt_iPhone:^{
        iPhoneExecuted = YES;
      } iPad:^{
        iPadExecuted = YES;
      }];

      expect(iPhoneExecuted).to.beTruthy();
      expect(iPadExecuted).to.beFalsy();
    });

    it(@"should not execute ipad block", ^{
      __block BOOL executed = NO;

      [device lt_iPad:^{
        executed = YES;
      }];

      expect(executed).to.beFalsy();
    });
  });

  context(@"unspecified devices", ^{
    beforeEach(^{
      OCMStub([device userInterfaceIdiom]).andReturn(UIUserInterfaceIdiomUnspecified);
      OCMStub([device lt_platformName]).andReturn(@"unknown");
    });

    it(@"should not execute any block", ^{
      __block BOOL iPadExecuted = NO;
      __block BOOL iPhoneExecuted = NO;

      [device lt_iPhone:^{
        iPhoneExecuted = YES;
      } iPad:^{
        iPadExecuted = YES;
      }];

      expect(iPhoneExecuted).to.beFalsy();
      expect(iPadExecuted).to.beFalsy();
    });
  });
});

context(@"platform info", ^{
  beforeEach(^{
    OCMStub([device userInterfaceIdiom]).andReturn(UIUserInterfaceIdiomPad);
    OCMStub([device lt_platformName]).andReturn(@"iPad1");
  });

  it(@"should return correct device kind", ^{
    expect(device.lt_deviceKind).to.equal(UIDeviceKindIPad1G);
  });

  it(@"should return correct device kind string", ^{
    expect(device.lt_deviceKindString).to.equal(@"UIDeviceKindIPad1G");
  });
});

SpecEnd
