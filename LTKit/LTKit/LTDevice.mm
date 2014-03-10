// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Amit Goldstein.

#import "LTDevice.h"

#import <sys/utsname.h>

/// Points per inch for the various devices. This is according to the specs, and can't be be found
/// in code.
///
/// @see http://www.apple.com/ipad/compare/
/// @see http://www.apple.com/iPhone/compare/
static const CGFloat kPointsPerInchDefault = 163.0;
static const CGFloat kPointsPerInchIPhone = 163.0;
static const CGFloat kPointsPerInchIPod = 163.0;
static const CGFloat kPointsPerInchIPad = 132.0;
static const CGFloat kPointsPerInchIPadMini = 163.0;

/// Size of the common finger in inches.
static const CGFloat kCommonFingerSizeInInches = 0.63;

/// Size in points of tall 4-inch screen (such as iPhone 5's screen).
static const CGFloat k4InchScreenHeight = 568;

// Source: http://theiphonewiki.com/wiki/Models
static NSDictionary * const kPlatformSubstringToLTDeviceType = @{
  // iPhone.
  @"iPhone1,1": @(LTDeviceTypeIPhone1),
  @"iPhone1,2": @(LTDeviceTypeIPhone3G),
  @"iPhone2":   @(LTDeviceTypeIPhone3GS),
  @"iPhone3":   @(LTDeviceTypeIPhone4),
  @"iPhone4":   @(LTDeviceTypeIPhone4S),
  @"iPhone5,1": @(LTDeviceTypeIPhone5),
  @"iPhone5,2": @(LTDeviceTypeIPhone5),
  @"iPhone5,3": @(LTDeviceTypeIPhone5C),
  @"iPhone5,4": @(LTDeviceTypeIPhone5C),
  @"iPhone6,1": @(LTDeviceTypeIPhone5S),
  @"iPhone6,2": @(LTDeviceTypeIPhone5S),

  // iPod.
  @"iPod1":     @(LTDeviceTypeIPod1G),
  @"iPod2":     @(LTDeviceTypeIPod2G),
  @"iPod3":     @(LTDeviceTypeIPod3G),
  @"iPod4":     @(LTDeviceTypeIPod4G),
  @"iPod5":     @(LTDeviceTypeIPod5G),

  // iPad.
  @"iPad1":     @(LTDeviceTypeIPad1G),
  @"iPad2,1":   @(LTDeviceTypeIPad2G),
  @"iPad2,2":   @(LTDeviceTypeIPad2G),
  @"iPad2,3":   @(LTDeviceTypeIPad2G),
  @"iPad2,4":   @(LTDeviceTypeIPad2G),
  @"iPad3,1":   @(LTDeviceTypeIPad3G),
  @"iPad3,2":   @(LTDeviceTypeIPad3G),
  @"iPad3,3":   @(LTDeviceTypeIPad3G),
  @"iPad3,4":   @(LTDeviceTypeIPad4G),
  @"iPad3,5":   @(LTDeviceTypeIPad4G),
  @"iPad3,6":   @(LTDeviceTypeIPad4G),
  @"iPad4,1":   @(LTDeviceTypeIPadAir),
  @"iPad4,2":   @(LTDeviceTypeIPadAir),
  @"iPad4,3":   @(LTDeviceTypeIPadAir), // Speculation: CDMA model.

  // iPad mini.
  @"iPad2,5":   @(LTDeviceTypeIPadMini1G), // iPad mini WIFI
  @"iPad2,6":   @(LTDeviceTypeIPadMini1G), // iPad mini WIFI + GSM
  @"iPad2,7":   @(LTDeviceTypeIPadMini1G), // iPad mini WIFI + CDMA
  @"iPad4,4":   @(LTDeviceTypeIPadMini2G),
  @"iPad4,5":   @(LTDeviceTypeIPadMini2G),
  @"iPad4,6":   @(LTDeviceTypeIPadMini2G), // Speculation: CDMA model.

  // Apple TV.
  @"AppleTV2":  @(LTDeviceTypeAppleTV2),
  @"AppleTV3":  @(LTDeviceTypeAppleTV3),

  // Simulator (iPad / iPhone types are not resolved by platform string).
  @"x86_64":    @(LTDeviceTypeSimulatorIPhone),
  @"i386":      @(LTDeviceTypeSimulatorIPhone),
};

