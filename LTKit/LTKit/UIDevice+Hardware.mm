// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "UIDevice+Hardware.h"

#import <cmath>
#import <sys/utsname.h>

#import "LTPropertyMacros.h"

NS_ASSUME_NONNULL_BEGIN

// Source: http://theiphonewiki.com/wiki/Models
static NSDictionary * const kPlatformSubstringToUIDeviceKind = @{
  // iPhone.
  @"iPhone1,1": @(UIDeviceKindIPhone1),
  @"iPhone1,2": @(UIDeviceKindIPhone3G),
  @"iPhone2": @(UIDeviceKindIPhone3GS),
  @"iPhone3": @(UIDeviceKindIPhone4),
  @"iPhone4": @(UIDeviceKindIPhone4S),
  @"iPhone5,1": @(UIDeviceKindIPhone5),
  @"iPhone5,2": @(UIDeviceKindIPhone5),
  @"iPhone5,3": @(UIDeviceKindIPhone5C),
  @"iPhone5,4": @(UIDeviceKindIPhone5C),
  @"iPhone6,1": @(UIDeviceKindIPhone5S),
  @"iPhone6,2": @(UIDeviceKindIPhone5S),
  @"iPhone7,2": @(UIDeviceKindIPhone6),
  @"iPhone7,1": @(UIDeviceKindIPhone6Plus),
  @"iPhone8,2": @(UIDeviceKindIPhone6S),
  @"iPhone8,1": @(UIDeviceKindIPhone6SPlus),

  // iPod.
  @"iPod1": @(UIDeviceKindIPod1G),
  @"iPod2": @(UIDeviceKindIPod2G),
  @"iPod3": @(UIDeviceKindIPod3G),
  @"iPod4": @(UIDeviceKindIPod4G),
  @"iPod5": @(UIDeviceKindIPod5G),
  @"iPod7": @(UIDeviceKindIPod6G),

  // iPad.
  @"iPad1": @(UIDeviceKindIPad1G),
  @"iPad2,1": @(UIDeviceKindIPad2G),
  @"iPad2,2": @(UIDeviceKindIPad2G),
  @"iPad2,3": @(UIDeviceKindIPad2G),
  @"iPad2,4": @(UIDeviceKindIPad2G),
  @"iPad3,1": @(UIDeviceKindIPad3G),
  @"iPad3,2": @(UIDeviceKindIPad3G),
  @"iPad3,3": @(UIDeviceKindIPad3G),
  @"iPad3,4": @(UIDeviceKindIPad4G),
  @"iPad3,5": @(UIDeviceKindIPad4G),
  @"iPad3,6": @(UIDeviceKindIPad4G),
  @"iPad4,1": @(UIDeviceKindIPadAir1G), // iPad Air WiFi.
  @"iPad4,2": @(UIDeviceKindIPadAir1G), // iPad Air WiFi + Cellular.
  @"iPad4,3": @(UIDeviceKindIPadAir1G), // iPad Air WiFi + Cellular (China).
  @"iPad5,3": @(UIDeviceKindIPadAir2G), // iPad Air 2 WiFi.
  @"iPad5,4": @(UIDeviceKindIPadAir2G), // iPad Air 2 WiFi + Cellular.
  @"iPad6,8": @(UIDeviceKindIPadPro),

  // iPad mini.
  @"iPad2,5": @(UIDeviceKindIPadMini1G), // iPad mini WiFi.
  @"iPad2,6": @(UIDeviceKindIPadMini1G), // iPad mini WiFi + GSM.
  @"iPad2,7": @(UIDeviceKindIPadMini1G), // iPad mini WiFi + CDMA.
  @"iPad4,4": @(UIDeviceKindIPadMini2G), // iPad mini 2 WiFi.
  @"iPad4,5": @(UIDeviceKindIPadMini2G), // iPad mini 2 WiFi + Cellular.
  @"iPad4,6": @(UIDeviceKindIPadMini2G), // iPad mini 2 WiFi + Cellular (China).
  @"iPad4,7": @(UIDeviceKindIPadMini3G), // iPad mini 3 WiFi.
  @"iPad4,8": @(UIDeviceKindIPadMini3G), // iPad mini 3 WiFi + Cellular.
  @"iPad4,9": @(UIDeviceKindIPadMini3G), // iPad mini 3 WiFi + Cellular (China).
  @"iPad5,1": @(UIDeviceKindIPadMini4G),
  @"iPad5,2": @(UIDeviceKindIPadMini4G),

  // Apple TV.
  @"AppleTV2": @(UIDeviceKindAppleTV2),
  @"AppleTV3": @(UIDeviceKindAppleTV3),

  // Simulator (iPad / iPhone types are not resolved by platform string).
  @"x86_64": @(UIDeviceKindSimulatorIPhone),
  @"i386": @(UIDeviceKindSimulatorIPhone),
};

