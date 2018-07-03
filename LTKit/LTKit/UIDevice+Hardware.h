// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Kind of device the app currently runs on.
///
/// This should be used with care, as this enum is generated manually, so new device types will take
/// a while to enter production. Therefore, relying on a specific device type for certain operations
/// should be usually frowned upon.
///
/// For example, detecting slow or low-end devices in order to select a lighter-weight but less
/// precise algorithm should not be done by the device kind, but by checking other system properties
/// that act as the bottleneck for the specific algorithm. These properties can be for example the
/// current free or total amount of RAM or the device's GPU model.
typedef NS_ENUM(NSUInteger, UIDeviceKind) {
  // iPhone.
  UIDeviceKindIPhone1 = 0,
  UIDeviceKindIPhone3G,
  UIDeviceKindIPhone3GS,
  UIDeviceKindIPhone4,
  UIDeviceKindIPhone4S,
  UIDeviceKindIPhone5,
  UIDeviceKindIPhone5C,
  UIDeviceKindIPhone5S,
  UIDeviceKindIPhone6,
  UIDeviceKindIPhone6Plus,
  UIDeviceKindIPhone6S,
  UIDeviceKindIPhone6SPlus,
  UIDeviceKindIPhoneSE,
  UIDeviceKindIPhone7,
  UIDeviceKindIPhone7Plus,
  UIDeviceKindIPhone8,
  UIDeviceKindIPhone8Plus,
  UIDeviceKindIPhoneX,

  // iPod.
  UIDeviceKindIPod1G,
  UIDeviceKindIPod2G,
  UIDeviceKindIPod3G,
  UIDeviceKindIPod4G,
  UIDeviceKindIPod5G,
  UIDeviceKindIPod6G,

  // iPad.
  UIDeviceKindIPad1G,
  UIDeviceKindIPad2G,
  UIDeviceKindIPad3G,
  UIDeviceKindIPad4G,
  UIDeviceKindIPad5G,
  UIDeviceKindIPad6G,
  UIDeviceKindIPadAir1G,
  UIDeviceKindIPadAir2G,
  UIDeviceKindIPadPro9_7,
  UIDeviceKindIPadPro10_5,
  UIDeviceKindIPadPro12_9,
  UIDeviceKindIPadPro2G12_9,

  // iPad mini.
  UIDeviceKindIPadMini1G,
  UIDeviceKindIPadMini2G,
  UIDeviceKindIPadMini3G,
  UIDeviceKindIPadMini4G,

  // Apple TV.
  UIDeviceKindAppleTV2,
  UIDeviceKindAppleTV3,
  UIDeviceKindAppleTV4,

  // Simulator.
  UIDeviceKindSimulatorIPhone,
  UIDeviceKindSimulatorIPad,

  // Unknown.
  UIDeviceKindUnknownIPhone,
  UIDeviceKindUnknownIPod,
  UIDeviceKindUnknownIPad,
  UIDeviceKindUnknownAppleTV,
  UIDeviceKindUnknownDevice
};

@interface UIDevice (Hardware)

#pragma mark -
#pragma mark Device idioms
#pragma mark -

/// Runs the block if currently running with a pad idiom. Note that an app might run on an iPad as
/// an iPhone app in 'simulation mode'. In such a case, the block won't execute.
- (void)lt_iPad:(NS_NOESCAPE LTVoidBlock)block;

/// Runs the block if currently running with a phone idiom. Note that an app might run on an iPad as
/// an iPhone app in 'simulation mode'. In such a case, the block will execute.
- (void)lt_iPhone:(NS_NOESCAPE LTVoidBlock)block;

/// Runs \c iPhoneBlock if running with a phone idiom, or \c iPadBlock if running with a pad idiom.
/// If the idiom is unspecified, no block will run.
- (void)lt_iPhone:(NS_NOESCAPE LTVoidBlock)iPhoneBlock iPad:(NS_NOESCAPE LTVoidBlock)iPadBlock;

/// \c YES if currently running with a pad user interface idiom.
@property (readonly, nonatomic) BOOL lt_isPadIdiom;

/// \c YES if currently running with a phone user interface idiom.
@property (readonly, nonatomic) BOOL lt_isPhoneIdiom;

#pragma mark -
#pragma mark Platform info
#pragma mark -

/// Name of the platform, such as 'iPhone1,2'.
@property (readonly, nonatomic) NSString *lt_platformName;

/// Type of the device the software currently runs on.
@property (readonly, nonatomic) UIDeviceKind lt_deviceKind;

/// Device type the software currently runs on as string.
@property (readonly, nonatomic) NSString *lt_deviceKindString;

#pragma mark -
#pragma mark Device PPI
#pragma mark -

/// The number of pixels per inch of the device's screen.
@property (readonly, nonatomic) CGFloat lt_pixelsPerInch;

#pragma mark -
#pragma mark Device memory
#pragma mark -

/// The amount of physical memory on the device in bytes.
@property (readonly, nonatomic) uint64_t lt_physicalMemory;

@end

NS_ASSUME_NONNULL_END