// Unknowns (these must be checked after all known devices).
static NSDictionary * const kUnknownPlatformSubstringToLTDeviceType = @{
  @"iPhone":    @(LTDeviceTypeUnknownIPhone),
  @"iPod":      @(LTDeviceTypeUnknownIPod),
  @"iPad":      @(LTDeviceTypeUnknownIPad),
  @"AppleTV":   @(LTDeviceTypeUnknownAppleTV),
};

static NSDictionary * const kDeviceTypeToString = @{
  // iPhone.
  @(LTDeviceTypeIPhone1):   @"LTDeviceTypeIPhone1",
  @(LTDeviceTypeIPhone3G):  @"LTDeviceTypeIPhone3G",
  @(LTDeviceTypeIPhone3GS): @"LTDeviceTypeIPhone3GS",
  @(LTDeviceTypeIPhone4):   @"LTDeviceTypeIPhone4",
  @(LTDeviceTypeIPhone4S):  @"LTDeviceTypeIPhone4S",
  @(LTDeviceTypeIPhone5):   @"LTDeviceTypeIPhone5",
  @(LTDeviceTypeIPhone5C):  @"LTDeviceTypeIPhone5C",
  @(LTDeviceTypeIPhone5S):  @"LTDeviceTypeIPhone5S",
  
  // iPod.
  @(LTDeviceTypeIPod1G): @"LTDeviceTypeIPod1G",
  @(LTDeviceTypeIPod2G): @"LTDeviceTypeIPod2G",
  @(LTDeviceTypeIPod3G): @"LTDeviceTypeIPod3G",
  @(LTDeviceTypeIPod4G): @"LTDeviceTypeIPod4G",
  @(LTDeviceTypeIPod5G): @"LTDeviceTypeIPod5G",
  
  // iPad.
  @(LTDeviceTypeIPad1G):  @"LTDeviceTypeIPad1G",
  @(LTDeviceTypeIPad2G):  @"LTDeviceTypeIPad2G",
  @(LTDeviceTypeIPad3G):  @"LTDeviceTypeIPad3G",
  @(LTDeviceTypeIPad4G):  @"LTDeviceTypeIPad4G",
  @(LTDeviceTypeIPadAir): @"LTDeviceTypeIPadAir",
  
  // iPad mini.
  @(LTDeviceTypeIPadMini1G): @"LTDeviceTypeIPadMini1G",
  @(LTDeviceTypeIPadMini2G): @"LTDeviceTypeIPadMini2G",

  // Apple TV.
  @(LTDeviceTypeAppleTV2): @"LTDeviceTypeAppleTV2",
  @(LTDeviceTypeAppleTV3): @"LTDeviceTypeAppleTV3",
  
  // Simulator
  @(LTDeviceTypeSimulatorIPhone): @"LTDeviceTypeSimulatorIPhone",
  @(LTDeviceTypeSimulatorIPad):   @"LTDeviceTypeSimulatorIPad",
  
  // Unknowns.
  @(LTDeviceTypeUnknownIPhone):   @"LTDeviceTypeUnknownIPhone",
  @(LTDeviceTypeUnknownIPod):     @"LTDeviceTypeUnknownIPod",
  @(LTDeviceTypeUnknownIPad):     @"LTDeviceTypeUnknownIPad",
  @(LTDeviceTypeUnknownAppleTV):  @"LTDeviceTypeUnknownAppleTV",
  @(LTDeviceTypeUnknownDevice):   @"LTDeviceTypeUnknownDevice"
};

@interface LTDevice ()

@property (readwrite, nonatomic) NSString *platformName;
@property (readwrite, nonatomic) LTDeviceType deviceType;
@property (readwrite, nonatomic) NSString *deviceTypeString;

@property (strong, nonatomic) EAGLContext *context;

@property (strong, nonatomic) NSSet *supportedExtensions;
@property (readwrite, nonatomic) GLint maxTextureSize;
@property (readwrite, nonatomic) GLint maxTextureUnits;

