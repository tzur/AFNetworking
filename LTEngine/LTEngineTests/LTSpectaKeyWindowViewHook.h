// Copyright (c) 2015 Lightricks. All rights reserved.
// Created by Yaron Inger.

#import <Specta/SPTGlobalBeforeAfterEach.h>

NS_ASSUME_NONNULL_BEGIN

/// Adds the given view to the key window. This will, among other things, set the view's
/// \c traitCollection property, needed for tests involving Auto Layout.
void LTAddViewToWindow(UIView *view);

/// Specta hook which inserts a view to the key window before each spec and removes it after each
/// one.
@interface LTSpectaKeyWindowViewHook : NSObject<SPTGlobalBeforeAfterEach>
@end

NS_ASSUME_NONNULL_END