// Unknowns (these must be checked after all known devices).
static NSDictionary * const kUnknownPlatformSubstringToUIDeviceKind = @{
  @"iPhone": @(UIDeviceKindUnknownIPhone),
  @"iPod": @(UIDeviceKindUnknownIPod),
  @"iPad": @(UIDeviceKindUnknownIPad),
  @"AppleTV": @(UIDeviceKindUnknownAppleTV),
};

static NSDictionary * const kDeviceKindToString = @{
  // iPhone.
  @(UIDeviceKindIPhone1): @"UIDeviceKindIPhone1",
  @(UIDeviceKindIPhone3G): @"UIDeviceKindIPhone3G",
  @(UIDeviceKindIPhone3GS): @"UIDeviceKindIPhone3GS",
  @(UIDeviceKindIPhone4): @"UIDeviceKindIPhone4",
  @(UIDeviceKindIPhone4S): @"UIDeviceKindIPhone4S",
  @(UIDeviceKindIPhone5): @"UIDeviceKindIPhone5",
  @(UIDeviceKindIPhone5C): @"UIDeviceKindIPhone5C",
  @(UIDeviceKindIPhone5S): @"UIDeviceKindIPhone5S",
  @(UIDeviceKindIPhone6): @"UIDeviceKindIPhone6",
  @(UIDeviceKindIPhone6Plus): @"UIDeviceKindIPhone6Plus",
  @(UIDeviceKindIPhone6S): @"UIDeviceKindIPhone6S",
  @(UIDeviceKindIPhone6SPlus): @"UIDeviceKindIPhone6SPlus",

  // iPod.
  @(UIDeviceKindIPod1G): @"UIDeviceKindIPod1G",
  @(UIDeviceKindIPod2G): @"UIDeviceKindIPod2G",
  @(UIDeviceKindIPod3G): @"UIDeviceKindIPod3G",
  @(UIDeviceKindIPod4G): @"UIDeviceKindIPod4G",
  @(UIDeviceKindIPod5G): @"UIDeviceKindIPod5G",
  @(UIDeviceKindIPod6G): @"UIDeviceKindIPod6G",

  // iPad.
  @(UIDeviceKindIPad1G): @"UIDeviceKindIPad1G",
  @(UIDeviceKindIPad2G): @"UIDeviceKindIPad2G",
  @(UIDeviceKindIPad3G): @"UIDeviceKindIPad3G",
  @(UIDeviceKindIPad4G): @"UIDeviceKindIPad4G",
  @(UIDeviceKindIPadAir1G): @"UIDeviceKindIPadAir1G",
  @(UIDeviceKindIPadAir2G): @"UIDeviceKindIPadAir2G",
  @(UIDeviceKindIPadPro): @"UIDeviceKindIPadPro",

  // iPad mini.
  @(UIDeviceKindIPadMini1G): @"UIDeviceKindIPadMini1G",
  @(UIDeviceKindIPadMini2G): @"UIDeviceKindIPadMini2G",
  @(UIDeviceKindIPadMini3G): @"UIDeviceKindIPadMini3G",
  @(UIDeviceKindIPadMini4G): @"UIDeviceKindIPadMini4G",

  // Apple TV.
  @(UIDeviceKindAppleTV2): @"UIDeviceKindAppleTV2",
  @(UIDeviceKindAppleTV3): @"UIDeviceKindAppleTV3",

  // Simulator
  @(UIDeviceKindSimulatorIPhone): @"UIDeviceKindSimulatorIPhone",
  @(UIDeviceKindSimulatorIPad): @"UIDeviceKindSimulatorIPad",

  // Unknowns.
  @(UIDeviceKindUnknownIPhone): @"UIDeviceKindUnknownIPhone",
  @(UIDeviceKindUnknownIPod): @"UIDeviceKindUnknownIPod",
  @(UIDeviceKindUnknownIPad): @"UIDeviceKindUnknownIPad",
  @(UIDeviceKindUnknownAppleTV): @"UIDeviceKindUnknownAppleTV",
  @(UIDeviceKindUnknownDevice): @"UIDeviceKindUnknownDevice"
};