@property (strong, nonatomic) UIScreen *screen;
@property (strong, nonatomic) UIDevice *device;
@property (strong, nonatomic) NSBundle *mainBundle;

@property (readwrite, nonatomic) BOOL isPadIdiom;
@property (readwrite, nonatomic) BOOL isPhoneIdiom;

@end

@implementation LTDevice

+ (instancetype)currentDevice {
  static LTDevice *instance;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[LTDevice alloc] init];
  });

  return instance;
}

#pragma mark -
#pragma mark Initialization
#pragma mark -

- (id)init {
  return [self initWithUIDevice:[UIDevice currentDevice] UIScreen:[UIScreen mainScreen]
                   platformName:nil mainBundle:[NSBundle mainBundle]];
}

- (id)initWithUIDevice:(UIDevice *)device UIScreen:(UIScreen *)screen
          platformName:(NSString *)platformName mainBundle:(NSBundle *)mainBundle {
  if (self = [super init]) {
    self.device = device;
    self.screen = screen;
    self.platformName = platformName;
    self.mainBundle = mainBundle;

    self.deviceType = [self deviceTypeFromPlatformName:self.platformName];

    self.isPadIdiom = self.device.userInterfaceIdiom == UIUserInterfaceIdiomPad;
    self.isPhoneIdiom = !self.isPadIdiom;
  }
  return self;
}

#pragma mark -
#pragma mark Device idioms
#pragma mark -

- (void)iPad:(LTVoidBlock)block {
  if (self.isPadIdiom && block) {
    block();
  }
}

- (void)iPhone:(LTVoidBlock)block {
  if (self.isPhoneIdiom && block) {
    block();
  }
}

- (void)iPhone:(LTVoidBlock)iPhoneBlock iPad:(LTVoidBlock)iPadBlock {
  if (self.isPhoneIdiom) {
    if (iPhoneBlock) iPhoneBlock();
  } else {
    if (iPadBlock) iPadBlock();
  }
}

#pragma mark -
#pragma mark Platform info
#pragma mark -

- (NSString *)platformName {
  if (!_platformName) {
    struct utsname systemInfo;
    uname(&systemInfo);
    _platformName = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
  }

  return _platformName;
}

- (LTDeviceType)deviceTypeFromPlatformName:(NSString *)platformName {
  // Convert to LTDeviceType. First search for known devices, then for unknown but specific kind,
  // and if not found until then, fall to the great unknown.
  for (NSString *substring in kPlatformSubstringToLTDeviceType) {
    if ([platformName hasPrefix:substring]) {
      LTDeviceType deviceType = (LTDeviceType)[kPlatformSubstringToLTDeviceType[substring]
                                               unsignedIntegerValue];

      // Special test to set simulator type. Note: it's not always possible to use the
      // UI_USER_INTERFACE_IDIOM() macro, because if the app runs as an iPhone app on an iPad, the
      // result will be UIUserInterfaceIdiomPhone.
      if (deviceType == LTDeviceTypeSimulatorIPhone &&
          [[self.device model] hasPrefix:@"iPad"]) {
        return LTDeviceTypeSimulatorIPad;
      }

      return deviceType;
    }
  }
  for (NSString *substring in kUnknownPlatformSubstringToLTDeviceType) {
    if ([platformName hasPrefix:substring]) {
      return (LTDeviceType)[kUnknownPlatformSubstringToLTDeviceType[substring]
                            unsignedIntegerValue];
    }
  }

  return LTDeviceTypeUnknownDevice;
}

- (NSString *)deviceTypeString {
  if (!_deviceTypeString) {
    _deviceTypeString = kDeviceTypeToString[@(self.deviceType)];
    LTAssert(self.deviceTypeString, @"No valid device type set.");
  }

  return _deviceTypeString;
}

- (BOOL)has4InchScreen {
  return self.screen.bounds.size.height == k4InchScreenHeight;
}

