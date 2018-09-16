// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Reuven Siman Tov.

#import "UIDevice+CameraMake.h"

#import <LTKit/UIDevice+Hardware.h>

NS_ASSUME_NONNULL_BEGIN

@implementation UIDevice (CameraMake)

- (NSString *)cam_cameraMake {
  return @"Apple";
}

- (NSString *)cam_cameraModel {
  // Sources: Mostly experimentation, https://www.flickr.com/cameras/apple, and by downloading real
  // sample photos from review websites.
  switch (self.lt_deviceKind) {
    case UIDeviceKindIPhone1:
      return @"iPhone";
    case UIDeviceKindIPhone3G:
      return @"iPhone 3G";
    case UIDeviceKindIPhone3GS:
      return @"iPhone 3GS";
    case UIDeviceKindIPhone4:
      return @"iPhone 4";
    case UIDeviceKindIPhone4S:
      return @"iPhone 4S";
    case UIDeviceKindIPhone5:
      return @"iPhone 5";
    case UIDeviceKindIPhone5C:
      return @"iPhone 5c";
    case UIDeviceKindIPhone5S:
      return @"iPhone 5s";
    case UIDeviceKindIPhone6:
      return @"iPhone 6";
    case UIDeviceKindIPhone6Plus:
      return @"iPhone 6 Plus";
    case UIDeviceKindIPhone6S:
      return @"iPhone 6s";
    case UIDeviceKindIPhone6SPlus:
      return @"iPhone 6s Plus";
    case UIDeviceKindIPhoneSE:
      return @"iPhone SE";
    case UIDeviceKindIPhone7:
      return @"iPhone 7";
    case UIDeviceKindIPhone7Plus:
      return @"iPhone 7 Plus";
    case UIDeviceKindIPhone8:
      return @"iPhone 8";
    case UIDeviceKindIPhone8Plus:
      return @"iPhone 8 Plus";
    case UIDeviceKindIPhoneX:
      return @"iPhone X";
    case UIDeviceKindIPhoneXS:
      return @"iPhone XS";
    case UIDeviceKindIPhoneXSMax:
      return @"iPhone XS Max";
    case UIDeviceKindIPhoneXR:
      return @"iPhone XR";

    case UIDeviceKindIPod1G:
    case UIDeviceKindIPod2G:
    case UIDeviceKindIPod3G:
    case UIDeviceKindIPod4G:
    case UIDeviceKindIPod5G:
    case UIDeviceKindIPod6G:
      return @"iPod touch";

    case UIDeviceKindIPad1G:
    case UIDeviceKindIPad3G:
    case UIDeviceKindIPad4G:
      return @"iPad";
    case UIDeviceKindIPad2G:
      return @"iPad 2";
    case UIDeviceKindIPadAir1G:
      return @"iPad Air";
    case UIDeviceKindIPadAir2G:
      return @"iPad Air 2";
    case UIDeviceKindIPadPro9_7:
    case UIDeviceKindIPadPro12_9:
      return @"iPad Pro";

    case UIDeviceKindIPadMini1G:
      return @"iPad mini";
    case UIDeviceKindIPadMini2G:
      return @"iPad mini 2";
    case UIDeviceKindIPadMini3G:
      return @"iPad mini 3";

    // Missing data - educated guesses.
    case UIDeviceKindIPadMini4G:
      return @"iPad mini 4";
    case UIDeviceKindIPad5G:
    case UIDeviceKindIPad6G:
      return @"iPad";
    case UIDeviceKindIPadPro10_5:
    case UIDeviceKindIPadPro2G12_9:
      return @"iPad Pro";

    // No camera or N/A
    case UIDeviceKindAppleTV2:
    case UIDeviceKindAppleTV3:
    case UIDeviceKindAppleTV4:
    case UIDeviceKindSimulatorIPhone:
    case UIDeviceKindSimulatorIPad:
    case UIDeviceKindUnknownIPhone:
    case UIDeviceKindUnknownIPod:
    case UIDeviceKindUnknownIPad:
    case UIDeviceKindUnknownAppleTV:
    case UIDeviceKindUnknownDevice:
      return @"";
  }
}

@end

NS_ASSUME_NONNULL_END
