// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

typedef NS_ENUM(NSUInteger, LTDeviceType) {
  // iPhone.
  LTDeviceTypeIPhone1 = 0,
  LTDeviceTypeIPhone3G,
  LTDeviceTypeIPhone3GS,
  LTDeviceTypeIPhone4,
  LTDeviceTypeIPhone4S,
  LTDeviceTypeIPhone5,
  LTDeviceTypeIPhone5C,
  LTDeviceTypeIPhone5S,

  // iPod.
  LTDeviceTypeIPod1G,
  LTDeviceTypeIPod2G,
  LTDeviceTypeIPod3G,
  LTDeviceTypeIPod4G,
  LTDeviceTypeIPod5G,

  // iPad.
  LTDeviceTypeIPad1G,
  LTDeviceTypeIPad2G,
  LTDeviceTypeIPad3G,
  LTDeviceTypeIPad4G,
  LTDeviceTypeIPadAir,

  // iPad mini.
  LTDeviceTypeIPadMini1G,
  LTDeviceTypeIPadMini2G,

  // Apple TV.
  LTDeviceTypeAppleTV2,
  LTDeviceTypeAppleTV3,

  // Simulator
  LTDeviceTypeSimulatorIPhone,
  LTDeviceTypeSimulatorIPad,

  // Unknowns.
  LTDeviceTypeUnknownIPhone,
  LTDeviceTypeUnknownIPod,
  LTDeviceTypeUnknownIPad,
  LTDeviceTypeUnknownAppleTV,
  LTDeviceTypeUnknownDevice
};

@interface LTDevice : NSObject

/// Default initializer. Will be called when the singleton creates its instance.
- (id)init;

/// The current device the app is running on.
+ (instancetype)currentDevice;

#pragma mark -
#pragma mark Device idioms
#pragma mark -

/// Runs the block if currently running with a pad idiom. Note that an app might run on an iPad as
/// an iPhone app in 'simulation mode'. In such a case, the block won't execute.
- (void)iPad:(LTVoidBlock)block;

/// Runs the block if currently running with a phone idiom. Note that an app might run on an iPad as
/// an iPhone app in 'simulation mode'. In such a case, the block will execute.
- (void)iPhone:(LTVoidBlock)block;

/// Runs the first block if running with a phone idiom, or the second one if running with a pad
/// idiom.
- (void)iPhone:(LTVoidBlock)iPhoneBlock iPad:(LTVoidBlock)iPadBlock;

/// \c YES if currently running with a pad user interface idiom.
@property (readonly, nonatomic) BOOL isPadIdiom;

/// \c YES if currently running with a phone user interface idiom.
@property (readonly, nonatomic) BOOL isPhoneIdiom;

#pragma mark -
#pragma mark Platform info
#pragma mark -

/// Name of the platform, such as 'iPhone1,2'.
@property (readonly, nonatomic) NSString *platformName;

/// Type of the device the software currently runs on.
@property (readonly, nonatomic) LTDeviceType deviceType;

/// Device type the software currently runs on as string.
@property (readonly, nonatomic) NSString *deviceTypeString;

/// \c YES if the device is an iPhone and has tall 4-inch screen (such as the iPhone 5).
@property (readonly, nonatomic) BOOL has4InchScreen;

// The number of screen points per inch on the device.
@property (readonly, nonatomic) CGFloat pointsPerInch;

/// The typical size (in points) of a finger on the device. This depends on the device's screen
/// points per inch.
@property (readonly, nonatomic) CGFloat fingerSizeInPoints;

#pragma mark -
#pragma mark Localization
#pragma mark -

/// Preferred language for the current device. This is the current iOS interface language, the one
/// appearing on top of the list in Settings-General-International-Language.
///
/// @return the canonicalized IETF BCP 47 representation of the preferred language, or \c nil if the
/// language is not available.
@property (readonly, nonatomic) NSString *preferredLanguage;

/// Language the app is currently using. In case a localization of the preferred language is not
/// available, the best available language will be selected (according to the order of the languages
/// in Settings-General-International-Language).
///
/// @return the canonicalized IETF BCP 47 representation of the preferred language, or \c nil if the
/// language is not available.
///
/// @note the current app language is determined by the main bundle only, meaning it assumes that
/// localizations to the main bundle apply to other bundles as well.
@property (readonly, nonatomic) NSString *currentAppLanguage;

#pragma mark -
#pragma mark GPU
#pragma mark -

/// Maximal texture size that can be used on the device's GPU.
@property (readonly, nonatomic) GLint maxTextureSize;

/// Maximal number of texture units that can be used on the device GPU.
@property (readonly, nonatomic) GLint maxTextureUnits;

/// \c YES if writing to half-float textures is supported.
@property (readonly, nonatomic) BOOL canRenderToHalfFloatTextures;

/// \c YES if writing to float textures is supported.
@property (readonly, nonatomic) BOOL canRenderToFloatTextures;

/// \c YES if creating and rendering \c RED or \c RG textures is supported.
@property (readonly, nonatomic) BOOL supportsRGTextures;

@end

#pragma mark -
#pragma mark For testing
#pragma mark -

@interface LTDevice (ForTesting)

/// Designated initializer: creates object for testing.
///
/// @param device \c UIDevice instance for device querying.
/// @param screen \c UIScreen instance for screen querying.
/// @param platformName name of the platform taken from \c uname.
/// @param mainBundle main bundle of the app.
- (id)initWithUIDevice:(UIDevice *)device UIScreen:(UIScreen *)screen
          platformName:(NSString *)platformName mainBundle:(NSBundle *)mainBundle;

@end