- (CGFloat)pointsPerInch {
  switch (self.deviceType) {
    case LTDeviceTypeIPhone1:
    case LTDeviceTypeIPhone3G:
    case LTDeviceTypeIPhone3GS:
    case LTDeviceTypeIPhone4:
    case LTDeviceTypeIPhone4S:
    case LTDeviceTypeIPhone5:
    case LTDeviceTypeIPhone5C:
    case LTDeviceTypeIPhone5S:
    case LTDeviceTypeUnknownIPhone:
    case LTDeviceTypeSimulatorIPhone:
      return kPointsPerInchIPhone;

    case LTDeviceTypeIPod1G:
    case LTDeviceTypeIPod2G:
    case LTDeviceTypeIPod3G:
    case LTDeviceTypeIPod4G:
    case LTDeviceTypeIPod5G:
    case LTDeviceTypeUnknownIPod:
      return kPointsPerInchIPod;

    case LTDeviceTypeIPad1G:
    case LTDeviceTypeIPad2G:
    case LTDeviceTypeIPad3G:
    case LTDeviceTypeIPad4G:
    case LTDeviceTypeIPadAir:
    case LTDeviceTypeUnknownIPad:
    case LTDeviceTypeSimulatorIPad:
      return kPointsPerInchIPad;

    case LTDeviceTypeIPadMini1G:
    case LTDeviceTypeIPadMini2G:
      return kPointsPerInchIPadMini;

    default:
      return kPointsPerInchDefault;
  }
}

- (CGFloat)fingerSizeOnDevice {
  return std::round(self.pointsPerInch * kCommonFingerSizeInInches);
}

#pragma mark -
#pragma mark Localization
#pragma mark -

- (NSString *)preferredLanguage {
  NSArray *languages = [NSLocale preferredLanguages];
  return [languages firstObject];
}

- (NSString *)currentAppLanguage {
  NSArray *localizations = [self.mainBundle preferredLocalizations];
  return [localizations firstObject];
}

#pragma mark -
#pragma mark GPU
#pragma mark -

- (EAGLContext *)setGLContext {
  // Set new context only if there's no context currently set.
  EAGLContext *currentContext = [EAGLContext currentContext];
  if (!currentContext) {
    [EAGLContext setCurrentContext:self.context];
  }
  return currentContext;
}

- (void)restoreGLContext:(EAGLContext *)context {
  if (!context) {
    [EAGLContext setCurrentContext:nil];
  }
}

- (void)executeOpenGL:(LTVoidBlock)block {
  EAGLContext *context = [self setGLContext];
  if (block) block();
  [self restoreGLContext:context];
}

- (EAGLContext *)context {
  if (!_context) {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
      LogError(@"Failed to create OpenGL ES context");
    }
  }
  return _context;
}

/// Returns \c YES if the given OpenGL extension is supported on this device.
- (NSSet *)supportedExtensions {
  if (!_supportedExtensions) {
    [self executeOpenGL:^{
      NSString *extensions = [NSString stringWithCString:(const char *)glGetString(GL_EXTENSIONS)
                                                encoding:NSASCIIStringEncoding];
      NSString *trimmed = [extensions
                           stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
      _supportedExtensions = [NSSet setWithArray:[trimmed componentsSeparatedByString:@" "]];
    }];
  }

  return _supportedExtensions;
}

- (GLint)maxTextureSize {
  if (!_maxTextureSize) {
    [self executeOpenGL:^{
      glGetIntegerv(GL_MAX_TEXTURE_SIZE, &_maxTextureSize);
    }];
  }

  return _maxTextureSize;
}

- (GLint)maxTextureUnits {
  if (!_maxTextureUnits) {
    [self executeOpenGL:^{
      glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &_maxTextureUnits);
    }];
  }

  return _maxTextureUnits;
}

- (BOOL)canRenderToHalfFloatTextures {
  return [self.supportedExtensions containsObject:@"GL_EXT_color_buffer_half_float"];
}

- (BOOL)canRenderToFloatTextures {
  return [self.supportedExtensions containsObject:@"GL_EXT_color_buffer_float"];
}

- (BOOL)supportsRGTextures {
  return [self.supportedExtensions containsObject:@"GL_EXT_texture_rg"];
}

@end
