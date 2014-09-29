// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTDevice.h"

SpecBegin(LTDevice)

context(@"device idioms", ^{
  context(@"ipad devices", ^{
    __block LTDevice *device;

    beforeEach(^{
      id uiDevice = [OCMockObject mockForClass:[UIDevice class]];
      [[[uiDevice stub] andReturnValue:@(UIUserInterfaceIdiomPad)] userInterfaceIdiom];

      device = [[LTDevice alloc] initWithUIDevice:uiDevice
                                         UIScreen:[UIScreen mainScreen]
                                     platformName:@"iPad1"
                                       mainBundle:[NSBundle mainBundle]];
    });

    afterEach(^{
      device = nil;
    });

    it(@"should return correct idiom", ^{
      expect(device.isPadIdiom).to.beTruthy();
      expect(device.isPhoneIdiom).to.beFalsy();
    });

    it(@"should execute ipad block", ^{
      __block BOOL executed = NO;

      [device iPad:^{
        executed = YES;
      }];

      expect(executed).to.beTruthy();
    });

    it(@"should execute ipad block and not iphone", ^{
      __block BOOL iPadExecuted = NO;
      __block BOOL iPhoneExecuted = NO;

      [device iPhone:^{
        iPhoneExecuted = YES;
      } iPad:^{
        iPadExecuted = YES;
      }];

      expect(iPhoneExecuted).to.beFalsy();
      expect(iPadExecuted).to.beTruthy();
    });

    it(@"should not execute iphone block", ^{
      __block BOOL executed = NO;

      [device iPhone:^{
        executed = YES;
      }];

      expect(executed).to.beFalsy();
    });
  });

  context(@"iphone devices", ^{
    __block LTDevice *device;

    beforeEach(^{
      id uiDevice = [OCMockObject mockForClass:[UIDevice class]];
      [[[uiDevice stub] andReturnValue:@(UIUserInterfaceIdiomPhone)] userInterfaceIdiom];

      device = [[LTDevice alloc] initWithUIDevice:uiDevice
                                         UIScreen:[UIScreen mainScreen]
                                     platformName:@"iPhone1"
                                       mainBundle:[NSBundle mainBundle]];
    });

    afterEach(^{
      device = nil;
    });

    it(@"should return correct idiom", ^{
      expect(device.isPadIdiom).to.beFalsy();
      expect(device.isPhoneIdiom).to.beTruthy();
    });

    it(@"should execute iphone block", ^{
      __block BOOL executed = NO;

      [device iPhone:^{
        executed = YES;
      }];

      expect(executed).to.beTruthy();
    });

    it(@"should execute iphone block and not ipad", ^{
      __block BOOL iPadExecuted = NO;
      __block BOOL iPhoneExecuted = NO;

      [device iPhone:^{
        iPhoneExecuted = YES;
      } iPad:^{
        iPadExecuted = YES;
      }];

      expect(iPhoneExecuted).to.beTruthy();
      expect(iPadExecuted).to.beFalsy();
    });

    it(@"should not execute ipad block", ^{
      __block BOOL executed = NO;

      [device iPad:^{
        executed = YES;
      }];

      expect(executed).to.beFalsy();
    });
  });
});

