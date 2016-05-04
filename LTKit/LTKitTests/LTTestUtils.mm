// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestUtils.h"

#import <Specta/SpectaDSL.h>
#import <Specta/SpectaUtility.h>

NS_ASSUME_NONNULL_BEGIN

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

NS_ASSUME_NONNULL_END
