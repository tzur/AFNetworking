// Copyright (c) 2013 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import "LTTestUtils.h"

#import <Specta/SpectaDSL.h>
#import <Specta/SpectaUtility.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
#pragma mark Public methods
#pragma mark -

void scontext(NSString * __unused name, id __unused block) {
#if TARGET_OS_SIMULATOR
  context(name, block);
#endif
}

void dcontext(NSString * __unused name, id __unused block) {
#if !TARGET_OS_SIMULATOR && TARGET_OS_IPHONE
  context(name, block);
#endif
}

void sit(NSString * __unused name, id __unused block) {
#if TARGET_OS_SIMULATOR
  it(name, block);
#endif
}

void dit(NSString * __unused name, id __unused block) {
#if !TARGET_OS_SIMULATOR && TARGET_OS_IPHONE
  it(name, block);
#endif
}

NS_ASSUME_NONNULL_END