context(@"platform info", ^{
  __block LTDevice *device;

  NSString *platformName = @"iPad1";

  beforeEach(^{
    device = [[LTDevice alloc] initWithUIDevice:[UIDevice currentDevice]
                                       UIScreen:[UIScreen mainScreen]
                                   platformName:platformName
                                     mainBundle:[NSBundle mainBundle]];
  });

  afterEach(^{
    device = nil;
  });

  it(@"should provide correct platform name", ^{
    expect(device.platformName).to.equal(platformName);
  });

  it(@"should return correct device type", ^{
    expect(device.deviceType).to.equal(LTDeviceTypeIPad1G);
  });

  it(@"should return correct device type string", ^{
    expect(device.deviceTypeString).to.equal(@"LTDeviceTypeIPad1G");
  });

  it(@"should return 3.5 inch screen given correct size", ^{
    id screen = [OCMockObject mockForClass:[UIScreen class]];

    CGRect bounds = CGRectMake(0, 0, 320, 480);
    [[[screen stub] andReturnValue:$(bounds)] bounds];

    LTDevice *device = [[LTDevice alloc] initWithUIDevice:[UIDevice currentDevice]
                                                 UIScreen:screen
                                             platformName:nil
                                               mainBundle:[NSBundle mainBundle]];

    expect(device.has3_5InchScreen).to.beTruthy();
    expect(device.has4InchScreen).to.beFalsy();
    expect(device.has4_7InchScreen).to.beFalsy();
    expect(device.has5_5InchScreen).to.beFalsy();
  });
  
  it(@"should return 4 inch screen given correct size", ^{
    id screen = [OCMockObject mockForClass:[UIScreen class]];
    
    CGRect bounds = CGRectMake(0, 0, 320, 568);
    [[[screen stub] andReturnValue:$(bounds)] bounds];

    LTDevice *device = [[LTDevice alloc] initWithUIDevice:[UIDevice currentDevice]
                                                 UIScreen:screen
                                             platformName:nil
                                               mainBundle:[NSBundle mainBundle]];

    expect(device.has3_5InchScreen).to.beFalsy();
    expect(device.has4InchScreen).to.beTruthy();
    expect(device.has4_7InchScreen).to.beFalsy();
    expect(device.has5_5InchScreen).to.beFalsy();
  });
  
  it(@"should return 4.7 inch screen given correct size", ^{
    id screen = [OCMockObject mockForClass:[UIScreen class]];
    
    CGRect bounds = CGRectMake(0, 0, 375, 667);
    [[[screen stub] andReturnValue:$(bounds)] bounds];

    LTDevice *device = [[LTDevice alloc] initWithUIDevice:[UIDevice currentDevice]
                                                 UIScreen:screen
                                             platformName:nil
                                               mainBundle:[NSBundle mainBundle]];
    
    expect(device.has3_5InchScreen).to.beFalsy();
    expect(device.has4InchScreen).to.beFalsy();
    expect(device.has4_7InchScreen).to.beTruthy();
    expect(device.has5_5InchScreen).to.beFalsy();
  });
  
  it(@"should return 5.5 inch screen given correct size", ^{
    id screen = [OCMockObject mockForClass:[UIScreen class]];

    CGRect bounds = CGRectMake(0, 0, 414, 736);
    [[[screen stub] andReturnValue:$(bounds)] bounds];

    LTDevice *device = [[LTDevice alloc] initWithUIDevice:[UIDevice currentDevice]
                                                 UIScreen:screen
                                             platformName:nil
                                               mainBundle:[NSBundle mainBundle]];
    
    expect(device.has3_5InchScreen).to.beFalsy();
    expect(device.has4InchScreen).to.beFalsy();
    expect(device.has4_7InchScreen).to.beFalsy();
    expect(device.has5_5InchScreen).to.beTruthy();
  });
  
  it(@"should return correct screen size even if given in landscape orientation", ^{
    id screen = [OCMockObject mockForClass:[UIScreen class]];
    LTDevice *device = [[LTDevice alloc] initWithUIDevice:[UIDevice currentDevice]
                                                 UIScreen:screen
                                             platformName:nil
                                               mainBundle:[NSBundle mainBundle]];

    [[[screen expect] andReturnValue:$(CGRectMake(0, 0, 480, 320))] bounds];
    [[[screen expect] andReturnValue:$(CGRectMake(0, 0, 568, 320))] bounds];
    [[[screen expect] andReturnValue:$(CGRectMake(0, 0, 667, 375))] bounds];
    [[[screen expect] andReturnValue:$(CGRectMake(0, 0, 736, 414))] bounds];
    expect(device.has3_5InchScreen).to.beTruthy();
    expect(device.has4InchScreen).to.beTruthy();
    expect(device.has4_7InchScreen).to.beTruthy();
    expect(device.has5_5InchScreen).to.beTruthy();
  });
});

context(@"localization", ^{
  it(@"should return current app language", ^{
    id mainBundle = [OCMockObject mockForClass:[NSBundle class]];
    [[[mainBundle stub] andReturn:@[@"en", @"fr-ca"]] preferredLocalizations];

    LTDevice *device = [[LTDevice alloc] initWithUIDevice:[UIDevice currentDevice]
                                                 UIScreen:[UIScreen mainScreen]
                                             platformName:nil
                                               mainBundle:mainBundle];

    expect(device.currentAppLanguage).to.equal(@"en");
  });
});

SpecEnd