/// Screen type of the device. The type of the screen defines its density.
typedef NS_ENUM(NSUInteger, UIDeviceScreenType) {
  UIDeviceScreenTypeIPhoneNonRetina,
  UIDeviceScreenTypeIPhoneRetina,
  UIDeviceScreenTypeIPhonePlusRetina,
  UIDeviceScreenTypeIPodNonRetina,
  UIDeviceScreenTypeIPodRetina,
  UIDeviceScreenTypeIPadNonRetina,
  UIDeviceScreenTypeIPadMiniRetina,
  UIDeviceScreenTypeIPadRetina,
};

@implementation UIDevice (Hardware)

#pragma mark -
#pragma mark Device idioms
#pragma mark -

- (void)lt_iPad:(LTVoidBlock)block {
  LTParameterAssert(block);

  if (self.lt_isPadIdiom) {
    block();
  }
}

- (void)lt_iPhone:(LTVoidBlock)block {
  LTParameterAssert(block);

  if (self.lt_isPhoneIdiom) {
    block();
  }
}

- (void)lt_iPhone:(LTVoidBlock)iPhoneBlock iPad:(LTVoidBlock)iPadBlock {
  LTParameterAssert(iPhoneBlock);
  LTParameterAssert(iPadBlock);

  if (self.lt_isPhoneIdiom) {
    iPhoneBlock();
  } else if (self.lt_isPadIdiom) {
    iPadBlock();
  }
}

