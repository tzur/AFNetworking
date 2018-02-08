// Copyright (c) 2018 Lightricks. All rights reserved.
// Created by Yaron Inger.

NS_ASSUME_NONNULL_BEGIN

/// Returns \c YES if the device is jailbroken, by checking if files can be opened outside the app's
/// sandbox.
BOOL LTIsJailbroken();

/// Returns the team identifier that signed the app binary, or \c nil if no signing exists, no team
/// identifier exists (old signing info) or fetching the signing info failed.
NSString * _Nullable LTSigningTeamIdentifier();

/// Returns the entitlements dictionary contained in the app binary, or \c nil if no entitlements
/// are found or fetching the entitlements failed.
NSDictionary<NSString *, id> * _Nullable LTAppEntitlements();

/// Contains information about an original method and its new implementation.
struct LTHijackedMethodInfo {
  /// Path to the image that contained the original method.
  std::string sourceImage;
  /// Name of the original method.
  std::string sourceMethod;
  /// Path to the image that contains the new method implementation.
  std::string targetImage;
  /// Name of the new method implementation.
  std::string targetMethod;
};

/// Returns information about Obj-C methods that were provided by the app that were swizzled to
/// point to other loaded images that were not provided by the author.
///
/// More specifically, this method iterates over every loaded image, and classifies each image to
/// either one that is provided by the app or by an external source, by the directory each image
/// resides in. Then, each implementation of Obj-C method in the app's images is checked to see
/// where it points to. If the implementation points to an image that was not provided by the app,
/// it will be reported by this function.
///
/// @note This method is not thread safe w.r.t. the list of loaded images, therefore it is
/// recommended to run this right after the executable loads and before there's a chance for other
/// code to dynamically load/unload images on other threads.
std::vector<LTHijackedMethodInfo> LTHijackedMethods();

NS_ASSUME_NONNULL_END
