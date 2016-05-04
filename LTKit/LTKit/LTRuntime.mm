// Copyright (c) 2016 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTRuntime.h"

NS_ASSUME_NONNULL_BEGIN

BOOL LTIsRunningTests() {
  NSDictionary *environment = [[NSProcessInfo processInfo] environment];

  // Works before Xcode 7.0.
  NSString *injectBundle = environment[@"XCInjectBundle"];
  BOOL injectingTestBundle = [injectBundle.pathExtension isEqualToString:@"xctest"];

  // Works on and after Xcode 7.0.
  NSString *configurationFilePath = environment[@"XCTestConfigurationFilePath"];
  BOOL testConfigurationAvailable = [configurationFilePath.pathExtension
                                     isEqualToString:@"xctestconfiguration"];

  return testConfigurationAvailable || injectingTestBundle;
}

NS_ASSUME_NONNULL_END