- (BOOL)lt_isPadIdiom {
  return self.userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

- (BOOL)lt_isPhoneIdiom {
  return self.userInterfaceIdiom == UIUserInterfaceIdiomPhone;
}

#pragma mark -
#pragma mark Platform info
#pragma mark -

- (NSString *)lt_platformName {
  if (!objc_getAssociatedObject(self, _cmd)) {
    struct utsname systemInfo;
    uname(&systemInfo);

    NSString *name = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
    objc_setAssociatedObject(self, _cmd, name, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  return objc_getAssociatedObject(self, _cmd);
}

- (UIDeviceKind)lt_deviceKind {
  if (!objc_getAssociatedObject(self, _cmd)) {
    objc_setAssociatedObject(self, _cmd,
                             @([self lt_deviceKindFromPlatformName:self.lt_platformName]),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }

  return (UIDeviceKind)[objc_getAssociatedObject(self, _cmd) unsignedIntegerValue];
}

- (UIDeviceKind)lt_deviceKindFromPlatformName:(NSString *)platformName {
  // Convert to UIDeviceKind. First search for known devices, then for unknown but specific kind,
  // and if not found until then, fall to the great unknown.
  for (NSString *substring in kPlatformSubstringToUIDeviceKind) {
    if ([platformName hasPrefix:substring]) {
      UIDeviceKind deviceType = (UIDeviceKind)[kPlatformSubstringToUIDeviceKind[substring]
                                               unsignedIntegerValue];

      // Special test to set simulator type. Note: it's not always possible to use the
      // UI_USER_INTERFACE_IDIOM() macro, because if the app runs as an iPhone app on an iPad, the
      // result will be UIUserInterfaceIdiomPhone.
      if (deviceType == UIDeviceKindSimulatorIPhone && [self.model hasPrefix:@"iPad"]) {
        return UIDeviceKindSimulatorIPad;
      }

      return deviceType;
    }
  }
  
  for (NSString *substring in kUnknownPlatformSubstringToUIDeviceKind) {
    if ([platformName hasPrefix:substring]) {
      return (UIDeviceKind)[kUnknownPlatformSubstringToUIDeviceKind[substring]
                            unsignedIntegerValue];
    }
  }

  return UIDeviceKindUnknownDevice;
}

- (NSString *)lt_deviceKindString {
  if (!objc_getAssociatedObject(self, _cmd)) {
    objc_setAssociatedObject(self, _cmd, kDeviceKindToString[@(self.lt_deviceKind)],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    LTAssert(self.lt_deviceKindString, @"No valid device type set.");
  }

  return objc_getAssociatedObject(self, _cmd);
}

- (UIDeviceScreenType)lt_screenType {
  switch (self.lt_deviceKind) {
    case UIDeviceKindIPhone1:
    case UIDeviceKindIPhone3G:
    case UIDeviceKindIPhone3GS:
      return UIDeviceScreenTypeIPhoneNonRetina;

    case UIDeviceKindIPhone4:
    case UIDeviceKindIPhone4S:
    case UIDeviceKindIPhone5:
    case UIDeviceKindIPhone5C:
    case UIDeviceKindIPhone5S:
    case UIDeviceKindIPhone6:
    case UIDeviceKindIPhone6S:
    case UIDeviceKindUnknownIPhone:
    case UIDeviceKindSimulatorIPhone:
      return UIDeviceScreenTypeIPhoneRetina;

    case UIDeviceKindIPod1G:
    case UIDeviceKindIPod2G:
    case UIDeviceKindIPod3G:
      return UIDeviceScreenTypeIPodNonRetina;

    case UIDeviceKindIPod4G:
    case UIDeviceKindIPod5G:
    case UIDeviceKindIPod6G:
    case UIDeviceKindUnknownIPod:
      return UIDeviceScreenTypeIPodRetina;

    case UIDeviceKindIPhone6Plus:
    case UIDeviceKindIPhone6SPlus:
      return UIDeviceScreenTypeIPhonePlusRetina;

    case UIDeviceKindIPad1G:
    case UIDeviceKindIPad2G:
    case UIDeviceKindIPadMini1G:
      return UIDeviceScreenTypeIPadNonRetina;

    case UIDeviceKindIPad3G:
    case UIDeviceKindIPad4G:
    case UIDeviceKindIPadAir1G:
    case UIDeviceKindIPadAir2G:
    case UIDeviceKindIPadPro:
    case UIDeviceKindUnknownIPad:
    case UIDeviceKindSimulatorIPad:
      return UIDeviceScreenTypeIPadRetina;

    case UIDeviceKindIPadMini2G:
    case UIDeviceKindIPadMini3G:
    case UIDeviceKindIPadMini4G:
      return UIDeviceScreenTypeIPadMiniRetina;

    default:
      return UIDeviceScreenTypeIPhoneRetina;
  }
}

- (CGFloat)lt_pixelsPerInch {
  /// Pixels per inch can't be extracted via API and need to be specifically copied from the device
  /// spec.
  ///
  /// @see http://www.apple.com/ipad/compare/
  /// @see http://www.apple.com/iphone/compare/
  switch (self.lt_screenType) {
    case UIDeviceScreenTypeIPhoneNonRetina:
    case UIDeviceScreenTypeIPodNonRetina:
      return 163;
    case UIDeviceScreenTypeIPhoneRetina:
    case UIDeviceScreenTypeIPodRetina:
      return 326;
    case UIDeviceScreenTypeIPhonePlusRetina:
      return 401;
    case UIDeviceScreenTypeIPadNonRetina:
      return 132;
    case UIDeviceScreenTypeIPadRetina:
      return 264;
    case UIDeviceScreenTypeIPadMiniRetina:
      return 326;
    default:
      return 326;
  }
}

#pragma mark -
#pragma mark Device memory
#pragma mark -

- (uint64_t)lt_physicalMemory {
  return [NSProcessInfo processInfo].physicalMemory;
}

@end

NS_ASSUME_NONNULL_END
