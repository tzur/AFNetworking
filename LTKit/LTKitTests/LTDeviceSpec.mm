// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTDevice.h"

SpecBegin(LTDevice)

context(@"device idioms", ^{
  context(@"ipad devices", ^{
    __block LTDevice *device;

    beforeEach(^{
      UIDevice *uiDevice = mock([UIDevice class]);

      [given(uiDevice.userInterfaceIdiom) willReturnInteger:UIUserInterfaceIdiomPad];

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
      UIDevice *uiDevice = mock([UIDevice class]);

      [given(uiDevice.userInterfaceIdiom) willReturnInteger:UIUserInterfaceIdiomPhone];

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

  it(@"should return 4 inch screen given correct size", ^{
    UIScreen *screen = mock([UIScreen class]);
    
    CGRect bounds = CGRectMake(0, 0, 320, 568);
    [given(screen.bounds) willReturnStruct:&bounds objCType:@encode(typeof(CGRect))];
    
    LTDevice *device = [[LTDevice alloc] initWithUIDevice:[UIDevice currentDevice]
                                                 UIScreen:screen
                                             platformName:nil
                                               mainBundle:[NSBundle mainBundle]];
    
    expect(device.has4InchScreen).to.beTruthy();
  });
  
  it(@"should return non 4 inch screen given correct size", ^{
    UIScreen *screen = mock([UIScreen class]);
    
    CGRect bounds = CGRectMake(0, 0, 320, 460);
    [given(screen.bounds) willReturnStruct:&bounds objCType:@encode(typeof(CGRect))];
    
    LTDevice *device = [[LTDevice alloc] initWithUIDevice:[UIDevice currentDevice]
                                                 UIScreen:screen
                                             platformName:nil
                                               mainBundle:[NSBundle mainBundle]];
    
    expect(device.has4InchScreen).to.beFalsy();
  });
});

context(@"localization", ^{
  it(@"should return current app language", ^{
    NSBundle *mainBundle = mock([NSBundle class]);

    [given(mainBundle.preferredLocalizations) willReturn:@[@"en", @"fr-ca"]];

    LTDevice *device = [[LTDevice alloc] initWithUIDevice:[UIDevice currentDevice]
                                                 UIScreen:[UIScreen mainScreen]
                                             platformName:nil
                                               mainBundle:mainBundle];

    expect(device.currentAppLanguage).to.equal(@"en");
  });
});

SpecEnd
