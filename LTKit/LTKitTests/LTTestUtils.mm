// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestUtils.h"

#import <Specta/SpectaDSL.h>
#import <Specta/SpectaUtility.h>

#import "LTCGExtensions.h"
#import "LTDevice.h"
#import "LTEnumRegistry.h"

static NSString * const kMatOutputBasedir = @"/tmp/";

#pragma mark -
#pragma mark Public methods
#pragma mark -

void sit(NSString __unused *name, id __unused block) {
#if TARGET_IPHONE_SIMULATOR
  it(name, block);
#endif
}

void dit(NSString __unused *name, id __unused block) {
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
  it(name, block);
#endif
}

BOOL LTRunningApplicationTests() {
  NSDictionary *environment = [[NSProcessInfo processInfo] environment];
  return environment[@"XCInjectBundle"] != nil;
}
