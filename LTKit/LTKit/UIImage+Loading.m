// Copyright (c) 2014 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "UIImage+Loading.h"

#import "LTDevice.h"

@implementation UIImage (Loading)

+ (LTDevice *)ltDevice {
  return [JSObjection defaultInjector][[LTDevice class]];
}

+ (UIScreen *)uiScreen {
  return [JSObjection defaultInjector][[UIScreen class]];
}

+ (UIApplication *)uiApplication {
  return [JSObjection defaultInjector][[UIApplication class]];
}

+ (NSArray *)imageNamesWithName:(NSString *)name heightModifier:(NSString *)heightModifier
            orientationModifier:(NSString *)orientationModifier
                  scaleModifier:(NSString *)scaleModifier
              andDeviceModifier:(NSString *)deviceModifier {
  NSMutableOrderedSet *names = [NSMutableOrderedSet orderedSet];
  [names addObject:[NSString stringWithFormat:@"%@%@%@%@%@", name, heightModifier,
                    orientationModifier, scaleModifier, deviceModifier]];
  [names addObject:[NSString stringWithFormat:@"%@%@%@%@", name, heightModifier, scaleModifier,
                    deviceModifier]];
  [names addObject:[NSString stringWithFormat:@"%@%@%@%@", name, orientationModifier, scaleModifier,
                    deviceModifier]];
  [names addObject:[NSString stringWithFormat:@"%@%@%@", name, scaleModifier, deviceModifier]];
  [names addObject:[NSString stringWithFormat:@"%@%@%@", name, heightModifier, scaleModifier]];
  [names addObject:[NSString stringWithFormat:@"%@%@", name, scaleModifier]];
  [names addObject:[NSString stringWithFormat:@"%@%@%@%@", name, heightModifier,
                    orientationModifier, deviceModifier]];
  [names addObject:[NSString stringWithFormat:@"%@%@%@", name, heightModifier, deviceModifier]];
  [names addObject:[NSString stringWithFormat:@"%@%@%@", name, orientationModifier,
                    deviceModifier]];
  [names addObject:[NSString stringWithFormat:@"%@%@", name, deviceModifier]];
  [names addObject:[NSString stringWithFormat:@"%@%@", name, heightModifier]];
  [names addObject:name];

  return [names array];
}

+ (NSArray *)imageNamesForBasicName:(NSString *)name {
	// Split into extension and name.
	NSString *extension = [name pathExtension];
	name = [name stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", extension]
                                         withString:@""
                                            options:NSBackwardsSearch | NSAnchoredSearch
                                              range:NSMakeRange(0, name.length)];

  // Generate tall screen modifier.
  NSString *heightModifier = @"";
  if (self.ltDevice.has4InchScreen) {
    heightModifier = @"-568h";
  }

  // Generate device modifier.
  NSString *deviceModifier = @"";
  if (self.ltDevice.isPhoneIdiom) {
    deviceModifier = @"~iphone";
  } else {
    deviceModifier = @"~ipad";
  }

  // Get scale and transform to int.
	CGFloat scale = self.uiScreen.scale;
	NSUInteger intScale = (NSUInteger)roundf(scale);

	// Generate scale modifier.
	NSString *scaleModifier = @"";
	if (intScale != 1) {
		scaleModifier = [NSString stringWithFormat:@"@%dx", intScale];
	}

  // Orientation modifier.
  NSString *orientationModifier;
  if (UIDeviceOrientationIsPortrait(self.uiApplication.statusBarOrientation)) {
    orientationModifier = @"-Portrait";
  } else {
    orientationModifier = @"-Landscape";
  }

  NSArray *names = [self imageNamesWithName:name heightModifier:heightModifier
                        orientationModifier:orientationModifier scaleModifier:scaleModifier
                          andDeviceModifier:deviceModifier];

  // If scale is 1, try also @2x images.
  if (intScale == 1) {
    NSArray *retinaArray = [self imageNamesWithName:name heightModifier:heightModifier
                                orientationModifier:orientationModifier scaleModifier:@"@2x"
                                  andDeviceModifier:deviceModifier];
    return [names arrayByAddingObjectsFromArray:retinaArray];
  }

  return names;
}

+ (NSString *)imagePathForNameInMainBundle:(NSString *)name {
  return [UIImage imagePathForName:name fromBundle:[NSBundle mainBundle]];
}

+ (NSString *)imagePathForName:(NSString *)name fromBundle:(NSBundle *)bundle {
  if (!name) {
    return nil;
  }

  if (!bundle) {
		bundle = [NSBundle mainBundle];
	}

  // If the image has no extension, append the 'png' file extension, as in -[UIImage imageNamed:].
  NSString *extension = [name pathExtension];
  if ([extension isEqualToString:@""]) {
    extension = @"png";
  }

  NSArray *names = [UIImage imageNamesForBasicName:name];
  for (NSString *resource in names) {
    NSString *path = [bundle pathForResource:resource ofType:extension];
    if (path) {
      return path;
    }
  }

  return nil;
}

+ (UIImage *)imageNamedInMainBundle:(NSString *)name {
  return [UIImage imageNamed:name fromBundle:[NSBundle mainBundle]];
}

+ (UIImage *)imageNamed:(NSString *)name fromBundle:(NSBundle *)bundle {
  NSString *path = [UIImage imagePathForName:name fromBundle:bundle];
  if (!path) {
    return nil;
  }

  return [UIImage imageWithContentsOfFile:path];
}

@end
